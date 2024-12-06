/*-------------------------------------------------------------------------
 *
 * pg_operator.h
 *	  definition of the "operator" system catalog (pg_operator)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_operator.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_OPERATOR_H
#define PG_OPERATOR_H

#include "catalog/genbki.h"
#include "catalog/objectaddress.h"
#include "catalog/pg_operator_d.h"
#include "nodes/pg_list.h"

/* ----------------
 *		pg_operator definition.  cpp turns this into
 *		typedef struct FormData_pg_operator
 * ----------------
 */
CATALOG(pg_operator,2617,OperatorRelationId)
{
	Oid			oid;			/* oid */

	/* name of operator */
	NameData	oprname;

	/* OID of namespace containing this oper */
	Oid			oprnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* operator owner */
	Oid			oprowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* 'l' for prefix or 'b' for infix */
	char		oprkind BKI_DEFAULT(b);

	/* can be used in merge join? */
	bool		oprcanmerge BKI_DEFAULT(f);

	/* can be used in hash join? */
	bool		oprcanhash BKI_DEFAULT(f);

	/* left arg type, or 0 if prefix operator */
	Oid			oprleft BKI_LOOKUP_OPT(pg_type);

	/* right arg type */
	Oid			oprright BKI_LOOKUP(pg_type);

	/* result datatype; can be 0 in a "shell" operator */
	Oid			oprresult BKI_LOOKUP_OPT(pg_type);

	/* OID of commutator oper, or 0 if none */
	Oid			oprcom BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_operator);

	/* OID of negator oper, or 0 if none */
	Oid			oprnegate BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_operator);

	/* OID of underlying function; can be 0 in a "shell" operator */
	regproc		oprcode BKI_LOOKUP_OPT(pg_proc);

	/* OID of restriction estimator, or 0 */
	regproc		oprrest BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* OID of join estimator, or 0 */
	regproc		oprjoin BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);
} FormData_pg_operator;

/* ----------------
 *		Form_pg_operator corresponds to a pointer to a tuple with
 *		the format of pg_operator relation.
 * ----------------
 */
typedef FormData_pg_operator *Form_pg_operator;

DECLARE_UNIQUE_INDEX_PKEY(pg_operator_oid_index, 2688, OperatorOidIndexId, on pg_operator using btree(oid oid_ops));
DECLARE_UNIQUE_INDEX(pg_operator_oprname_l_r_n_index, 2689, OperatorNameNspIndexId, on pg_operator using btree(oprname name_ops, oprleft oid_ops, oprright oid_ops, oprnamespace oid_ops));


extern ObjectAddress OperatorCreate(const char *operatorName,
									Oid operatorNamespace,
									Oid leftTypeId,
									Oid rightTypeId,
									Oid procedureId,
									List *commutatorName,
									List *negatorName,
									Oid restrictionId,
									Oid joinId,
									bool canMerge,
									bool canHash);

extern ObjectAddress makeOperatorDependencies(HeapTuple tuple,
											  bool makeExtensionDep,
											  bool isUpdate);

extern void OperatorUpd(Oid baseId, Oid commId, Oid negId, bool isDelete);

#endif							/* PG_OPERATOR_H */
