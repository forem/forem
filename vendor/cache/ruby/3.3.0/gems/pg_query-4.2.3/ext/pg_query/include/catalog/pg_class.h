/*-------------------------------------------------------------------------
 *
 * pg_class.h
 *	  definition of the "relation" system catalog (pg_class)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_class.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_CLASS_H
#define PG_CLASS_H

#include "catalog/genbki.h"
#include "catalog/pg_class_d.h"

/* ----------------
 *		pg_class definition.  cpp turns this into
 *		typedef struct FormData_pg_class
 *
 * Note that the BKI_DEFAULT values below are only used for rows describing
 * BKI_BOOTSTRAP catalogs, since only those rows appear in pg_class.dat.
 * ----------------
 */
CATALOG(pg_class,1259,RelationRelationId) BKI_BOOTSTRAP BKI_ROWTYPE_OID(83,RelationRelation_Rowtype_Id) BKI_SCHEMA_MACRO
{
	/* oid */
	Oid			oid;

	/* class name */
	NameData	relname;

	/* OID of namespace containing this class */
	Oid			relnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* OID of entry in pg_type for relation's implicit row type, if any */
	Oid			reltype BKI_LOOKUP_OPT(pg_type);

	/* OID of entry in pg_type for underlying composite type, if any */
	Oid			reloftype BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_type);

	/* class owner */
	Oid			relowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* access method; 0 if not a table / index */
	Oid			relam BKI_DEFAULT(heap) BKI_LOOKUP_OPT(pg_am);

	/* identifier of physical storage file */
	/* relfilenode == 0 means it is a "mapped" relation, see relmapper.c */
	Oid			relfilenode BKI_DEFAULT(0);

	/* identifier of table space for relation (0 means default for database) */
	Oid			reltablespace BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_tablespace);

	/* # of blocks (not always up-to-date) */
	int32		relpages BKI_DEFAULT(0);

	/* # of tuples (not always up-to-date; -1 means "unknown") */
	float4		reltuples BKI_DEFAULT(-1);

	/* # of all-visible blocks (not always up-to-date) */
	int32		relallvisible BKI_DEFAULT(0);

	/* OID of toast table; 0 if none */
	Oid			reltoastrelid BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_class);

	/* T if has (or has had) any indexes */
	bool		relhasindex BKI_DEFAULT(f);

	/* T if shared across databases */
	bool		relisshared BKI_DEFAULT(f);

	/* see RELPERSISTENCE_xxx constants below */
	char		relpersistence BKI_DEFAULT(p);

	/* see RELKIND_xxx constants below */
	char		relkind BKI_DEFAULT(r);

	/* number of user attributes */
	int16		relnatts BKI_DEFAULT(0);	/* genbki.pl will fill this in */

	/*
	 * Class pg_attribute must contain exactly "relnatts" user attributes
	 * (with attnums ranging from 1 to relnatts) for this class.  It may also
	 * contain entries with negative attnums for system attributes.
	 */

	/* # of CHECK constraints for class */
	int16		relchecks BKI_DEFAULT(0);

	/* has (or has had) any rules */
	bool		relhasrules BKI_DEFAULT(f);

	/* has (or has had) any TRIGGERs */
	bool		relhastriggers BKI_DEFAULT(f);

	/* has (or has had) child tables or indexes */
	bool		relhassubclass BKI_DEFAULT(f);

	/* row security is enabled or not */
	bool		relrowsecurity BKI_DEFAULT(f);

	/* row security forced for owners or not */
	bool		relforcerowsecurity BKI_DEFAULT(f);

	/* matview currently holds query results */
	bool		relispopulated BKI_DEFAULT(t);

	/* see REPLICA_IDENTITY_xxx constants */
	char		relreplident BKI_DEFAULT(n);

	/* is relation a partition? */
	bool		relispartition BKI_DEFAULT(f);

	/* link to original rel during table rewrite; otherwise 0 */
	Oid			relrewrite BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_class);

	/* all Xids < this are frozen in this rel */
	TransactionId relfrozenxid BKI_DEFAULT(3);	/* FirstNormalTransactionId */

	/* all multixacts in this rel are >= this; it is really a MultiXactId */
	TransactionId relminmxid BKI_DEFAULT(1);	/* FirstMultiXactId */

#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	/* NOTE: These fields are not present in a relcache entry's rd_rel field. */
	/* access permissions */
	aclitem		relacl[1] BKI_DEFAULT(_null_);

	/* access-method-specific options */
	text		reloptions[1] BKI_DEFAULT(_null_);

	/* partition bound node tree */
	pg_node_tree relpartbound BKI_DEFAULT(_null_);
#endif
} FormData_pg_class;

/* Size of fixed part of pg_class tuples, not counting var-length fields */
#define CLASS_TUPLE_SIZE \
	 (offsetof(FormData_pg_class,relminmxid) + sizeof(TransactionId))

/* ----------------
 *		Form_pg_class corresponds to a pointer to a tuple with
 *		the format of pg_class relation.
 * ----------------
 */
typedef FormData_pg_class *Form_pg_class;

DECLARE_UNIQUE_INDEX_PKEY(pg_class_oid_index, 2662, ClassOidIndexId, on pg_class using btree(oid oid_ops));
DECLARE_UNIQUE_INDEX(pg_class_relname_nsp_index, 2663, ClassNameNspIndexId, on pg_class using btree(relname name_ops, relnamespace oid_ops));
DECLARE_INDEX(pg_class_tblspc_relfilenode_index, 3455, ClassTblspcRelfilenodeIndexId, on pg_class using btree(reltablespace oid_ops, relfilenode oid_ops));

#ifdef EXPOSE_TO_CLIENT_CODE

#define		  RELKIND_RELATION		  'r'	/* ordinary table */
#define		  RELKIND_INDEX			  'i'	/* secondary index */
#define		  RELKIND_SEQUENCE		  'S'	/* sequence object */
#define		  RELKIND_TOASTVALUE	  't'	/* for out-of-line values */
#define		  RELKIND_VIEW			  'v'	/* view */
#define		  RELKIND_MATVIEW		  'm'	/* materialized view */
#define		  RELKIND_COMPOSITE_TYPE  'c'	/* composite type */
#define		  RELKIND_FOREIGN_TABLE   'f'	/* foreign table */
#define		  RELKIND_PARTITIONED_TABLE 'p' /* partitioned table */
#define		  RELKIND_PARTITIONED_INDEX 'I' /* partitioned index */

#define		  RELPERSISTENCE_PERMANENT	'p' /* regular table */
#define		  RELPERSISTENCE_UNLOGGED	'u' /* unlogged permanent table */
#define		  RELPERSISTENCE_TEMP		't' /* temporary table */

/* default selection for replica identity (primary key or nothing) */
#define		  REPLICA_IDENTITY_DEFAULT	'd'
/* no replica identity is logged for this relation */
#define		  REPLICA_IDENTITY_NOTHING	'n'
/* all columns are logged as replica identity */
#define		  REPLICA_IDENTITY_FULL		'f'
/*
 * an explicitly chosen candidate key's columns are used as replica identity.
 * Note this will still be set if the index has been dropped; in that case it
 * has the same meaning as 'n'.
 */
#define		  REPLICA_IDENTITY_INDEX	'i'

/*
 * Relation kinds that have physical storage. These relations normally have
 * relfilenode set to non-zero, but it can also be zero if the relation is
 * mapped.
 */
#define RELKIND_HAS_STORAGE(relkind) \
	((relkind) == RELKIND_RELATION || \
	 (relkind) == RELKIND_INDEX || \
	 (relkind) == RELKIND_SEQUENCE || \
	 (relkind) == RELKIND_TOASTVALUE || \
	 (relkind) == RELKIND_MATVIEW)

#define RELKIND_HAS_PARTITIONS(relkind) \
	((relkind) == RELKIND_PARTITIONED_TABLE || \
	 (relkind) == RELKIND_PARTITIONED_INDEX)

/*
 * Relation kinds that support tablespaces: All relation kinds with storage
 * support tablespaces, except that we don't support moving sequences around
 * into different tablespaces.  Partitioned tables and indexes don't have
 * physical storage, but they have a tablespace settings so that their
 * children can inherit it.
 */
#define RELKIND_HAS_TABLESPACE(relkind) \
	((RELKIND_HAS_STORAGE(relkind) || RELKIND_HAS_PARTITIONS(relkind)) \
	 && (relkind) != RELKIND_SEQUENCE)

/*
 * Relation kinds with a table access method (rd_tableam).  Although sequences
 * use the heap table AM, they are enough of a special case in most uses that
 * they are not included here.
 */
#define RELKIND_HAS_TABLE_AM(relkind) \
	((relkind) == RELKIND_RELATION || \
	 (relkind) == RELKIND_TOASTVALUE || \
	 (relkind) == RELKIND_MATVIEW)

extern int	errdetail_relkind_not_supported(char relkind);

#endif							/* EXPOSE_TO_CLIENT_CODE */

#endif							/* PG_CLASS_H */
