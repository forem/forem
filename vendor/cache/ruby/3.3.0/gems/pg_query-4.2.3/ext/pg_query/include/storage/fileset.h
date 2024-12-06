/*-------------------------------------------------------------------------
 *
 * fileset.h
 *	  Management of named temporary files.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/fileset.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef FILESET_H
#define FILESET_H

#include "storage/fd.h"

/*
 * A set of temporary files.
 */
typedef struct FileSet
{
	pid_t		creator_pid;	/* PID of the creating process */
	uint32		number;			/* per-PID identifier */
	int			ntablespaces;	/* number of tablespaces to use */
	Oid			tablespaces[8]; /* OIDs of tablespaces to use. Assumes that
								 * it's rare that there more than temp
								 * tablespaces. */
} FileSet;

extern void FileSetInit(FileSet *fileset);
extern File FileSetCreate(FileSet *fileset, const char *name);
extern File FileSetOpen(FileSet *fileset, const char *name,
						int mode);
extern bool FileSetDelete(FileSet *fileset, const char *name,
						  bool error_on_failure);
extern void FileSetDeleteAll(FileSet *fileset);

#endif
