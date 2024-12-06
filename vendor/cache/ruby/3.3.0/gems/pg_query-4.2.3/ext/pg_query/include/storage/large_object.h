/*-------------------------------------------------------------------------
 *
 * large_object.h
 *	  Declarations for PostgreSQL large objects.  POSTGRES 4.2 supported
 *	  zillions of large objects (internal, external, jaquith, inversion).
 *	  Now we only support inversion.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/large_object.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef LARGE_OBJECT_H
#define LARGE_OBJECT_H

#include "utils/snapshot.h"


/*----------
 * Data about a currently-open large object.
 *
 * id is the logical OID of the large object
 * snapshot is the snapshot to use for read/write operations
 * subid is the subtransaction that opened the desc (or currently owns it)
 * offset is the current seek offset within the LO
 * flags contains some flag bits
 *
 * NOTE: as of v11, permission checks are made when the large object is
 * opened; therefore IFS_RDLOCK/IFS_WRLOCK indicate that read or write mode
 * has been requested *and* the corresponding permission has been checked.
 *
 * NOTE: before 7.1, we also had to store references to the separate table
 * and index of a specific large object.  Now they all live in pg_largeobject
 * and are accessed via a common relation descriptor.
 *----------
 */
typedef struct LargeObjectDesc
{
	Oid			id;				/* LO's identifier */
	Snapshot	snapshot;		/* snapshot to use */
	SubTransactionId subid;		/* owning subtransaction ID */
	uint64		offset;			/* current seek pointer */
	int			flags;			/* see flag bits below */

/* bits in flags: */
#define IFS_RDLOCK		(1 << 0)	/* LO was opened for reading */
#define IFS_WRLOCK		(1 << 1)	/* LO was opened for writing */

} LargeObjectDesc;


/*
 * Each "page" (tuple) of a large object can hold this much data
 *
 * We could set this as high as BLCKSZ less some overhead, but it seems
 * better to make it a smaller value, so that not as much space is used
 * up when a page-tuple is updated.  Note that the value is deliberately
 * chosen large enough to trigger the tuple toaster, so that we will
 * attempt to compress page tuples in-line.  (But they won't be moved off
 * unless the user creates a toast-table for pg_largeobject...)
 *
 * Also, it seems to be a smart move to make the page size be a power of 2,
 * since clients will often be written to send data in power-of-2 blocks.
 * This avoids unnecessary tuple updates caused by partial-page writes.
 *
 * NB: Changing LOBLKSIZE requires an initdb.
 */
#define LOBLKSIZE		(BLCKSZ / 4)

/*
 * Maximum length in bytes for a large object.  To make this larger, we'd
 * have to widen pg_largeobject.pageno as well as various internal variables.
 */
#define MAX_LARGE_OBJECT_SIZE	((int64) INT_MAX * LOBLKSIZE)


/*
 * GUC: backwards-compatibility flag to suppress LO permission checks
 */
extern PGDLLIMPORT bool lo_compat_privileges;

/*
 * Function definitions...
 */

/* inversion stuff in inv_api.c */
extern void close_lo_relation(bool isCommit);
extern Oid	inv_create(Oid lobjId);
extern LargeObjectDesc *inv_open(Oid lobjId, int flags, MemoryContext mcxt);
extern void inv_close(LargeObjectDesc *obj_desc);
extern int	inv_drop(Oid lobjId);
extern int64 inv_seek(LargeObjectDesc *obj_desc, int64 offset, int whence);
extern int64 inv_tell(LargeObjectDesc *obj_desc);
extern int	inv_read(LargeObjectDesc *obj_desc, char *buf, int nbytes);
extern int	inv_write(LargeObjectDesc *obj_desc, const char *buf, int nbytes);
extern void inv_truncate(LargeObjectDesc *obj_desc, int64 len);

#endif							/* LARGE_OBJECT_H */
