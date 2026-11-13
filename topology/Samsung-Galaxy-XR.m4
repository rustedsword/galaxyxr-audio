# SPDX-License-Identifier: BSD-3-Clause
include(`audioreach/audioreach.m4')
include(`audioreach/stream-subgraph.m4')
include(`audioreach/device-subgraph.m4')
include(`util/route.m4')
include(`util/mixer.m4')
include(`audioreach/tokens.m4')
dnl
dnl MultiMedia1 playback: speakers
STREAM_SG_PCM_ADD(audioreach/subgraph-stream-vol-playback.m4, FRONTEND_DAI_MULTIMEDIA1,
	`S16_LE', 48000, 48000, 2, 2,
	0x00004001, 0x00004001, 0x00006001, `110000')
dnl MultiMedia2 playback: DisplayPort
STREAM_SG_PCM_ADD(audioreach/subgraph-stream-vol-playback.m4, FRONTEND_DAI_MULTIMEDIA2,
	`S16_LE', 48000, 48000, 2, 2,
	0x00004002, 0x00004002, 0x00006010, `110000')
dnl MultiMedia3 capture: microphones
STREAM_SG_PCM_ADD(audioreach/subgraph-stream-capture.m4, FRONTEND_DAI_MULTIMEDIA3,
	`S16_LE', 48000, 48000, 1, 2,
	0x00004003, 0x00004003, 0x00006020, `110000')
dnl
DEVICE_SG_ADD(audioreach/subgraph-device-i2s-playback.m4, `Quaternary', QUATERNARY_MI2S_RX,
	`S16_LE', 48000, 48000, 2, 2,
	LPAIF_INTF_TYPE_RXTX, I2S_INTF_TYPE_PRIMARY, SD_LINE_IDX_I2S_SD1, DATA_FORMAT_FIXED_POINT,
	0x00004005, 0x00004005, 0x00006050, `QUATERNARY_MI2S_RX')
DEVICE_SG_ADD(audioreach/subgraph-device-display-port-playback.m4, `DISPLAY_PORT_RX_0', DISPLAY_PORT_RX_0,
	`S16_LE', 48000, 48000, 2, 2,
	LPAIF_INTF_TYPE_LPAIF, 0, 0, DATA_FORMAT_FIXED_POINT,
	0x00004006, 0x00004006, 0x00006060, `DISPLAY_PORT_RX_0')
DEVICE_SG_ADD(audioreach/subgraph-device-codec-dma-capture.m4, `VA_CODEC_DMA_TX_0', VA_CODEC_DMA_TX_0,
	`S16_LE', 48000, 48000, 1, 2,
	LPAIF_INTF_TYPE_VA, CODEC_INTF_IDX_TX0, 0, DATA_FORMAT_FIXED_POINT,
	0x00004008, 0x00004008, 0x00006080)
dnl
STREAM_DEVICE_PLAYBACK_MIXER(QUATERNARY_MI2S_RX, ``QUATERNARY_MI2S_RX'', ``MultiMedia1'')
STREAM_DEVICE_PLAYBACK_ROUTE(QUATERNARY_MI2S_RX, ``QUATERNARY_MI2S_RX Audio Mixer'', ``MultiMedia1, stream0.logger1'')
STREAM_DEVICE_PLAYBACK_MIXER(DISPLAY_PORT_RX_0, ``DISPLAY_PORT_RX_0'', ``MultiMedia2'')
STREAM_DEVICE_PLAYBACK_ROUTE(DISPLAY_PORT_RX_0, ``DISPLAY_PORT_RX_0 Audio Mixer'', ``MultiMedia2, stream1.logger1'')
dnl
STREAM_DEVICE_CAPTURE_MIXER(FRONTEND_DAI_MULTIMEDIA3, ``VA_CODEC_DMA_TX_0'')
STREAM_DEVICE_CAPTURE_ROUTE(FRONTEND_DAI_MULTIMEDIA3, ``MultiMedia3 Mixer'', ``VA_CODEC_DMA_TX_0, device110.logger1'')
