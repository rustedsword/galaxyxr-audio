dnl Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
dnl SPDX-License-Identifier: BSD-3-Clause
include(`audioreach/audioreach.m4') dnl
include(`util/pcm.m4') dnl
include(`audioreach/subgraph.m4') dnl
include(`audioreach/container.m4') dnl
include(`audioreach/module_log.m4') dnl
include(`galaxyxr/module_tdm.m4') dnl
include(`galaxyxr/module_mfc_quad.m4') dnl
include(`galaxyxr/module_samsung_spk.m4') dnl
include(`util/mixer.m4') dnl
dnl
dnl The speakers' backend: Samsung's speaker processing in front of the TDM sink
dnl
dnl  _________________________________      ________________________
dnl | Subgraph 2, low power           |    | Subgraph 1             |
dnl | specialized container           | -> | [LOG] -> [TDM SINK EP] |
dnl | [MFC, 24 bit quad] -> [SPK PROC]|    |________________________|
dnl |_________________________________|
dnl
dnl Samsung's module works only in this setting. The interface configuration
dnl comes from DEVICE_AUDIO_IF_SG_ADD in the board topology.

undefine(`LOG_MODULE_IID') dnl
undefine(`AUDIO_IF_MODULE_IID') dnl
undefine(`SG_INDEX') dnl
undefine(`CONTAINER_INDEX') dnl
undefine(`MOD_INDEX') dnl

undefine(`DEVICE_PERF_MODE') dnl
undefine(`DEVICE_DIRECTION') dnl
undefine(`CONT_SENARIO_ID') dnl
undefine(`CONT_CAP') dnl
undefine(`CONT_POSITION') dnl
undefine(`DEVICE_DOMAIN_ID') dnl
undefine(`CONT_STACK_SIZE') dnl

dnl Subgraph configuration - same as I2S playback:
dnl  DIRECTION_TX = data flows from ADSP to HW (playback)
dnl  SID_AUDIO_PLAYBACK = audio playback scenario
define(`DEVICE_PERF_MODE', APM_SG_PERF_MODE_LOW_LATENCY) dnl'
define(`DEVICE_DIRECTION', APM_SUB_GRAPH_DIRECTION_TX) dnl'
define(`CONT_SENARIO_ID', APM_SUB_GRAPH_SID_AUDIO_PLAYBACK) dnl'
define(`CONT_CAP', `ifelse(LPASS_VER_COMPAT, 110000, APM_CONTAINER_TYPE_ID_GC, APM_CONTAINER_CAP_ID_EP)') dnl'
define(`CONT_POSITION', APM_CONT_GRAPH_POS_STREAM)dnl'
define(`DEVICE_DOMAIN_ID', `ifdef(`AR_SELECTED_PROC_DOMAIN_ID', AR_SELECTED_PROC_DOMAIN_ID, APM_PROC_DOMAIN_ID_ADSP)') dnl'
define(`CONT_STACK_SIZE', 8192) dnl'
dnl
dnl Module IID assignments:
dnl  LOG_MODULE_IID  = MOD_IID_START + 0  (data logging module)
dnl  AUDIO_IF_MODULE_IID = MOD_IID_START + 1  (TDM sink, the HW endpoint)
dnl  MFCQ_MODULE_IID = MOD_IID_START + 2  (MFC in front of Samsung's module)
dnl  SPK_MODULE_IID  = MOD_IID_START + 3  (Samsung's speaker processing)
define(`LOG_MODULE_IID', MOD_IID_START) dnl
define(`AUDIO_IF_MODULE_IID', eval(MOD_IID_START + 1)) dnl
define(`MFCQ_MODULE_IID', eval(MOD_IID_START + 2)) dnl
define(`SPK_MODULE_IID', eval(MOD_IID_START + 3)) dnl
define(`SG_INDEX', 1) dnl
define(`CONTAINER_INDEX', 1) dnl
define(`MOD_INDEX', 1) dnl
dnl
dnl DEVICE_PLAYBACK_ROUTE(stream-index, dai-name, mixer-prefix)
dnl Defines the ALSA graph connections of the speakers:
dnl   tdm_rx widget <- logger <- spk_proc <- mfcq <- Audio Mixer <- stream
dnl The stream_name "$2 Playback" must match the backend DAI stream_name.
define(`DEVICE_PLAYBACK_ROUTE',
`'
`SectionGraph."NAME_PREFIX.$1 $3 Graph" {'
`        index STR($1)'
`        lines ['
`                "NAME_PREFIX.mfcq$1, , $3 Audio Mixer"'
`                "NAME_PREFIX.spk_proc$1, , NAME_PREFIX.mfcq$1"'
`                "NAME_PREFIX.logger$1, , NAME_PREFIX.spk_proc$1"'
`                "NAME_PREFIX.tdm_rx$1, , NAME_PREFIX.logger$1"'
`                "$2 Playback, , NAME_PREFIX.tdm_rx$1"'
`        ]'
`}')


AR_SUBGRAPH(SG_INDEX, DEVICE_DAI_ID, SG_IID_START, DEVICE_PERF_MODE, DEVICE_DIRECTION, CONT_SENARIO_ID)
AR_CONTAINER(CONTAINER_INDEX, CONT_IID_START, CONT_CAP, CONT_STACK_SIZE, CONT_POSITION, DEVICE_DOMAIN_ID)
AR_SUBGRAPH(2, DEVICE_DAI_ID, 0x00004015, APM_SG_PERF_MODE_LOW_POWER, DEVICE_DIRECTION, CONT_SENARIO_ID)
AR_CONTAINER(2, 0x00004015, APM_CONTAINER_TYPE_ID_SC, 4096, APM_CONT_GRAPH_POS_PER_STR_PER_DEV, DEVICE_DOMAIN_ID)

dnl LOG module in front of the TDM sink
dnl AR_MODULE_LOG(idx, sg, cont, iid, maxip, maxop, src-port, dst-port, log-code, log-tap, log-mode, dst-iid)
AR_MODULE_LOG(MOD_INDEX, SG_INDEX, CONTAINER_INDEX,
	LOG_MODULE_IID, 1, 1, 1, 2, 0x00001586, 1, 0, AUDIO_IF_MODULE_IID)
AR_MODULE_MFC_QUAD(MOD_INDEX, 2, 2, MFCQ_MODULE_IID, 1, 1, 1, 2, SPK_MODULE_IID)
AR_MODULE_SAMSUNG_SPK(MOD_INDEX, 2, 2, SPK_MODULE_IID, 1, 1, 1, 2, LOG_MODULE_IID)

dnl TDM sink: the HW endpoint. Of the Audio IF arguments it uses the TDM ones:
dnl sync source, data-out control, slot mask, slots per frame, slot width,
dnl sync mode, sync pulse inversion and data delay.
AR_MODULE_TDM_SINK(MOD_INDEX, SG_INDEX, CONTAINER_INDEX,
	AUDIO_IF_MODULE_IID, 1, 0, 1, 0,
	DEVICE_INTF_TYPE, DEVICE_INTF_INDEX, DEVICE_DATA_FORMAT,
	DEVICE_AUDIO_IF_SYNC_SRC, DEVICE_AUDIO_IF_CTRL_DATA_OUT_ENABLE,
	DEVICE_AUDIO_IF_SLOT_MASK, DEVICE_AUDIO_IF_NSLOTS_PER_FRAME,
	DEVICE_AUDIO_IF_SLOT_WIDTH, DEVICE_AUDIO_IF_INTF_MODE,
	DEVICE_AUDIO_IF_FRAME_SYNC_MODE,
	DEVICE_AUDIO_IF_CTRL_INVERT_SYNC_PULSE,
	DEVICE_AUDIO_IF_CTRL_SYNC_DATA_DELAY,
	DEVICE_AUDIO_IF_QAIF_TYPE,
	DEVICE_AUDIO_IF_ACTIVE_LANE_MASK, DEVICE_AUDIO_IF_FRAME_SYNC_RATE,
	DEVICE_AUDIO_IF_BIT_CLK_TYPE, DEVICE_AUDIO_IF_INV_INT_BIT_CLK,
	DEVICE_AUDIO_IF_INV_EXT_BIT_CLK,
	`DEVICE_NAME', NONE_IID)

DEVICE_PLAYBACK_ROUTE(MOD_INDEX, `DEVICE_NAME', `MIXER_PREFIX')
