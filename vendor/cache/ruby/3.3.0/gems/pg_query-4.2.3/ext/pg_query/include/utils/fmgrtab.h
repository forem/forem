/*-------------------------------------------------------------------------
 *
 * fmgrtab.h
 *	  The function manager's table of internal functions.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/fmgrtab.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef FMGRTAB_H
#define FMGRTAB_H

#include "access/transam.h"
#include "fmgr.h"


/*
 * This table stores info about all the built-in functions (ie, functions
 * that are compiled into the Postgres executable).
 */

typedef struct
{
	Oid			foid;			/* OID of the function */
	short		nargs;			/* 0..FUNC_MAX_ARGS, or -1 if variable count */
	bool		strict;			/* T if function is "strict" */
	bool		retset;			/* T if function returns a set */
	const char *funcName;		/* C name of the function */
	PGFunction	func;			/* pointer to compiled function */
} FmgrBuiltin;

extern PGDLLIMPORT const FmgrBuiltin fmgr_builtins[];

extern PGDLLIMPORT const int fmgr_nbuiltins;	/* number of entries in table */

extern PGDLLIMPORT const Oid fmgr_last_builtin_oid; /* highest function OID in
													 * table */

/*
 * Mapping from a builtin function's OID to its index in the fmgr_builtins
 * array.  This is indexed from 0 through fmgr_last_builtin_oid.
 */
#define InvalidOidBuiltinMapping PG_UINT16_MAX
extern PGDLLIMPORT const uint16 fmgr_builtin_oid_index[];

#endif							/* FMGRTAB_H */
