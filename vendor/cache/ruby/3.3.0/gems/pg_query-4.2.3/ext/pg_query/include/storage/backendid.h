/*-------------------------------------------------------------------------
 *
 * backendid.h
 *	  POSTGRES backend id communication definitions
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/backendid.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef BACKENDID_H
#define BACKENDID_H

/* ----------------
 *		-cim 8/17/90
 * ----------------
 */
typedef int BackendId;			/* unique currently active backend identifier */

#define InvalidBackendId		(-1)

extern PGDLLIMPORT BackendId MyBackendId;	/* backend id of this backend */

/* backend id of our parallel session leader, or InvalidBackendId if none */
extern PGDLLIMPORT BackendId ParallelLeaderBackendId;

/*
 * The BackendId to use for our session's temp relations is normally our own,
 * but parallel workers should use their leader's ID.
 */
#define BackendIdForTempRelations() \
	(ParallelLeaderBackendId == InvalidBackendId ? MyBackendId : ParallelLeaderBackendId)

#endif							/* BACKENDID_H */
