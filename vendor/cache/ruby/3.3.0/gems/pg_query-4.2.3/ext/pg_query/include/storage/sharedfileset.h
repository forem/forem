/*-------------------------------------------------------------------------
 *
 * sharedfileset.h
 *	  Shared temporary file management.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/sharedfileset.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef SHAREDFILESET_H
#define SHAREDFILESET_H

#include "storage/dsm.h"
#include "storage/fd.h"
#include "storage/fileset.h"
#include "storage/spin.h"

/*
 * A set of temporary files that can be shared by multiple backends.
 */
typedef struct SharedFileSet
{
	FileSet		fs;
	slock_t		mutex;			/* mutex protecting the reference count */
	int			refcnt;			/* number of attached backends */
} SharedFileSet;

extern void SharedFileSetInit(SharedFileSet *fileset, dsm_segment *seg);
extern void SharedFileSetAttach(SharedFileSet *fileset, dsm_segment *seg);
extern void SharedFileSetDeleteAll(SharedFileSet *fileset);

#endif
