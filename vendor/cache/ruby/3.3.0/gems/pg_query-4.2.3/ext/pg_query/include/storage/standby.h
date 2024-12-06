/*-------------------------------------------------------------------------
 *
 * standby.h
 *	  Definitions for hot standby mode.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/standby.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef STANDBY_H
#define STANDBY_H

#include "datatype/timestamp.h"
#include "storage/lock.h"
#include "storage/procsignal.h"
#include "storage/relfilenode.h"
#include "storage/standbydefs.h"

/* User-settable GUC parameters */
extern PGDLLIMPORT int vacuum_defer_cleanup_age;
extern PGDLLIMPORT int max_standby_archive_delay;
extern PGDLLIMPORT int max_standby_streaming_delay;
extern PGDLLIMPORT bool log_recovery_conflict_waits;

extern void InitRecoveryTransactionEnvironment(void);
extern void ShutdownRecoveryTransactionEnvironment(void);

extern void ResolveRecoveryConflictWithSnapshot(TransactionId latestRemovedXid,
												RelFileNode node);
extern void ResolveRecoveryConflictWithSnapshotFullXid(FullTransactionId latestRemovedFullXid,
													   RelFileNode node);
extern void ResolveRecoveryConflictWithTablespace(Oid tsid);
extern void ResolveRecoveryConflictWithDatabase(Oid dbid);

extern void ResolveRecoveryConflictWithLock(LOCKTAG locktag, bool logging_conflict);
extern void ResolveRecoveryConflictWithBufferPin(void);
extern void CheckRecoveryConflictDeadlock(void);
extern void StandbyDeadLockHandler(void);
extern void StandbyTimeoutHandler(void);
extern void StandbyLockTimeoutHandler(void);
extern void LogRecoveryConflict(ProcSignalReason reason, TimestampTz wait_start,
								TimestampTz cur_ts, VirtualTransactionId *wait_list,
								bool still_waiting);

/*
 * Standby Rmgr (RM_STANDBY_ID)
 *
 * Standby recovery manager exists to perform actions that are required
 * to make hot standby work. That includes logging AccessExclusiveLocks taken
 * by transactions and running-xacts snapshots.
 */
extern void StandbyAcquireAccessExclusiveLock(TransactionId xid, Oid dbOid, Oid relOid);
extern void StandbyReleaseLockTree(TransactionId xid,
								   int nsubxids, TransactionId *subxids);
extern void StandbyReleaseAllLocks(void);
extern void StandbyReleaseOldLocks(TransactionId oldxid);

#define MinSizeOfXactRunningXacts offsetof(xl_running_xacts, xids)


/*
 * Declarations for GetRunningTransactionData(). Similar to Snapshots, but
 * not quite. This has nothing at all to do with visibility on this server,
 * so this is completely separate from snapmgr.c and snapmgr.h.
 * This data is important for creating the initial snapshot state on a
 * standby server. We need lots more information than a normal snapshot,
 * hence we use a specific data structure for our needs. This data
 * is written to WAL as a separate record immediately after each
 * checkpoint. That means that wherever we start a standby from we will
 * almost immediately see the data we need to begin executing queries.
 */

typedef struct RunningTransactionsData
{
	int			xcnt;			/* # of xact ids in xids[] */
	int			subxcnt;		/* # of subxact ids in xids[] */
	bool		subxid_overflow;	/* snapshot overflowed, subxids missing */
	TransactionId nextXid;		/* xid from ShmemVariableCache->nextXid */
	TransactionId oldestRunningXid; /* *not* oldestXmin */
	TransactionId latestCompletedXid;	/* so we can set xmax */

	TransactionId *xids;		/* array of (sub)xids still running */
} RunningTransactionsData;

typedef RunningTransactionsData *RunningTransactions;

extern void LogAccessExclusiveLock(Oid dbOid, Oid relOid);
extern void LogAccessExclusiveLockPrepare(void);

extern XLogRecPtr LogStandbySnapshot(void);
extern void LogStandbyInvalidations(int nmsgs, SharedInvalidationMessage *msgs,
									bool relcacheInitFileInval);

#endif							/* STANDBY_H */
