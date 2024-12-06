/*-------------------------------------------------------------------------
 *
 * standbydefs.h
 *	   Frontend exposed definitions for hot standby mode.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/standbydefs.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef STANDBYDEFS_H
#define STANDBYDEFS_H

#include "access/xlogreader.h"
#include "lib/stringinfo.h"
#include "storage/lockdefs.h"
#include "storage/sinval.h"

/* Recovery handlers for the Standby Rmgr (RM_STANDBY_ID) */
extern void standby_redo(XLogReaderState *record);
extern void standby_desc(StringInfo buf, XLogReaderState *record);
extern const char *standby_identify(uint8 info);
extern void standby_desc_invalidations(StringInfo buf,
									   int nmsgs, SharedInvalidationMessage *msgs,
									   Oid dbId, Oid tsId,
									   bool relcacheInitFileInval);

/*
 * XLOG message types
 */
#define XLOG_STANDBY_LOCK			0x00
#define XLOG_RUNNING_XACTS			0x10
#define XLOG_INVALIDATIONS			0x20

typedef struct xl_standby_locks
{
	int			nlocks;			/* number of entries in locks array */
	xl_standby_lock locks[FLEXIBLE_ARRAY_MEMBER];
} xl_standby_locks;

/*
 * When we write running xact data to WAL, we use this structure.
 */
typedef struct xl_running_xacts
{
	int			xcnt;			/* # of xact ids in xids[] */
	int			subxcnt;		/* # of subxact ids in xids[] */
	bool		subxid_overflow;	/* snapshot overflowed, subxids missing */
	TransactionId nextXid;		/* xid from ShmemVariableCache->nextXid */
	TransactionId oldestRunningXid; /* *not* oldestXmin */
	TransactionId latestCompletedXid;	/* so we can set xmax */

	TransactionId xids[FLEXIBLE_ARRAY_MEMBER];
} xl_running_xacts;

/*
 * Invalidations for standby, currently only when transactions without an
 * assigned xid commit.
 */
typedef struct xl_invalidations
{
	Oid			dbId;			/* MyDatabaseId */
	Oid			tsId;			/* MyDatabaseTableSpace */
	bool		relcacheInitFileInval;	/* invalidate relcache init files */
	int			nmsgs;			/* number of shared inval msgs */
	SharedInvalidationMessage msgs[FLEXIBLE_ARRAY_MEMBER];
} xl_invalidations;

#define MinSizeOfInvalidations offsetof(xl_invalidations, msgs)

#endif							/* STANDBYDEFS_H */
