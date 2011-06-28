/*
 * Name:    i_ilm.c
 *
 * Purpose: MX driver for Oxford Instruments ILM (Intelligent Level Meter)
 *          controllers.
 *          
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

#define MXI_ILM_DEBUG	FALSE

#include <stdio.h>
#include <stdlib.h>

#include "mx_util.h"
#include "mx_record.h"
#include "i_isobus.h"
#include "i_ilm.h"

MX_RECORD_FUNCTION_LIST mxi_ilm_record_function_list = {
	NULL,
	mxi_ilm_create_record_structures,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	mxi_ilm_open
};

MX_RECORD_FIELD_DEFAULTS mxi_ilm_record_field_defaults[] = {
	MX_RECORD_STANDARD_FIELDS,
	MXI_ILM_STANDARD_FIELDS
};

long mxi_ilm_num_record_fields
		= sizeof( mxi_ilm_record_field_defaults )
			/ sizeof( mxi_ilm_record_field_defaults[0] );

MX_RECORD_FIELD_DEFAULTS *mxi_ilm_rfield_def_ptr
			= &mxi_ilm_record_field_defaults[0];

MX_EXPORT mx_status_type
mxi_ilm_create_record_structures( MX_RECORD *record )
{
	static const char fname[] = "mxi_ilm_create_record_structures()";

	MX_ILM *ilm;

	/* Allocate memory for the necessary structures. */

	ilm = (MX_ILM *) malloc( sizeof(MX_ILM) );

	if ( ilm == (MX_ILM *) NULL ) {
		return mx_error( MXE_OUT_OF_MEMORY, fname,
		"Can't allocate memory for MX_ILM structure." );
	}

	/* Now set up the necessary pointers. */

	record->record_class_struct = NULL;
	record->record_type_struct = ilm;

	record->record_function_list = &mxi_ilm_record_function_list;
	record->superclass_specific_function_list = NULL;
	record->class_specific_function_list = NULL;

	ilm->record = record;

	return MX_SUCCESSFUL_RESULT;
}

MX_EXPORT mx_status_type
mxi_ilm_open( MX_RECORD *record )
{
	static const char fname[] = "mxi_ilm_open()";

	MX_ILM *ilm;
	MX_ISOBUS *isobus;
	char command[10];
	char response[40];
	int c_command_value;
	mx_status_type mx_status;

	if ( record == (MX_RECORD *) NULL ) {
		return mx_error( MXE_NULL_ARGUMENT, fname,
			"MX_RECORD pointer passed is NULL.");
	}

#if MXI_ILM_DEBUG
	MX_DEBUG(-2,("%s invoked for record '%s'.", fname, record->name ));
#endif

	ilm = (MX_ILM *) record->record_type_struct;

	if ( ilm == (MX_ILM *) NULL ) {
		return mx_error( MXE_CORRUPT_DATA_STRUCTURE, fname,
		"MX_ILM pointer for record '%s' is NULL.", record->name);
	}

	if ( ilm->isobus_record == NULL ) {
		return mx_error( MXE_CORRUPT_DATA_STRUCTURE, fname,
		"isobus_record pointer for record '%s' is NULL.", record->name);
	}

	isobus = ilm->isobus_record->record_type_struct;

	if ( isobus == (MX_ISOBUS *) NULL ) {
		return mx_error( MXE_CORRUPT_DATA_STRUCTURE, fname,
		"MX_ISOBUS pointer for ISOBUS record '%s' is NULL.",
			ilm->isobus_record->name );
	}

	/* Tell the ILM to terminate responses only with a <CR> character. */

	mx_status = mxi_isobus_command( isobus, ilm->isobus_address,
					"Q0", NULL, 0, -1,
					MXI_ILM_DEBUG );

	if ( mx_status.code != MXE_SUCCESS )
		return mx_status;

	/* Ask for the version number of the controller. */

	mx_status = mxi_isobus_command( isobus, ilm->isobus_address,
					"V", response, sizeof(response),
					ilm->maximum_retries,
					MXI_ILM_DEBUG );

	if ( mx_status.code != MXE_SUCCESS )
		return mx_status;

#if MXI_ILM_DEBUG
	MX_DEBUG(-2,("%s: ILM controller '%s' version = '%s'",
		fname, record->name, response));
#endif

	if ( strncmp( response, "ILM", 3 ) != 0 ) {
		return mx_error( MXE_DEVICE_IO_ERROR, fname,
		"ILM controller '%s' did not return the expected "
		"version string in its response to the V command.  "
		"Response = '%s'",
			record->name, response );
	}

	/* Send a 'Cn' control command.  See the header file
	 * 'i_ilm.h' for a description of this command.
	 */

	c_command_value = (int) ( ilm->ilm_flags & 0x3 );

	snprintf( command, sizeof(command), "C%d", c_command_value );

	mx_status = mxi_isobus_command( isobus, ilm->isobus_address,
					command, response, sizeof(response),
					ilm->maximum_retries,
					MXI_ILM_DEBUG );

	return mx_status;
}

