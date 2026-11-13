# Copyright, Linaro Ltd, 2023
# SPDX-License-Identifier: BSD-3-Clause
include(`util/util.m4') dnl
dnl An MFC with a fixed output format: 24 bit, four channels (the kernel maps them FL FR LB RB).
dnl AR_MODULE_MFC_QUAD(index, sgidx, container-idx, iid, maxip-ports, max-op-ports, src-port, dst-port, dst-iid)
define(`AR_MODULE_MFC_QUAD',
`'
`SectionVendorTuples."NAME_PREFIX.mfcq$1_tuples" {'
`        tokens "audioreach_tokens"'
`'
`        tuples."word.u32_data" {'
`                AR_TKN_U32_MODULE_INSTANCE_ID STR($4)'
`                AR_TKN_U32_MODULE_ID STR(MODULE_ID_MFC)'
`                AR_TKN_U32_MODULE_MAX_IP_PORTS STR($5)'
`                AR_TKN_U32_MODULE_MAX_OP_PORTS STR($6)'
`                AR_TKN_U32_MODULE_SRC_OP_PORT_ID STR($7)'
`                AR_TKN_U32_MODULE_DST_IN_PORT_ID STR($8)'
`                AR_TKN_U32_MODULE_SRC_INSTANCE_ID STR($4)'
`                AR_TKN_U32_MODULE_DST_INSTANCE_ID STR($9)'
`                AR_TKN_U32_MODULE_FMT_BIT_DEPTH "24"'
`                AR_TKN_U32_MODULE_FMT_NUM_CHANNELS "4"'
`        }'
`}'
`'
`SectionData."NAME_PREFIX.mfcq$1_data" {'
`        tuples "NAME_PREFIX.mfcq$1_tuples"'
`}'
`'
`SectionWidget."NAME_PREFIX.mfcq$1" {'
`        index STR($1)'
`        type "src"'
`        no_pm "true"'
`        subseq "10"'
`        data ['
`                "NAME_PREFIX.sub_graph$2_data"'
`                "NAME_PREFIX.container$3_data"'
`                "NAME_PREFIX.mfcq$1_data"'
`        ]'
`}') dnl
