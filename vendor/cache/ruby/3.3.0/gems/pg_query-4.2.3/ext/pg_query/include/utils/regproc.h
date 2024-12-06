/*-------------------------------------------------------------------------
 *
 * regproc.h
 *	  Functions for the built-in types regproc, regclass, regtype, etc.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/regproc.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef REGPROC_H
#define REGPROC_H

#include "nodes/pg_list.h"

/* Control flags for format_procedure_extended */
#define FORMAT_PROC_INVALID_AS_NULL	0x01	/* NULL if undefined */
#define FORMAT_PROC_FORCE_QUALIFY	0x02	/* force qualification */
extern char *format_procedure_extended(Oid procedure_oid, bits16 flags);

/* Control flags for format_operator_extended */
#define FORMAT_OPERATOR_INVALID_AS_NULL	0x01	/* NULL if undefined */
#define FORMAT_OPERATOR_FORCE_QUALIFY	0x02	/* force qualification */
extern char *format_operator_extended(Oid operator_oid, bits16 flags);

extern List *stringToQualifiedNameList(const char *string);
extern char *format_procedure(Oid procedure_oid);
extern char *format_procedure_qualified(Oid procedure_oid);
extern void format_procedure_parts(Oid operator_oid, List **objnames,
								   List **objargs, bool missing_ok);

extern char *format_operator(Oid operator_oid);
extern char *format_operator_qualified(Oid operator_oid);
extern void format_operator_parts(Oid operator_oid, List **objnames,
								  List **objargs, bool missing_ok);

#endif
