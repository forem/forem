/*-------------------------------------------------------------------------
 *
 * xlogprefetcher.h
 *		Declarations for the recovery prefetching module.
 *
 * Portions Copyright (c) 2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *		src/include/access/xlogprefetcher.h
 *-------------------------------------------------------------------------
 */
#ifndef XLOGPREFETCHER_H
#define XLOGPREFETCHER_H

#include "access/xlogdefs.h"
#include "access/xlogreader.h"
#include "access/xlogrecord.h"

/* GUCs */
extern PGDLLIMPORT int recovery_prefetch;

/* Possible values for recovery_prefetch */
typedef enum
{
	RECOVERY_PREFETCH_OFF,
	RECOVERY_PREFETCH_ON,
	RECOVERY_PREFETCH_TRY
}			RecoveryPrefetchValue;

struct XLogPrefetcher;
typedef struct XLogPrefetcher XLogPrefetcher;


extern void XLogPrefetchReconfigure(void);

extern size_t XLogPrefetchShmemSize(void);
extern void XLogPrefetchShmemInit(void);

extern void XLogPrefetchResetStats(void);

extern XLogPrefetcher *XLogPrefetcherAllocate(XLogReaderState *reader);
extern void XLogPrefetcherFree(XLogPrefetcher *prefetcher);

extern XLogReaderState *XLogPrefetcherGetReader(XLogPrefetcher *prefetcher);

extern void XLogPrefetcherBeginRead(XLogPrefetcher *prefetcher,
									XLogRecPtr recPtr);

extern XLogRecord *XLogPrefetcherReadRecord(XLogPrefetcher *prefetcher,
											char **errmsg);

extern void XLogPrefetcherComputeStats(XLogPrefetcher *prefetcher);

#endif
