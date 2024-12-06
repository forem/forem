/*-------------------------------------------------------------------------
 *
 * pgarch.h
 *	  Exports from postmaster/pgarch.c.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/postmaster/pgarch.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _PGARCH_H
#define _PGARCH_H

/* ----------
 * Archiver control info.
 *
 * We expect that archivable files within pg_wal will have names between
 * MIN_XFN_CHARS and MAX_XFN_CHARS in length, consisting only of characters
 * appearing in VALID_XFN_CHARS.  The status files in archive_status have
 * corresponding names with ".ready" or ".done" appended.
 * ----------
 */
#define MIN_XFN_CHARS	16
#define MAX_XFN_CHARS	40
#define VALID_XFN_CHARS "0123456789ABCDEF.history.backup.partial"

extern Size PgArchShmemSize(void);
extern void PgArchShmemInit(void);
extern bool PgArchCanRestart(void);
extern void PgArchiverMain(void) pg_attribute_noreturn();
extern void PgArchWakeup(void);
extern void PgArchForceDirScan(void);

/*
 * The value of the archive_library GUC.
 */
extern PGDLLIMPORT char *XLogArchiveLibrary;

/*
 * Archive module callbacks
 *
 * These callback functions should be defined by archive libraries and returned
 * via _PG_archive_module_init().  ArchiveFileCB is the only required callback.
 * For more information about the purpose of each callback, refer to the
 * archive modules documentation.
 */
typedef bool (*ArchiveCheckConfiguredCB) (void);
typedef bool (*ArchiveFileCB) (const char *file, const char *path);
typedef void (*ArchiveShutdownCB) (void);

typedef struct ArchiveModuleCallbacks
{
	ArchiveCheckConfiguredCB check_configured_cb;
	ArchiveFileCB archive_file_cb;
	ArchiveShutdownCB shutdown_cb;
} ArchiveModuleCallbacks;

/*
 * Type of the shared library symbol _PG_archive_module_init that is looked
 * up when loading an archive library.
 */
typedef void (*ArchiveModuleInit) (ArchiveModuleCallbacks *cb);

/*
 * Since the logic for archiving via a shell command is in the core server
 * and does not need to be loaded via a shared library, it has a special
 * initialization function.
 */
extern void shell_archive_init(ArchiveModuleCallbacks *cb);

#endif							/* _PGARCH_H */
