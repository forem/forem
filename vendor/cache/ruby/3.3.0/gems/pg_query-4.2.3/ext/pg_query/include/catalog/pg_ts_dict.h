/*-------------------------------------------------------------------------
 *
 * pg_ts_dict.h
 *	  definition of the "text search dictionary" system catalog (pg_ts_dict)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_ts_dict.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_TS_DICT_H
#define PG_TS_DICT_H

#include "catalog/genbki.h"
#include "catalog/pg_ts_dict_d.h"

/* ----------------
 *		pg_ts_dict definition.  cpp turns this into
 *		typedef struct FormData_pg_ts_dict
 * ----------------
 */
CATALOG(pg_ts_dict,3600,TSDictionaryRelationId)
{
	/* oid */
	Oid			oid;

	/* dictionary name */
	NameData	dictname;

	/* name space */
	Oid			dictnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* owner */
	Oid			dictowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* dictionary's template */
	Oid			dicttemplate BKI_LOOKUP(pg_ts_template);

#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	/* options passed to dict_init() */
	text		dictinitoption;
#endif
} FormData_pg_ts_dict;

typedef FormData_pg_ts_dict *Form_pg_ts_dict;

DECLARE_TOAST(pg_ts_dict, 4169, 4170);

DECLARE_UNIQUE_INDEX(pg_ts_dict_dictname_index, 3604, TSDictionaryNameNspIndexId, on pg_ts_dict using btree(dictname name_ops, dictnamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_ts_dict_oid_index, 3605, TSDictionaryOidIndexId, on pg_ts_dict using btree(oid oid_ops));

#endif							/* PG_TS_DICT_H */
