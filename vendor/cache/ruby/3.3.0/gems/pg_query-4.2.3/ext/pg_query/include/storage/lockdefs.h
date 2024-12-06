/*-------------------------------------------------------------------------
 *
 * lockdefs.h
 *	   Frontend exposed parts of postgres' low level lock mechanism
 *
 * The split between lockdefs.h and lock.h is not very principled. This file
 * contains definition that have to (indirectly) be available when included by
 * FRONTEND code.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/lockdefs.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef LOCKDEFS_H_
#define LOCKDEFS_H_

/*
 * LOCKMODE is an integer (1..N) indicating a lock type.  LOCKMASK is a bit
 * mask indicating a set of held or requested lock types (the bit 1<<mode
 * corresponds to a particular lock mode).
 */
typedef int LOCKMASK;
typedef int LOCKMODE;

/*
 * These are the valid values of type LOCKMODE for all the standard lock
 * methods (both DEFAULT and USER).
 */

/* NoLock is not a lock mode, but a flag value meaning "don't get a lock" */
#define NoLock					0

#define AccessShareLock			1	/* SELECT */
#define RowShareLock			2	/* SELECT FOR UPDATE/FOR SHARE */
#define RowExclusiveLock		3	/* INSERT, UPDATE, DELETE */
#define ShareUpdateExclusiveLock 4	/* VACUUM (non-FULL),ANALYZE, CREATE INDEX
									 * CONCURRENTLY */
#define ShareLock				5	/* CREATE INDEX (WITHOUT CONCURRENTLY) */
#define ShareRowExclusiveLock	6	/* like EXCLUSIVE MODE, but allows ROW
									 * SHARE */
#define ExclusiveLock			7	/* blocks ROW SHARE/SELECT...FOR UPDATE */
#define AccessExclusiveLock		8	/* ALTER TABLE, DROP TABLE, VACUUM FULL,
									 * and unqualified LOCK TABLE */

#define MaxLockMode				8	/* highest standard lock mode */


/* WAL representation of an AccessExclusiveLock on a table */
typedef struct xl_standby_lock
{
	TransactionId xid;			/* xid of holder of AccessExclusiveLock */
	Oid			dbOid;			/* DB containing table */
	Oid			relOid;			/* OID of table */
} xl_standby_lock;

#endif							/* LOCKDEFS_H_ */
