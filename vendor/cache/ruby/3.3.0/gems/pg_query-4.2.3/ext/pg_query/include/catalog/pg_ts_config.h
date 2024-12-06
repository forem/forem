/*-------------------------------------------------------------------------
 *
 * pg_ts_config.h
 *	  definition of the "text search configuration" system catalog
 *	  (pg_ts_config)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_ts_config.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_TS_CONFIG_H
#define PG_TS_CONFIG_H

#include "catalog/genbki.h"
#include "catalog/pg_ts_config_d.h"

/* ----------------
 *		pg_ts_config definition.  cpp turns this into
 *		typedef struct FormData_pg_ts_config
 * ----------------
 */
CATALOG(pg_ts_config,3602,TSConfigRelationId)
{
	/* oid */
	Oid			oid;

	/* name of configuration */
	NameData	cfgname;

	/* name space */
	Oid			cfgnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* owner */
	Oid			cfgowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* OID of parser */
	Oid			cfgparser BKI_LOOKUP(pg_ts_parser);
} FormData_pg_ts_config;

typedef FormData_pg_ts_config *Form_pg_ts_config;

DECLARE_UNIQUE_INDEX(pg_ts_config_cfgname_index, 3608, TSConfigNameNspIndexId, on pg_ts_config using btree(cfgname name_ops, cfgnamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_ts_config_oid_index, 3712, TSConfigOidIndexId, on pg_ts_config using btree(oid oid_ops));

#endif							/* PG_TS_CONFIG_H */
