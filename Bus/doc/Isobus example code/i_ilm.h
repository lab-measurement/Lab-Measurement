/*
 * Name:    i_ilm.h
 *
 * Purpose: Header file for Oxford Instruments ILM
 *          (Intelligent Level Meter) controllers.
 *
 * Author:  William Lavender
 *
 *--------------------------------------------------------------------------
 *
 * Copyright 2008-2009 Illinois Institute of Technology
 *
 * See the file "LICENSE" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef __I_ILM_H__
#define __I_ILM_H__

/* Values for 'ilm_flags' below */

#define MXF_ILM_ENABLE_REMOTE_MODE	0x1
#define MXF_ILM_UNLOCK			0x2

/* The two lowest order bits in 'ilm_flags' are used to
 * construct a 'Cn' control command.  The 'Cn' determines whether
 * or not the controller is in LOCAL or REMOTE mode and also
 * whether or not the LOC/REM button is locked or active.  The
 * possible values for the 'Cn' command are:
 * 
 * C0 - Local and locked (default state)
 * C1 - Remote and locked (front panel disabled)
 * C2 - Local and unlocked
 * C3 - Remote and unlocked (front panel disabled)
 */

typedef struct {
	MX_RECORD *record;

	MX_RECORD *isobus_record;
	long isobus_address;

	unsigned long ilm_flags;

	long maximum_retries;
} MX_ILM;

#define MXI_ILM_STANDARD_FIELDS \
  {-1, -1, "isobus_record", MXFT_RECORD, NULL, 0, {0}, \
	MXF_REC_TYPE_STRUCT, offsetof(MX_ILM, isobus_record), \
	{0}, NULL, (MXFF_IN_DESCRIPTION | MXFF_IN_SUMMARY)}, \
  \
  {-1, -1, "isobus_address", MXFT_LONG, NULL, 0, {0}, \
  	MXF_REC_TYPE_STRUCT, offsetof(MX_ILM, isobus_address), \
	{0}, NULL, (MXFF_IN_DESCRIPTION | MXFF_IN_SUMMARY)}, \
  \
  {-1, -1, "ilm_flags", MXFT_HEX, NULL, 0, {0}, \
  	MXF_REC_TYPE_STRUCT, offsetof(MX_ILM, ilm_flags), \
	{0}, NULL, MXFF_IN_DESCRIPTION}, \
  \
  {-1, -1, "maximum_retries", MXFT_LONG, NULL, 0, {0}, \
  	MXF_REC_TYPE_STRUCT, offsetof(MX_ILM, maximum_retries), \
	{0}, NULL, MXFF_IN_DESCRIPTION}

MX_API mx_status_type mxi_ilm_create_record_structures( MX_RECORD *record );

MX_API mx_status_type mxi_ilm_open( MX_RECORD *record );

extern MX_RECORD_FUNCTION_LIST mxi_ilm_record_function_list;

extern long mxi_ilm_num_record_fields;
extern MX_RECORD_FIELD_DEFAULTS *mxi_ilm_rfield_def_ptr;

#endif /* __I_ILM_H__ */

