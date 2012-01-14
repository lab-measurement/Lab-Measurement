/*
 * Name:    i_isobus.c
 *
 * Purpose: MX interface driver for Oxford Instruments ISOBUS devices.
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

#define MXI_ISOBUS_DEBUG	FALSE

#include <stdio.h>
#include <stdlib.h>

#include "mx_util.h"
#include "mx_record.h"
#include "mx_driver.h"
#include "mx_ascii.h"
#include "mx_rs232.h"
#include "mx_gpib.h"
#include "i_isobus.h"

MX_RECORD_FUNCTION_LIST mxi_isobus_record_function_list = {
	NULL,
	mxi_isobus_create_record_structures,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	mxi_isobus_open
};

MX_RECORD_FIELD_DEFAULTS mxi_isobus_record_field_defaults[] = {
	MX_RECORD_STANDARD_FIELDS,
	MXI_ISOBUS_STANDARD_FIELDS
};

long mxi_isobus_num_record_fields
		= sizeof( mxi_isobus_record_field_defaults )
			/ sizeof( mxi_isobus_record_field_defaults[0] );

MX_RECORD_FIELD_DEFAULTS *mxi_isobus_rfield_def_ptr
			= &mxi_isobus_record_field_defaults[0];

MX_EXPORT mx_status_type
mxi_isobus_create_record_structures( MX_RECORD *record )
{
	static const char fname[] = "mxi_isobus_create_record_structures()";

	MX_ISOBUS *isobus;

	/* Allocate memory for the necessary structures. */

	isobus = (MX_ISOBUS *) malloc( sizeof(MX_ISOBUS) );

	if ( isobus == (MX_ISOBUS *) NULL ) {
		return mx_error( MXE_OUT_OF_MEMORY, fname,
		"Can't allocate memory for MX_ISOBUS structure." );
	}

	/* Now set up the necessary pointers. */

	record->record_class_struct = NULL;
	record->record_type_struct = isobus;

	record->record_function_list = &mxi_isobus_record_function_list;
	record->superclass_specific_function_list = NULL;
	record->class_specific_function_list = NULL;

	isobus->record = record;

	return MX_SUCCESSFUL_RESULT;
}

MX_EXPORT mx_status_type
mxi_isobus_open( MX_RECORD *record )
{
	static const char fname[] = "mxi_isobus_open()";

	MX_ISOBUS *isobus;
	MX_RECORD *interface_record;
	unsigned long isobus_flags, read_terminator;
	mx_status_type mx_status;

	if ( record == (MX_RECORD *) NULL ) {
		return mx_error( MXE_NULL_ARGUMENT, fname,
			"MX_RECORD pointer passed is NULL.");
	}

	isobus = (MX_ISOBUS *) record->record_type_struct;

	if ( isobus == (MX_ISOBUS *) NULL ) {
		return mx_error( MXE_CORRUPT_DATA_STRUCTURE, fname,
		"MX_ISOBUS pointer for record '%s' is NULL.", record->name);
	}

	isobus_flags = isobus->isobus_flags;

#if MXI_ISOBUS_DEBUG
	MX_DEBUG(-2,("%s invoked for record '%s', isobus_flags = %#lx.",
		fname, record->name, isobus_flags ));
#endif

	interface_record = isobus->isobus_interface.record;

	switch( interface_record->mx_class ) {
	case MXI_RS232:
		/* Verify that the RS-232 port has the right settings. */

		if ( isobus_flags & MXF_ISOBUS_READ_TERMINATOR_IS_LINEFEED ) {
			read_terminator = MX_LF;
		} else {
			read_terminator = MX_CR;
		}

		mx_status = mx_rs232_verify_configuration( interface_record,
				9600, 8, 'N', 1, 'N', read_terminator, 0x0d );

		if ( mx_status.code != MXE_SUCCESS )
			return mx_status;

		/* Reinitialize the serial port. */

		mx_status = mx_resynchronize_record( interface_record );

		if ( mx_status.code != MXE_SUCCESS )
			return mx_status;

		mx_msleep(1000);

		/* Discard any characters waiting to be sent or received. */

		mx_status = mx_rs232_discard_unwritten_output(
					interface_record, MXI_ISOBUS_DEBUG );

		if ( mx_status.code != MXE_SUCCESS )
			return mx_status;

		mx_status = mx_rs232_discard_unread_input(
					interface_record, MXI_ISOBUS_DEBUG );

		if ( mx_status.code != MXE_SUCCESS )
			return mx_status;
		break;

	case MXI_GPIB:
		/* GPIB does not require any initialization. */

		break;
	
	default:
		return mx_error( MXE_TYPE_MISMATCH, fname,
		"Only RS-232 and GPIB interfaces are supported for "
		"ISOBUS interface '%s'.  Interface record '%s' is "
		"of unsupported type '%s'.",
			record->name, interface_record->name,
			mx_get_driver_name( interface_record ) );

		break;
	}

	return MX_SUCCESSFUL_RESULT;
}

/*---*/

MX_EXPORT mx_status_type
mxi_isobus_command( MX_ISOBUS *isobus,
		long isobus_address,
		char *command,
		char *response,
		size_t max_response_length,
		long maximum_retries,
		unsigned long isobus_flags )
{
	static const char fname[] = "mxi_isobus_command()";

	MX_RECORD *interface_record;
	long gpib_address;
	char local_command_buffer[100];
	char *command_ptr;
	size_t length;
	long i, j, rs232_retries;
	unsigned long wait_ms, num_input_bytes_available;
	mx_bool_type error_occurred;
	mx_status_type mx_status;

	if ( isobus == (MX_ISOBUS *) NULL ) {
		return mx_error( MXE_NULL_ARGUMENT, fname,
		"The MX_ISOBUS pointer passed was NULL." );
	}
	if ( command == (char *) NULL ) {
		return mx_error( MXE_NULL_ARGUMENT, fname,
		"The command pointer passed was NULL." );
	}

	interface_record = isobus->isobus_interface.record;

	if ( interface_record == (MX_RECORD *) NULL ) {
		return mx_error( MXE_CORRUPT_DATA_STRUCTURE, fname,
	    "The interface record pointer for ISOBUS interface '%s' is NULL.",
			isobus->record->name );
	}

	/* Format the command to be sent. */

	if ( isobus_address < 0 ) {
		command_ptr = command;
	} else {
		command_ptr = local_command_buffer;

		snprintf( local_command_buffer, sizeof(local_command_buffer),
			"@%ld%s", isobus_address, command );
	}

	if ( maximum_retries < 0 ) {
		maximum_retries = LONG_MAX;
	}

	error_occurred = FALSE;

	for ( i = 0; i <= maximum_retries; i++ ) {

		if ( i > 0 ) {
			mx_info( "ISOBUS interface '%s' command retry #%ld.",
				isobus->record->name, i );
		}

		/* Send the command and get the response. */

		if ( isobus_flags & MXF_ISOBUS_DEBUG ) {

			MX_DEBUG(-2,("%s: sending command '%s' to '%s'.",
			    fname, command_ptr, isobus->record->name));
		}

		error_occurred = FALSE;

		if ( interface_record->mx_class == MXI_RS232 ) {
			mx_status = mx_rs232_putline( interface_record,
						command_ptr, NULL, 0 );

			if ( mx_status.code != MXE_SUCCESS )
				return mx_status;

			if ( response != NULL ) {
				/* Wait for the response. */

				rs232_retries = 50;
				wait_ms = 100;

				for ( j = 0; j <= rs232_retries; j++ ) {

					/* See if the first character
					 * has arrived.
					 */

					mx_status =
					  mx_rs232_num_input_bytes_available(
						interface_record,
						&num_input_bytes_available );

					if ( mx_status.code != MXE_SUCCESS ) {
						/* Exit the for(j) loop. */

						break;  
					}

					if ( num_input_bytes_available > 0 ) {
						/* Exit the for(j) loop. */

						break;  
					}
				}

				if ( mx_status.code != MXE_SUCCESS ) {
					error_occurred = TRUE;
				} else {
					/* Read in the response. */

					mx_status = mx_rs232_getline(
						interface_record, response,
						max_response_length, NULL, 0);

					if ( mx_status.code != MXE_SUCCESS ) {
						error_occurred = TRUE;
					} else {
						/* Remove any trailing carriage
						 * return characters.
						 */

						length = strlen( response );

						if (length <
							max_response_length )
						{
							if ( response[length-1]
								== MX_CR )
							{
							    response[length-1]
								= '\0';
							}
						}
					}
				}
			}
		} else {	/* GPIB */

			gpib_address = isobus->isobus_interface.address;

			mx_status = mx_gpib_putline(
						interface_record, gpib_address,
						command_ptr, NULL, 0 );

			if ( mx_status.code != MXE_SUCCESS )
				return mx_status;

			if ( response != NULL ) {
				mx_status = mx_gpib_getline(
					interface_record, gpib_address,
					response, max_response_length, NULL, 0);

				if ( mx_status.code != MXE_SUCCESS ) {
					error_occurred = TRUE;
				}
			}
		}

		if ( error_occurred == FALSE ) {

			/* If the first character in the response is a
			 * question mark '?', then an error occurred.
			 */

			if ( response != NULL ) {
				if ( response[0] == '?' ) {

					mx_status = mx_error(
						MXE_DEVICE_ACTION_FAILED, fname,
			"The command '%s' to ISOBUS interface '%s' failed.  "
			"Controller error message = '%s'", command_ptr,
					isobus->record->name, response );

					error_occurred = TRUE;
				} else {
					if ( isobus_flags & MXF_ISOBUS_DEBUG )
					{
						MX_DEBUG(-2,("%s: received "
						"response '%s' from '%s'",
							fname, response,
							isobus->record->name ));
					}
				}
			}
		}

		if ( error_occurred == FALSE ) {
			break;		/* Exit the for() loop. */
		}
	}

	if ( error_occurred ) {
		return mx_error( MXE_TIMED_OUT, fname,
	"The command '%s' to ISOBUS interface '%s' is still failing "
	"after %ld retries.  Giving up...", command_ptr,
				isobus->record->name,
				maximum_retries );
	} else {
		return MX_SUCCESSFUL_RESULT;
	}
}

