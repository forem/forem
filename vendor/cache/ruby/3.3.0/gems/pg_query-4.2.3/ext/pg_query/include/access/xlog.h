/*
 * xlog.h
 *
 * PostgreSQL write-ahead log manager
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/access/xlog.h
 */
#ifndef XLOG_H
#define XLOG_H

#include "access/xlogdefs.h"
#include "access/xlogreader.h"
#include "datatype/timestamp.h"
#include "lib/stringinfo.h"
#include "nodes/pg_list.h"


/* Sync methods */
#define SYNC_METHOD_FSYNC		0
#define SYNC_METHOD_FDATASYNC	1
#define SYNC_METHOD_OPEN		2	/* for O_SYNC */
#define SYNC_METHOD_FSYNC_WRITETHROUGH	3
#define SYNC_METHOD_OPEN_DSYNC	4	/* for O_DSYNC */
extern PGDLLIMPORT int sync_method;

extern PGDLLIMPORT XLogRecPtr ProcLastRecPtr;
extern PGDLLIMPORT XLogRecPtr XactLastRecEnd;
extern PGDLLIMPORT XLogRecPtr XactLastCommitEnd;

/* these variables are GUC parameters related to XLOG */
extern PGDLLIMPORT int wal_segment_size;
extern PGDLLIMPORT int min_wal_size_mb;
extern PGDLLIMPORT int max_wal_size_mb;
extern PGDLLIMPORT int wal_keep_size_mb;
extern PGDLLIMPORT int max_slot_wal_keep_size_mb;
extern PGDLLIMPORT int XLOGbuffers;
extern PGDLLIMPORT int XLogArchiveTimeout;
extern PGDLLIMPORT int wal_retrieve_retry_interval;
extern PGDLLIMPORT char *XLogArchiveCommand;
extern PGDLLIMPORT bool EnableHotStandby;
extern PGDLLIMPORT bool fullPageWrites;
extern PGDLLIMPORT bool wal_log_hints;
extern PGDLLIMPORT int wal_compression;
extern PGDLLIMPORT bool wal_init_zero;
extern PGDLLIMPORT bool wal_recycle;
extern PGDLLIMPORT bool *wal_consistency_checking;
extern PGDLLIMPORT char *wal_consistency_checking_string;
extern PGDLLIMPORT bool log_checkpoints;
extern PGDLLIMPORT bool track_wal_io_timing;
extern PGDLLIMPORT int wal_decode_buffer_size;

extern PGDLLIMPORT int CheckPointSegments;

/* Archive modes */
typedef enum ArchiveMode
{
	ARCHIVE_MODE_OFF = 0,		/* disabled */
	ARCHIVE_MODE_ON,			/* enabled while server is running normally */
	ARCHIVE_MODE_ALWAYS			/* enabled always (even during recovery) */
} ArchiveMode;
extern PGDLLIMPORT int XLogArchiveMode;

/* WAL levels */
typedef enum WalLevel
{
	WAL_LEVEL_MINIMAL = 0,
	WAL_LEVEL_REPLICA,
	WAL_LEVEL_LOGICAL
} WalLevel;

/* Compression algorithms for WAL */
typedef enum WalCompression
{
	WAL_COMPRESSION_NONE = 0,
	WAL_COMPRESSION_PGLZ,
	WAL_COMPRESSION_LZ4,
	WAL_COMPRESSION_ZSTD
} WalCompression;

/* Recovery states */
typedef enum RecoveryState
{
	RECOVERY_STATE_CRASH = 0,	/* crash recovery */
	RECOVERY_STATE_ARCHIVE,		/* archive recovery */
	RECOVERY_STATE_DONE			/* currently in production */
} RecoveryState;

extern PGDLLIMPORT int wal_level;

/* Is WAL archiving enabled (always or only while server is running normally)? */
#define XLogArchivingActive() \
	(AssertMacro(XLogArchiveMode == ARCHIVE_MODE_OFF || wal_level >= WAL_LEVEL_REPLICA), XLogArchiveMode > ARCHIVE_MODE_OFF)
/* Is WAL archiving enabled always (even during recovery)? */
#define XLogArchivingAlways() \
	(AssertMacro(XLogArchiveMode == ARCHIVE_MODE_OFF || wal_level >= WAL_LEVEL_REPLICA), XLogArchiveMode == ARCHIVE_MODE_ALWAYS)

/*
 * Is WAL-logging necessary for archival or log-shipping, or can we skip
 * WAL-logging if we fsync() the data before committing instead?
 */
#define XLogIsNeeded() (wal_level >= WAL_LEVEL_REPLICA)

/*
 * Is a full-page image needed for hint bit updates?
 *
 * Normally, we don't WAL-log hint bit updates, but if checksums are enabled,
 * we have to protect them against torn page writes.  When you only set
 * individual bits on a page, it's still consistent no matter what combination
 * of the bits make it to disk, but the checksum wouldn't match.  Also WAL-log
 * them if forced by wal_log_hints=on.
 */
#define XLogHintBitIsNeeded() (DataChecksumsEnabled() || wal_log_hints)

/* Do we need to WAL-log information required only for Hot Standby and logical replication? */
#define XLogStandbyInfoActive() (wal_level >= WAL_LEVEL_REPLICA)

/* Do we need to WAL-log information required only for logical replication? */
#define XLogLogicalInfoActive() (wal_level >= WAL_LEVEL_LOGICAL)

#ifdef WAL_DEBUG
extern PGDLLIMPORT bool XLOG_DEBUG;
#endif

/*
 * OR-able request flag bits for checkpoints.  The "cause" bits are used only
 * for logging purposes.  Note: the flags must be defined so that it's
 * sensible to OR together request flags arising from different requestors.
 */

/* These directly affect the behavior of CreateCheckPoint and subsidiaries */
#define CHECKPOINT_IS_SHUTDOWN	0x0001	/* Checkpoint is for shutdown */
#define CHECKPOINT_END_OF_RECOVERY	0x0002	/* Like shutdown checkpoint, but
											 * issued at end of WAL recovery */
#define CHECKPOINT_IMMEDIATE	0x0004	/* Do it without delays */
#define CHECKPOINT_FORCE		0x0008	/* Force even if no activity */
#define CHECKPOINT_FLUSH_ALL	0x0010	/* Flush all pages, including those
										 * belonging to unlogged tables */
/* These are important to RequestCheckpoint */
#define CHECKPOINT_WAIT			0x0020	/* Wait for completion */
#define CHECKPOINT_REQUESTED	0x0040	/* Checkpoint request has been made */
/* These indicate the cause of a checkpoint request */
#define CHECKPOINT_CAUSE_XLOG	0x0080	/* XLOG consumption */
#define CHECKPOINT_CAUSE_TIME	0x0100	/* Elapsed time */

/*
 * Flag bits for the record being inserted, set using XLogSetRecordFlags().
 */
#define XLOG_INCLUDE_ORIGIN		0x01	/* include the replication origin */
#define XLOG_MARK_UNIMPORTANT	0x02	/* record not important for durability */


/* Checkpoint statistics */
typedef struct CheckpointStatsData
{
	TimestampTz ckpt_start_t;	/* start of checkpoint */
	TimestampTz ckpt_write_t;	/* start of flushing buffers */
	TimestampTz ckpt_sync_t;	/* start of fsyncs */
	TimestampTz ckpt_sync_end_t;	/* end of fsyncs */
	TimestampTz ckpt_end_t;		/* end of checkpoint */

	int			ckpt_bufs_written;	/* # of buffers written */

	int			ckpt_segs_added;	/* # of new xlog segments created */
	int			ckpt_segs_removed;	/* # of xlog segments deleted */
	int			ckpt_segs_recycled; /* # of xlog segments recycled */

	int			ckpt_sync_rels; /* # of relations synced */
	uint64		ckpt_longest_sync;	/* Longest sync for one relation */
	uint64		ckpt_agg_sync_time; /* The sum of all the individual sync
									 * times, which is not necessarily the
									 * same as the total elapsed time for the
									 * entire sync phase. */
} CheckpointStatsData;

extern PGDLLIMPORT CheckpointStatsData CheckpointStats;

/*
 * GetWALAvailability return codes
 */
typedef enum WALAvailability
{
	WALAVAIL_INVALID_LSN,		/* parameter error */
	WALAVAIL_RESERVED,			/* WAL segment is within max_wal_size */
	WALAVAIL_EXTENDED,			/* WAL segment is reserved by a slot or
								 * wal_keep_size */
	WALAVAIL_UNRESERVED,		/* no longer reserved, but not removed yet */
	WALAVAIL_REMOVED			/* WAL segment has been removed */
} WALAvailability;

struct XLogRecData;

extern XLogRecPtr XLogInsertRecord(struct XLogRecData *rdata,
								   XLogRecPtr fpw_lsn,
								   uint8 flags,
								   int num_fpi,
								   bool topxid_included);
extern void XLogFlush(XLogRecPtr RecPtr);
extern bool XLogBackgroundFlush(void);
extern bool XLogNeedsFlush(XLogRecPtr RecPtr);
extern int	XLogFileInit(XLogSegNo segno, TimeLineID tli);
extern int	XLogFileOpen(XLogSegNo segno, TimeLineID tli);

extern void CheckXLogRemoved(XLogSegNo segno, TimeLineID tli);
extern XLogSegNo XLogGetLastRemovedSegno(void);
extern void XLogSetAsyncXactLSN(XLogRecPtr record);
extern void XLogSetReplicationSlotMinimumLSN(XLogRecPtr lsn);

extern void xlog_redo(XLogReaderState *record);
extern void xlog_desc(StringInfo buf, XLogReaderState *record);
extern const char *xlog_identify(uint8 info);

extern void issue_xlog_fsync(int fd, XLogSegNo segno, TimeLineID tli);

extern bool RecoveryInProgress(void);
extern RecoveryState GetRecoveryState(void);
extern bool XLogInsertAllowed(void);
extern XLogRecPtr GetXLogInsertRecPtr(void);
extern XLogRecPtr GetXLogWriteRecPtr(void);

extern uint64 GetSystemIdentifier(void);
extern char *GetMockAuthenticationNonce(void);
extern bool DataChecksumsEnabled(void);
extern XLogRecPtr GetFakeLSNForUnloggedRel(void);
extern Size XLOGShmemSize(void);
extern void XLOGShmemInit(void);
extern void BootStrapXLOG(void);
extern void LocalProcessControlFile(bool reset);
extern void StartupXLOG(void);
extern void ShutdownXLOG(int code, Datum arg);
extern void CreateCheckPoint(int flags);
extern bool CreateRestartPoint(int flags);
extern WALAvailability GetWALAvailability(XLogRecPtr targetLSN);
extern void XLogPutNextOid(Oid nextOid);
extern XLogRecPtr XLogRestorePoint(const char *rpName);
extern void UpdateFullPageWrites(void);
extern void GetFullPageWriteInfo(XLogRecPtr *RedoRecPtr_p, bool *doPageWrites_p);
extern XLogRecPtr GetRedoRecPtr(void);
extern XLogRecPtr GetInsertRecPtr(void);
extern XLogRecPtr GetFlushRecPtr(TimeLineID *insertTLI);
extern TimeLineID GetWALInsertionTimeLine(void);
extern XLogRecPtr GetLastImportantRecPtr(void);

extern void SetWalWriterSleeping(bool sleeping);

extern void assign_max_wal_size(int newval, void *extra);
extern void assign_checkpoint_completion_target(double newval, void *extra);

/*
 * Routines used by xlogrecovery.c to call back into xlog.c during recovery.
 */
extern void RemoveNonParentXlogFiles(XLogRecPtr switchpoint, TimeLineID newTLI);
extern bool XLogCheckpointNeeded(XLogSegNo new_segno);
extern void SwitchIntoArchiveRecovery(XLogRecPtr EndRecPtr, TimeLineID replayTLI);
extern void ReachedEndOfBackup(XLogRecPtr EndRecPtr, TimeLineID tli);
extern void SetInstallXLogFileSegmentActive(void);
extern bool IsInstallXLogFileSegmentActive(void);
extern void XLogShutdownWalRcv(void);

/*
 * Routines to start, stop, and get status of a base backup.
 */

/*
 * Session-level status of base backups
 *
 * This is used in parallel with the shared memory status to control parallel
 * execution of base backup functions for a given session, be it a backend
 * dedicated to replication or a normal backend connected to a database. The
 * update of the session-level status happens at the same time as the shared
 * memory counters to keep a consistent global and local state of the backups
 * running.
 */
typedef enum SessionBackupState
{
	SESSION_BACKUP_NONE,
	SESSION_BACKUP_RUNNING,
} SessionBackupState;

extern XLogRecPtr do_pg_backup_start(const char *backupidstr, bool fast,
									 TimeLineID *starttli_p, StringInfo labelfile,
									 List **tablespaces, StringInfo tblspcmapfile);
extern XLogRecPtr do_pg_backup_stop(char *labelfile, bool waitforarchive,
									TimeLineID *stoptli_p);
extern void do_pg_abort_backup(int code, Datum arg);
extern void register_persistent_abort_backup_handler(void);
extern SessionBackupState get_backup_status(void);

/* File path names (all relative to $PGDATA) */
#define RECOVERY_SIGNAL_FILE	"recovery.signal"
#define STANDBY_SIGNAL_FILE		"standby.signal"
#define BACKUP_LABEL_FILE		"backup_label"
#define BACKUP_LABEL_OLD		"backup_label.old"

#define TABLESPACE_MAP			"tablespace_map"
#define TABLESPACE_MAP_OLD		"tablespace_map.old"

/* files to signal promotion to primary */
#define PROMOTE_SIGNAL_FILE		"promote"

#endif							/* XLOG_H */
