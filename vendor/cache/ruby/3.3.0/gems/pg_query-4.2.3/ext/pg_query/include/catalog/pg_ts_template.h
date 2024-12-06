/*-------------------------------------------------------------------------
 *
 * pg_ts_template.h
 *	  definition of the "text search template" system catalog (pg_ts_template)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_ts_template.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_TS_TEMPLATE_H
#define PG_TS_TEMPLATE_H

#include "catalog/genbki.h"
#include "catalog/pg_ts_template_d.h"

/* ----------------
 *		pg_ts_template definition.  cpp turns this into
 *		typedef struct FormData_pg_ts_template
 * ----------------
 */
CATALOG(pg_ts_template,3764,TSTemplateRelationId)
{
	Oid			oid;			/* oid */

	/* template name */
	NameData	tmplname;

	/* name space */
	Oid			tmplnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* initialization method of dict (may be 0) */
	regproc		tmplinit BKI_LOOKUP_OPT(pg_proc);

	/* base method of dictionary */
	regproc		tmpllexize BKI_LOOKUP(pg_proc);
} FormData_pg_ts_template;

typedef FormData_pg_ts_template *Form_pg_ts_template;

DECLARE_UNIQUE_INDEX(pg_ts_template_tmplname_index, 3766, TSTemplateNameNspIndexId, on pg_ts_template using btree(tmplname name_ops, tmplnamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_ts_template_oid_index, 3767, TSTemplateOidIndexId, on pg_ts_template using btree(oid oid_ops));

#endif							/* PG_TS_TEMPLATE_H */
