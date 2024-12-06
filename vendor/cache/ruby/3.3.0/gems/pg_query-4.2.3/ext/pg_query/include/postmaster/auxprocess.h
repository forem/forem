/*-------------------------------------------------------------------------
 * auxprocess.h
 *	  include file for functions related to auxiliary processes.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *		src/include/postmaster/auxprocess.h
 *-------------------------------------------------------------------------
 */
#ifndef AUXPROCESS_H
#define AUXPROCESS_H

#include "miscadmin.h"

extern void AuxiliaryProcessMain(AuxProcType auxtype) pg_attribute_noreturn();

#endif							/* AUXPROCESS_H */
