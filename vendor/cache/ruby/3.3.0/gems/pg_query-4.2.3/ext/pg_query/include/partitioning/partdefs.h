/*-------------------------------------------------------------------------
 *
 * partdefs.h
 *		Base definitions for partitioned table handling
 *
 * Copyright (c) 2007-2022, PostgreSQL Global Development Group
 *
 * src/include/partitioning/partdefs.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PARTDEFS_H
#define PARTDEFS_H


typedef struct PartitionBoundInfoData *PartitionBoundInfo;

typedef struct PartitionKeyData *PartitionKey;

typedef struct PartitionBoundSpec PartitionBoundSpec;

typedef struct PartitionDescData *PartitionDesc;

typedef struct PartitionDirectoryData *PartitionDirectory;

#endif							/* PARTDEFS_H */
