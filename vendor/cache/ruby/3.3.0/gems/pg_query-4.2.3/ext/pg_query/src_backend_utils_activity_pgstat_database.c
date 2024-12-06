/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pgStatSessionEndCause
 *--------------------------------------------------------------------
 */

/* -------------------------------------------------------------------------
 *
 * pgstat_database.c
 *	  Implementation of database statistics.
 *
 * This file contains the implementation of database statistics. It is kept
 * separate from pgstat.c to enforce the line between the statistics access /
 * storage implementation and the details about individual types of
 * statistics.
 *
 * Copyright (c) 2001-2022, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/backend/utils/activity/pgstat_database.c
 * -------------------------------------------------------------------------
 */

#include "postgres.h"

#include "utils/pgstat_internal.h"
#include "utils/timestamp.h"
#include "storage/procsignal.h"


static bool pgstat_should_report_connstat(void);






__thread SessionEndType pgStatSessionEndCause = DISCONNECT_NORMAL;








/*
 * Remove entry for the database being dropped.
 */


/*
 * Called from autovacuum.c to report startup of an autovacuum process.
 * We are called before InitPostgres is done, so can't rely on MyDatabaseId;
 * the db OID must be passed in, instead.
 */


/*
 * Report a Hot Standby recovery conflict.
 */


/*
 * Report a detected deadlock.
 */


/*
 * Report one or more checksum failures.
 */


/*
 * Report one checksum failure in the current database.
 */


/*
 * Report creation of temporary file.
 */


/*
 * Notify stats system of a new connection.
 */


/*
 * Notify the stats system of a disconnect.
 */


/*
 * Support function for the SQL-callable pgstat* functions. Returns
 * the collected statistics for one database or NULL. NULL doesn't mean
 * that the database doesn't exist, just that there are no statistics, so the
 * caller is better off to report ZERO instead.
 */




/*
 * Subroutine for pgstat_report_stat(): Handle xact commit/rollback and I/O
 * timings.
 */


/*
 * We report session statistics only for normal backend processes.  Parallel
 * workers run in parallel, so they don't contribute to session times, even
 * though they use CPU time. Walsender processes could be considered here,
 * but they have different session characteristics from normal backends (for
 * example, they are always "active"), so they would skew session statistics.
 */


/*
 * Find or create a local PgStat_StatDBEntry entry for dboid.
 */


/*
 * Reset the database's reset timestamp, without resetting the contents of the
 * database stats.
 */


/*
 * Flush out pending stats for the entry
 *
 * If nowait is true, this function returns false if lock could not
 * immediately acquired, otherwise true is returned.
 */
#define PGSTAT_ACCUM_DBCOUNT(item)		\
	(sharedent)->stats.item += (pendingent)->item
#undef PGSTAT_ACCUM_DBCOUNT


