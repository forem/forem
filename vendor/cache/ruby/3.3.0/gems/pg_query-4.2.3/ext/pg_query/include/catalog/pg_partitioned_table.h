/*-------------------------------------------------------------------------
 *
 * pg_partitioned_table.h
 *	  definition of the "partitioned table" system catalog
 *	  (pg_partitioned_table)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_partitioned_table.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_PARTITIONED_TABLE_H
#define PG_PARTITIONED_TABLE_H

#include "catalog/genbki.h"
#include "catalog/pg_partitioned_table_d.h"

/* ----------------
 *		pg_partitioned_table definition.  cpp turns this into
 *		typedef struct FormData_pg_partitioned_table
 * ----------------
 */
CATALOG(pg_partitioned_table,3350,PartitionedRelationId)
{
	Oid			partrelid BKI_LOOKUP(pg_class); /* partitioned table oid */
	char		partstrat;		/* partitioning strategy */
	int16		partnatts;		/* number of partition key columns */
	Oid			partdefid BKI_LOOKUP_OPT(pg_class); /* default partition oid;
													 * 0 if there isn't one */

	/*
	 * variable-length fields start here, but we allow direct access to
	 * partattrs via the C struct.  That's because the first variable-length
	 * field of a heap tuple can be reliably accessed using its C struct
	 * offset, as previous fields are all non-nullable fixed-length fields.
	 */
	int2vector	partattrs BKI_FORCE_NOT_NULL;	/* each member of the array is
												 * the attribute number of a
												 * partition key column, or 0
												 * if the column is actually
												 * an expression */

#ifdef CATALOG_VARLEN
	oidvector	partclass BKI_LOOKUP(pg_opclass) BKI_FORCE_NOT_NULL;	/* operator class to
																		 * compare keys */
	oidvector	partcollation BKI_LOOKUP_OPT(pg_collation) BKI_FORCE_NOT_NULL;	/* user-specified
																				 * collation for keys */
	pg_node_tree partexprs;		/* list of expressions in the partition key;
								 * one item for each zero entry in partattrs[] */
#endif
} FormData_pg_partitioned_table;

/* ----------------
 *		Form_pg_partitioned_table corresponds to a pointer to a tuple with
 *		the format of pg_partitioned_table relation.
 * ----------------
 */
typedef FormData_pg_partitioned_table *Form_pg_partitioned_table;

DECLARE_TOAST(pg_partitioned_table, 4165, 4166);

DECLARE_UNIQUE_INDEX_PKEY(pg_partitioned_table_partrelid_index, 3351, PartitionedRelidIndexId, on pg_partitioned_table using btree(partrelid oid_ops));

/* partattrs can contain zero (InvalidAttrNumber) to represent expressions */
DECLARE_ARRAY_FOREIGN_KEY_OPT((partrelid, partattrs), pg_attribute, (attrelid, attnum));

#endif							/* PG_PARTITIONED_TABLE_H */
