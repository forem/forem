/*-------------------------------------------------------------------------
 *
 * partcache.h
 *
 * Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * src/include/utils/partcache.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PARTCACHE_H
#define PARTCACHE_H

#include "access/attnum.h"
#include "fmgr.h"
#include "nodes/pg_list.h"
#include "nodes/primnodes.h"
#include "partitioning/partdefs.h"
#include "utils/relcache.h"

/*
 * Information about the partition key of a relation
 */
typedef struct PartitionKeyData
{
	char		strategy;		/* partitioning strategy */
	int16		partnatts;		/* number of columns in the partition key */
	AttrNumber *partattrs;		/* attribute numbers of columns in the
								 * partition key or 0 if it's an expr */
	List	   *partexprs;		/* list of expressions in the partitioning
								 * key, one for each zero-valued partattrs */

	Oid		   *partopfamily;	/* OIDs of operator families */
	Oid		   *partopcintype;	/* OIDs of opclass declared input data types */
	FmgrInfo   *partsupfunc;	/* lookup info for support funcs */

	/* Partitioning collation per attribute */
	Oid		   *partcollation;

	/* Type information per attribute */
	Oid		   *parttypid;
	int32	   *parttypmod;
	int16	   *parttyplen;
	bool	   *parttypbyval;
	char	   *parttypalign;
	Oid		   *parttypcoll;
}			PartitionKeyData;


extern PartitionKey RelationGetPartitionKey(Relation rel);
extern List *RelationGetPartitionQual(Relation rel);
extern Expr *get_partition_qual_relid(Oid relid);

/*
 * PartitionKey inquiry functions
 */
static inline int
get_partition_strategy(PartitionKey key)
{
	return key->strategy;
}

static inline int
get_partition_natts(PartitionKey key)
{
	return key->partnatts;
}

static inline List *
get_partition_exprs(PartitionKey key)
{
	return key->partexprs;
}

/*
 * PartitionKey inquiry functions - one column
 */
static inline int16
get_partition_col_attnum(PartitionKey key, int col)
{
	return key->partattrs[col];
}

static inline Oid
get_partition_col_typid(PartitionKey key, int col)
{
	return key->parttypid[col];
}

static inline int32
get_partition_col_typmod(PartitionKey key, int col)
{
	return key->parttypmod[col];
}

static inline Oid
get_partition_col_collation(PartitionKey key, int col)
{
	return key->partcollation[col];
}

#endif							/* PARTCACHE_H */
