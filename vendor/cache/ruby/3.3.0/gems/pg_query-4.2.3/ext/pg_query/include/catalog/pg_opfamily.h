/*-------------------------------------------------------------------------
 *
 * pg_opfamily.h
 *	  definition of the "operator family" system catalog (pg_opfamily)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_opfamily.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_OPFAMILY_H
#define PG_OPFAMILY_H

#include "catalog/genbki.h"
#include "catalog/pg_opfamily_d.h"

/* ----------------
 *		pg_opfamily definition. cpp turns this into
 *		typedef struct FormData_pg_opfamily
 * ----------------
 */
CATALOG(pg_opfamily,2753,OperatorFamilyRelationId)
{
	Oid			oid;			/* oid */

	/* index access method opfamily is for */
	Oid			opfmethod BKI_LOOKUP(pg_am);

	/* name of this opfamily */
	NameData	opfname;

	/* namespace of this opfamily */
	Oid			opfnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* opfamily owner */
	Oid			opfowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);
} FormData_pg_opfamily;

/* ----------------
 *		Form_pg_opfamily corresponds to a pointer to a tuple with
 *		the format of pg_opfamily relation.
 * ----------------
 */
typedef FormData_pg_opfamily *Form_pg_opfamily;

DECLARE_UNIQUE_INDEX(pg_opfamily_am_name_nsp_index, 2754, OpfamilyAmNameNspIndexId, on pg_opfamily using btree(opfmethod oid_ops, opfname name_ops, opfnamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_opfamily_oid_index, 2755, OpfamilyOidIndexId, on pg_opfamily using btree(oid oid_ops));

#ifdef EXPOSE_TO_CLIENT_CODE

#define IsBooleanOpfamily(opfamily) \
	((opfamily) == BOOL_BTREE_FAM_OID || (opfamily) == BOOL_HASH_FAM_OID)

#endif							/* EXPOSE_TO_CLIENT_CODE */

#endif							/* PG_OPFAMILY_H */
