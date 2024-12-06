/*-------------------------------------------------------------------------
 *
 * pg_index.h
 *	  definition of the "index" system catalog (pg_index)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_index.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_INDEX_H
#define PG_INDEX_H

#include "catalog/genbki.h"
#include "catalog/pg_index_d.h"

/* ----------------
 *		pg_index definition.  cpp turns this into
 *		typedef struct FormData_pg_index.
 * ----------------
 */
CATALOG(pg_index,2610,IndexRelationId) BKI_SCHEMA_MACRO
{
	Oid			indexrelid BKI_LOOKUP(pg_class);	/* OID of the index */
	Oid			indrelid BKI_LOOKUP(pg_class);	/* OID of the relation it
												 * indexes */
	int16		indnatts;		/* total number of columns in index */
	int16		indnkeyatts;	/* number of key columns in index */
	bool		indisunique;	/* is this a unique index? */
	bool		indnullsnotdistinct;	/* null treatment in unique index */
	bool		indisprimary;	/* is this index for primary key? */
	bool		indisexclusion; /* is this index for exclusion constraint? */
	bool		indimmediate;	/* is uniqueness enforced immediately? */
	bool		indisclustered; /* is this the index last clustered by? */
	bool		indisvalid;		/* is this index valid for use by queries? */
	bool		indcheckxmin;	/* must we wait for xmin to be old? */
	bool		indisready;		/* is this index ready for inserts? */
	bool		indislive;		/* is this index alive at all? */
	bool		indisreplident; /* is this index the identity for replication? */

	/* variable-length fields start here, but we allow direct access to indkey */
	int2vector	indkey BKI_FORCE_NOT_NULL;	/* column numbers of indexed cols,
											 * or 0 */

#ifdef CATALOG_VARLEN
	oidvector	indcollation BKI_LOOKUP_OPT(pg_collation) BKI_FORCE_NOT_NULL;	/* collation identifiers */
	oidvector	indclass BKI_LOOKUP(pg_opclass) BKI_FORCE_NOT_NULL; /* opclass identifiers */
	int2vector	indoption BKI_FORCE_NOT_NULL;	/* per-column flags
												 * (AM-specific meanings) */
	pg_node_tree indexprs;		/* expression trees for index attributes that
								 * are not simple column references; one for
								 * each zero entry in indkey[] */
	pg_node_tree indpred;		/* expression tree for predicate, if a partial
								 * index; else NULL */
#endif
} FormData_pg_index;

/* ----------------
 *		Form_pg_index corresponds to a pointer to a tuple with
 *		the format of pg_index relation.
 * ----------------
 */
typedef FormData_pg_index *Form_pg_index;

DECLARE_INDEX(pg_index_indrelid_index, 2678, IndexIndrelidIndexId, on pg_index using btree(indrelid oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_index_indexrelid_index, 2679, IndexRelidIndexId, on pg_index using btree(indexrelid oid_ops));

/* indkey can contain zero (InvalidAttrNumber) to represent expressions */
DECLARE_ARRAY_FOREIGN_KEY_OPT((indrelid, indkey), pg_attribute, (attrelid, attnum));

#ifdef EXPOSE_TO_CLIENT_CODE

/*
 * Index AMs that support ordered scans must support these two indoption
 * bits.  Otherwise, the content of the per-column indoption fields is
 * open for future definition.
 */
#define INDOPTION_DESC			0x0001	/* values are in reverse order */
#define INDOPTION_NULLS_FIRST	0x0002	/* NULLs are first instead of last */

#endif							/* EXPOSE_TO_CLIENT_CODE */

#endif							/* PG_INDEX_H */
