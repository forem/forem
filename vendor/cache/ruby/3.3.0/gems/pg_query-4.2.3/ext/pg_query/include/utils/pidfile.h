/*-------------------------------------------------------------------------
 *
 * pidfile.h
 *	  Declarations describing the data directory lock file (postmaster.pid)
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/pidfile.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef UTILS_PIDFILE_H
#define UTILS_PIDFILE_H

/*
 * As of Postgres 10, the contents of the data-directory lock file are:
 *
 * line #
 *		1	postmaster PID (or negative of a standalone backend's PID)
 *		2	data directory path
 *		3	postmaster start timestamp (time_t representation)
 *		4	port number
 *		5	first Unix socket directory path (empty if none)
 *		6	first listen_address (IP address or "*"; empty if no TCP port)
 *		7	shared memory key (empty on Windows)
 *		8	postmaster status (see values below)
 *
 * Lines 6 and up are added via AddToDataDirLockFile() after initial file
 * creation; also, line 5 is initially empty and is changed after the first
 * Unix socket is opened.  Onlookers should not assume that lines 4 and up
 * are filled in any particular order.
 *
 * Socket lock file(s), if used, have the same contents as lines 1-5, with
 * line 5 being their own directory.
 */
#define LOCK_FILE_LINE_PID			1
#define LOCK_FILE_LINE_DATA_DIR		2
#define LOCK_FILE_LINE_START_TIME	3
#define LOCK_FILE_LINE_PORT			4
#define LOCK_FILE_LINE_SOCKET_DIR	5
#define LOCK_FILE_LINE_LISTEN_ADDR	6
#define LOCK_FILE_LINE_SHMEM_KEY	7
#define LOCK_FILE_LINE_PM_STATUS	8

/*
 * The PM_STATUS line may contain one of these values.  All these strings
 * must be the same length, per comments for AddToDataDirLockFile().
 * We pad with spaces as needed to make that true.
 */
#define PM_STATUS_STARTING		"starting"	/* still starting up */
#define PM_STATUS_STOPPING		"stopping"	/* in shutdown sequence */
#define PM_STATUS_READY			"ready   "	/* ready for connections */
#define PM_STATUS_STANDBY		"standby "	/* up, won't accept connections */

#endif							/* UTILS_PIDFILE_H */
