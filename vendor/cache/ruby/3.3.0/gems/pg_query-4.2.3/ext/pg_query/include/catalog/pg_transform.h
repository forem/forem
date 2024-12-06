/*-------------------------------------------------------------------------
 *
 * pg_transform.h
 *	  definition of the "transform" system catalog (pg_transform)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_transform.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_TRANSFORM_H
#define PG_TRANSFORM_H

#include "catalog/genbki.h"
#include "catalog/pg_transform_d.h"

/* ----------------
 *		pg_transform definition.  cpp turns this into
 *		typedef struct FormData_pg_transform
 * ----------------
 */
CATALOG(pg_transform,3576,TransformRelationId)
{
	Oid			oid;			/* oid */
	Oid			trftype BKI_LOOKUP(pg_type);
	Oid			trflang BKI_LOOKUP(pg_language);
	regproc		trffromsql BKI_LOOKUP_OPT(pg_proc);
	regproc		trftosql BKI_LOOKUP_OPT(pg_proc);
} FormData_pg_transform;

/* ----------------
 *		Form_pg_transform corresponds to a pointer to a tuple with
 *		the format of pg_transform relation.
 * ----------------
 */
typedef FormData_pg_transform *Form_pg_transform;

DECLARE_UNIQUE_INDEX_PKEY(pg_transform_oid_index, 3574, TransformOidIndexId, on pg_transform using btree(oid oid_ops));
DECLARE_UNIQUE_INDEX(pg_transform_type_lang_index, 3575, TransformTypeLangIndexId, on pg_transform using btree(trftype oid_ops, trflang oid_ops));

#endif							/* PG_TRANSFORM_H */
