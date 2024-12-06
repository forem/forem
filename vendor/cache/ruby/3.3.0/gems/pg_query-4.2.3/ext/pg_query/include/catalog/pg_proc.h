/*-------------------------------------------------------------------------
 *
 * pg_proc.h
 *	  definition of the "procedure" system catalog (pg_proc)
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_proc.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_PROC_H
#define PG_PROC_H

#include "catalog/genbki.h"
#include "catalog/objectaddress.h"
#include "catalog/pg_proc_d.h"
#include "nodes/pg_list.h"

/* ----------------
 *		pg_proc definition.  cpp turns this into
 *		typedef struct FormData_pg_proc
 * ----------------
 */
CATALOG(pg_proc,1255,ProcedureRelationId) BKI_BOOTSTRAP BKI_ROWTYPE_OID(81,ProcedureRelation_Rowtype_Id) BKI_SCHEMA_MACRO
{
	Oid			oid;			/* oid */

	/* procedure name */
	NameData	proname;

	/* OID of namespace containing this proc */
	Oid			pronamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* procedure owner */
	Oid			proowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* OID of pg_language entry */
	Oid			prolang BKI_DEFAULT(internal) BKI_LOOKUP(pg_language);

	/* estimated execution cost */
	float4		procost BKI_DEFAULT(1);

	/* estimated # of rows out (if proretset) */
	float4		prorows BKI_DEFAULT(0);

	/* element type of variadic array, or 0 if not variadic */
	Oid			provariadic BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_type);

	/* planner support function for this function, or 0 if none */
	regproc		prosupport BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_proc);

	/* see PROKIND_ categories below */
	char		prokind BKI_DEFAULT(f);

	/* security definer */
	bool		prosecdef BKI_DEFAULT(f);

	/* is it a leak-proof function? */
	bool		proleakproof BKI_DEFAULT(f);

	/* strict with respect to NULLs? */
	bool		proisstrict BKI_DEFAULT(t);

	/* returns a set? */
	bool		proretset BKI_DEFAULT(f);

	/* see PROVOLATILE_ categories below */
	char		provolatile BKI_DEFAULT(i);

	/* see PROPARALLEL_ categories below */
	char		proparallel BKI_DEFAULT(s);

	/* number of arguments */
	/* Note: need not be given in pg_proc.dat; genbki.pl will compute it */
	int16		pronargs;

	/* number of arguments with defaults */
	int16		pronargdefaults BKI_DEFAULT(0);

	/* OID of result type */
	Oid			prorettype BKI_LOOKUP(pg_type);

	/*
	 * variable-length fields start here, but we allow direct access to
	 * proargtypes
	 */

	/* parameter types (excludes OUT params) */
	oidvector	proargtypes BKI_LOOKUP(pg_type) BKI_FORCE_NOT_NULL;

#ifdef CATALOG_VARLEN

	/* all param types (NULL if IN only) */
	Oid			proallargtypes[1] BKI_DEFAULT(_null_) BKI_LOOKUP(pg_type);

	/* parameter modes (NULL if IN only) */
	char		proargmodes[1] BKI_DEFAULT(_null_);

	/* parameter names (NULL if no names) */
	text		proargnames[1] BKI_DEFAULT(_null_);

	/* list of expression trees for argument defaults (NULL if none) */
	pg_node_tree proargdefaults BKI_DEFAULT(_null_);

	/* types for which to apply transforms */
	Oid			protrftypes[1] BKI_DEFAULT(_null_) BKI_LOOKUP(pg_type);

	/* procedure source text */
	text		prosrc BKI_FORCE_NOT_NULL;

	/* secondary procedure info (can be NULL) */
	text		probin BKI_DEFAULT(_null_);

	/* pre-parsed SQL function body */
	pg_node_tree prosqlbody BKI_DEFAULT(_null_);

	/* procedure-local GUC settings */
	text		proconfig[1] BKI_DEFAULT(_null_);

	/* access permissions */
	aclitem		proacl[1] BKI_DEFAULT(_null_);
#endif
} FormData_pg_proc;

/* ----------------
 *		Form_pg_proc corresponds to a pointer to a tuple with
 *		the format of pg_proc relation.
 * ----------------
 */
typedef FormData_pg_proc *Form_pg_proc;

DECLARE_TOAST(pg_proc, 2836, 2837);

DECLARE_UNIQUE_INDEX_PKEY(pg_proc_oid_index, 2690, ProcedureOidIndexId, on pg_proc using btree(oid oid_ops));
DECLARE_UNIQUE_INDEX(pg_proc_proname_args_nsp_index, 2691, ProcedureNameArgsNspIndexId, on pg_proc using btree(proname name_ops, proargtypes oidvector_ops, pronamespace oid_ops));

#ifdef EXPOSE_TO_CLIENT_CODE

/*
 * Symbolic values for prokind column
 */
#define PROKIND_FUNCTION 'f'
#define PROKIND_AGGREGATE 'a'
#define PROKIND_WINDOW 'w'
#define PROKIND_PROCEDURE 'p'

/*
 * Symbolic values for provolatile column: these indicate whether the result
 * of a function is dependent *only* on the values of its explicit arguments,
 * or can change due to outside factors (such as parameter variables or
 * table contents).  NOTE: functions having side-effects, such as setval(),
 * must be labeled volatile to ensure they will not get optimized away,
 * even if the actual return value is not changeable.
 */
#define PROVOLATILE_IMMUTABLE	'i' /* never changes for given input */
#define PROVOLATILE_STABLE		's' /* does not change within a scan */
#define PROVOLATILE_VOLATILE	'v' /* can change even within a scan */

/*
 * Symbolic values for proparallel column: these indicate whether a function
 * can be safely be run in a parallel backend, during parallelism but
 * necessarily in the leader, or only in non-parallel mode.
 */
#define PROPARALLEL_SAFE		's' /* can run in worker or leader */
#define PROPARALLEL_RESTRICTED	'r' /* can run in parallel leader only */
#define PROPARALLEL_UNSAFE		'u' /* banned while in parallel mode */

/*
 * Symbolic values for proargmodes column.  Note that these must agree with
 * the FunctionParameterMode enum in parsenodes.h; we declare them here to
 * be accessible from either header.
 */
#define PROARGMODE_IN		'i'
#define PROARGMODE_OUT		'o'
#define PROARGMODE_INOUT	'b'
#define PROARGMODE_VARIADIC 'v'
#define PROARGMODE_TABLE	't'

#endif							/* EXPOSE_TO_CLIENT_CODE */


extern ObjectAddress ProcedureCreate(const char *procedureName,
									 Oid procNamespace,
									 bool replace,
									 bool returnsSet,
									 Oid returnType,
									 Oid proowner,
									 Oid languageObjectId,
									 Oid languageValidator,
									 const char *prosrc,
									 const char *probin,
									 Node *prosqlbody,
									 char prokind,
									 bool security_definer,
									 bool isLeakProof,
									 bool isStrict,
									 char volatility,
									 char parallel,
									 oidvector *parameterTypes,
									 Datum allParameterTypes,
									 Datum parameterModes,
									 Datum parameterNames,
									 List *parameterDefaults,
									 Datum trftypes,
									 Datum proconfig,
									 Oid prosupport,
									 float4 procost,
									 float4 prorows);

extern bool function_parse_error_transpose(const char *prosrc);

extern List *oid_array_to_list(Datum datum);

#endif							/* PG_PROC_H */
