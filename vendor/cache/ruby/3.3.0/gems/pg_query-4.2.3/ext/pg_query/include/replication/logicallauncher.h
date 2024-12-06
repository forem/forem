/*-------------------------------------------------------------------------
 *
 * logicallauncher.h
 *	  Exports for logical replication launcher.
 *
 * Portions Copyright (c) 2016-2022, PostgreSQL Global Development Group
 *
 * src/include/replication/logicallauncher.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef LOGICALLAUNCHER_H
#define LOGICALLAUNCHER_H

extern PGDLLIMPORT int max_logical_replication_workers;
extern PGDLLIMPORT int max_sync_workers_per_subscription;

extern void ApplyLauncherRegister(void);
extern void ApplyLauncherMain(Datum main_arg);

extern Size ApplyLauncherShmemSize(void);
extern void ApplyLauncherShmemInit(void);

extern void ApplyLauncherWakeupAtCommit(void);
extern void AtEOXact_ApplyLauncher(bool isCommit);

extern bool IsLogicalLauncher(void);

#endif							/* LOGICALLAUNCHER_H */
