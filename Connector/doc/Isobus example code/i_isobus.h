/*
 * Name:    i_isobus.h
 *
 * Purpose: Header file for Oxford Instruments ISOBUS communication.
 *
 * Author:  William Lavender
 *
 *--------------------------------------------------------------------------
 *
 * Copyright 2008 Illinois Institute of Technology
 *
 * See the file "LICENSE" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef __I_ISOBUS_H__
#define __I_ISOBUS_H__

#define MXF_ISOBUS_RETRY_FOREVER    (-1)

/* Values for 'isobus_flags' */

#define MXF_ISOBUS_DEBUG			0x1
#define MXF_ISOBUS_READ_TERMINATOR_IS_LINEFEED	0x2

typedef struct {
	MX_RECORD *record;

	MX_INTERFACE isobus_interface;
	unsigned long isobus_flags;
} MX_ISOBUS;

#define MXI_ISOBUS_STANDARD_FIELDS \
  {-1, -1, "isobus_interface", MXFT_INTERFACE, NULL, 0, {0}, \
	MXF_REC_TYPE_STRUCT, offsetof(MX_ISOBUS, isobus_interface), \
	{0}, NULL, (MXFF_IN_DESCRIPTION | MXFF_IN_SUMMARY)}, \
  \
  {-1, -1, "isobus_flags", MXFT_HEX, NULL, 0, {0}, \
	MXF_REC_TYPE_STRUCT, offsetof(MX_ISOBUS, isobus_flags), \
	{0}, NULL, MXFF_IN_DESCRIPTION}

MX_API mx_status_type mxi_isobus_create_record_structures( MX_RECORD *record );

MX_API mx_status_type mxi_isobus_open( MX_RECORD *record );

MX_API mx_status_type mxi_isobus_command( MX_ISOBUS *isobus,
					long isobus_address,
					char *command,
					char *response,
					size_t max_response_length,
					long maximum_retries,
					unsigned long isobus_flags );

extern MX_RECORD_FUNCTION_LIST mxi_isobus_record_function_list;

extern long mxi_isobus_num_record_fields;
extern MX_RECORD_FIELD_DEFAULTS *mxi_isobus_rfield_def_ptr;

#endif /* __I_ISOBUS_H__ */

