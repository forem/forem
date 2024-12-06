/*-------------------------------------------------------------------------
 *
 * startup.h
 *	  Exports from postmaster/startup.c.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * src/include/postmaster/startup.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _STARTUP_H
#define _STARTUP_H

/*
 * Log the startup progress message if a timer has expired.
 */
#define ereport_startup_progress(msg, ...) \
	do { \
		long    secs; \
		int     usecs; \
		if (has_startup_progress_timeout_expired(&secs, &usecs)) \
			ereport(LOG, errmsg(msg, secs, (usecs / 10000),  __VA_ARGS__ )); \
	} while(0)

extern PGDLLIMPORT int log_startup_progress_interval;

extern void HandleStartupProcInterrupts(void);
extern void StartupProcessMain(void) pg_attribute_noreturn();
extern void PreRestoreCommand(void);
extern void PostRestoreCommand(void);
extern bool IsPromoteSignaled(void);
extern void ResetPromoteSignaled(void);

extern void begin_startup_progress_phase(void);
extern void startup_progress_timeout_handler(void);
extern bool has_startup_progress_timeout_expired(long *secs, int *usecs);

#endif							/* _STARTUP_H */
