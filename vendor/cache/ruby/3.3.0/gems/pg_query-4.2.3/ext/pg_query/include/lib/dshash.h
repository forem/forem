/*-------------------------------------------------------------------------
 *
 * dshash.h
 *	  Concurrent hash tables backed by dynamic shared memory areas.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/include/lib/dshash.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef DSHASH_H
#define DSHASH_H

#include "utils/dsa.h"

/* The opaque type representing a hash table. */
struct dshash_table;
typedef struct dshash_table dshash_table;

/* A handle for a dshash_table which can be shared with other processes. */
typedef dsa_pointer dshash_table_handle;

/* The type for hash values. */
typedef uint32 dshash_hash;

/* A function type for comparing keys. */
typedef int (*dshash_compare_function) (const void *a, const void *b,
										size_t size, void *arg);

/* A function type for computing hash values for keys. */
typedef dshash_hash (*dshash_hash_function) (const void *v, size_t size,
											 void *arg);

/*
 * The set of parameters needed to create or attach to a hash table.  The
 * members tranche_id and tranche_name do not need to be initialized when
 * attaching to an existing hash table.
 *
 * Compare and hash functions must be supplied even when attaching, because we
 * can't safely share function pointers between backends in general.  Either
 * the arg variants or the non-arg variants should be supplied; the other
 * function pointers should be NULL.  If the arg variants are supplied then the
 * user data pointer supplied to the create and attach functions will be
 * passed to the hash and compare functions.
 */
typedef struct dshash_parameters
{
	size_t		key_size;		/* Size of the key (initial bytes of entry) */
	size_t		entry_size;		/* Total size of entry */
	dshash_compare_function compare_function;	/* Compare function */
	dshash_hash_function hash_function; /* Hash function */
	int			tranche_id;		/* The tranche ID to use for locks */
} dshash_parameters;

/* Forward declaration of private types for use only by dshash.c. */
struct dshash_table_item;
typedef struct dshash_table_item dshash_table_item;

/*
 * Sequential scan state. The detail is exposed to let users know the storage
 * size but it should be considered as an opaque type by callers.
 */
typedef struct dshash_seq_status
{
	dshash_table *hash_table;	/* dshash table working on */
	int			curbucket;		/* bucket number we are at */
	int			nbuckets;		/* total number of buckets in the dshash */
	dshash_table_item *curitem; /* item we are currently at */
	dsa_pointer pnextitem;		/* dsa-pointer to the next item */
	int			curpartition;	/* partition number we are at */
	bool		exclusive;		/* locking mode */
} dshash_seq_status;

/* Creating, sharing and destroying from hash tables. */
extern dshash_table *dshash_create(dsa_area *area,
								   const dshash_parameters *params,
								   void *arg);
extern dshash_table *dshash_attach(dsa_area *area,
								   const dshash_parameters *params,
								   dshash_table_handle handle,
								   void *arg);
extern void dshash_detach(dshash_table *hash_table);
extern dshash_table_handle dshash_get_hash_table_handle(dshash_table *hash_table);
extern void dshash_destroy(dshash_table *hash_table);

/* Finding, creating, deleting entries. */
extern void *dshash_find(dshash_table *hash_table,
						 const void *key, bool exclusive);
extern void *dshash_find_or_insert(dshash_table *hash_table,
								   const void *key, bool *found);
extern bool dshash_delete_key(dshash_table *hash_table, const void *key);
extern void dshash_delete_entry(dshash_table *hash_table, void *entry);
extern void dshash_release_lock(dshash_table *hash_table, void *entry);

/* seq scan support */
extern void dshash_seq_init(dshash_seq_status *status, dshash_table *hash_table,
							bool exclusive);
extern void *dshash_seq_next(dshash_seq_status *status);
extern void dshash_seq_term(dshash_seq_status *status);
extern void dshash_delete_current(dshash_seq_status *status);

/* Convenience hash and compare functions wrapping memcmp and tag_hash. */
extern int	dshash_memcmp(const void *a, const void *b, size_t size, void *arg);
extern dshash_hash dshash_memhash(const void *v, size_t size, void *arg);

/* Debugging support. */
extern void dshash_dump(dshash_table *hash_table);

#endif							/* DSHASH_H */
