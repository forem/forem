/*-------------------------------------------------------------------------
 *
 * async.h
 *	  Asynchronous notification: NOTIFY, LISTEN, UNLISTEN
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/async.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef ASYNC_H
#define ASYNC_H

#include <signal.h>

/*
 * The number of SLRU page buffers we use for the notification queue.
 */
#define NUM_NOTIFY_BUFFERS	8

extern PGDLLIMPORT bool Trace_notify;
extern PGDLLIMPORT volatile sig_atomic_t notifyInterruptPending;

extern Size AsyncShmemSize(void);
extern void AsyncShmemInit(void);

extern void NotifyMyFrontEnd(const char *channel,
							 const char *payload,
							 int32 srcPid);

/* notify-related SQL statements */
extern void Async_Notify(const char *channel, const char *payload);
extern void Async_Listen(const char *channel);
extern void Async_Unlisten(const char *channel);
extern void Async_UnlistenAll(void);

/* perform (or cancel) outbound notify processing at transaction commit */
extern void PreCommit_Notify(void);
extern void AtCommit_Notify(void);
extern void AtAbort_Notify(void);
extern void AtSubCommit_Notify(void);
extern void AtSubAbort_Notify(void);
extern void AtPrepare_Notify(void);

/* signal handler for inbound notifies (PROCSIG_NOTIFY_INTERRUPT) */
extern void HandleNotifyInterrupt(void);

/* process interrupts */
extern void ProcessNotifyInterrupt(bool flush);

#endif							/* ASYNC_H */
