/*-------------------------------------------------------------------------
 *
 * proc.h
 *	  per-process shared memory data structures
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/proc.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _PROC_H_
#define _PROC_H_

#include "access/clog.h"
#include "access/xlogdefs.h"
#include "lib/ilist.h"
#include "storage/latch.h"
#include "storage/lock.h"
#include "storage/pg_sema.h"
#include "storage/proclist_types.h"

/*
 * Each backend advertises up to PGPROC_MAX_CACHED_SUBXIDS TransactionIds
 * for non-aborted subtransactions of its current top transaction.  These
 * have to be treated as running XIDs by other backends.
 *
 * We also keep track of whether the cache overflowed (ie, the transaction has
 * generated at least one subtransaction that didn't fit in the cache).
 * If none of the caches have overflowed, we can assume that an XID that's not
 * listed anywhere in the PGPROC array is not a running transaction.  Else we
 * have to look at pg_subtrans.
 */
#define PGPROC_MAX_CACHED_SUBXIDS 64	/* XXX guessed-at value */

typedef struct XidCacheStatus
{
	/* number of cached subxids, never more than PGPROC_MAX_CACHED_SUBXIDS */
	uint8		count;
	/* has PGPROC->subxids overflowed */
	bool		overflowed;
} XidCacheStatus;

struct XidCache
{
	TransactionId xids[PGPROC_MAX_CACHED_SUBXIDS];
};

/*
 * Flags for PGPROC->statusFlags and PROC_HDR->statusFlags[]
 */
#define		PROC_IS_AUTOVACUUM	0x01	/* is it an autovac worker? */
#define		PROC_IN_VACUUM		0x02	/* currently running lazy vacuum */
#define		PROC_IN_SAFE_IC		0x04	/* currently running CREATE INDEX
										 * CONCURRENTLY or REINDEX
										 * CONCURRENTLY on non-expressional,
										 * non-partial index */
#define		PROC_VACUUM_FOR_WRAPAROUND	0x08	/* set by autovac only */
#define		PROC_IN_LOGICAL_DECODING	0x10	/* currently doing logical
												 * decoding outside xact */
#define		PROC_AFFECTS_ALL_HORIZONS	0x20	/* this proc's xmin must be
												 * included in vacuum horizons
												 * in all databases */

/* flags reset at EOXact */
#define		PROC_VACUUM_STATE_MASK \
	(PROC_IN_VACUUM | PROC_IN_SAFE_IC | PROC_VACUUM_FOR_WRAPAROUND)

/*
 * Xmin-related flags. Make sure any flags that affect how the process' Xmin
 * value is interpreted by VACUUM are included here.
 */
#define		PROC_XMIN_FLAGS (PROC_IN_VACUUM | PROC_IN_SAFE_IC)

/*
 * We allow a small number of "weak" relation locks (AccessShareLock,
 * RowShareLock, RowExclusiveLock) to be recorded in the PGPROC structure
 * rather than the main lock table.  This eases contention on the lock
 * manager LWLocks.  See storage/lmgr/README for additional details.
 */
#define		FP_LOCK_SLOTS_PER_BACKEND 16

/*
 * An invalid pgprocno.  Must be larger than the maximum number of PGPROC
 * structures we could possibly have.  See comments for MAX_BACKENDS.
 */
#define INVALID_PGPROCNO		PG_INT32_MAX

/*
 * Flags for PGPROC.delayChkpt
 *
 * These flags can be used to delay the start or completion of a checkpoint
 * for short periods. A flag is in effect if the corresponding bit is set in
 * the PGPROC of any backend.
 *
 * For our purposes here, a checkpoint has three phases: (1) determine the
 * location to which the redo pointer will be moved, (2) write all the
 * data durably to disk, and (3) WAL-log the checkpoint.
 *
 * Setting DELAY_CHKPT_START prevents the system from moving from phase 1
 * to phase 2. This is useful when we are performing a WAL-logged modification
 * of data that will be flushed to disk in phase 2. By setting this flag
 * before writing WAL and clearing it after we've both written WAL and
 * performed the corresponding modification, we ensure that if the WAL record
 * is inserted prior to the new redo point, the corresponding data changes will
 * also be flushed to disk before the checkpoint can complete. (In the
 * extremely common case where the data being modified is in shared buffers
 * and we acquire an exclusive content lock on the relevant buffers before
 * writing WAL, this mechanism is not needed, because phase 2 will block
 * until we release the content lock and then flush the modified data to
 * disk.)
 *
 * Setting DELAY_CHKPT_COMPLETE prevents the system from moving from phase 2
 * to phase 3. This is useful if we are performing a WAL-logged operation that
 * might invalidate buffers, such as relation truncation. In this case, we need
 * to ensure that any buffers which were invalidated and thus not flushed by
 * the checkpoint are actaully destroyed on disk. Replay can cope with a file
 * or block that doesn't exist, but not with a block that has the wrong
 * contents.
 */
#define DELAY_CHKPT_START		(1<<0)
#define DELAY_CHKPT_COMPLETE	(1<<1)

typedef enum
{
	PROC_WAIT_STATUS_OK,
	PROC_WAIT_STATUS_WAITING,
	PROC_WAIT_STATUS_ERROR,
} ProcWaitStatus;

/*
 * Each backend has a PGPROC struct in shared memory.  There is also a list of
 * currently-unused PGPROC structs that will be reallocated to new backends.
 *
 * links: list link for any list the PGPROC is in.  When waiting for a lock,
 * the PGPROC is linked into that lock's waitProcs queue.  A recycled PGPROC
 * is linked into ProcGlobal's freeProcs list.
 *
 * Note: twophase.c also sets up a dummy PGPROC struct for each currently
 * prepared transaction.  These PGPROCs appear in the ProcArray data structure
 * so that the prepared transactions appear to be still running and are
 * correctly shown as holding locks.  A prepared transaction PGPROC can be
 * distinguished from a real one at need by the fact that it has pid == 0.
 * The semaphore and lock-activity fields in a prepared-xact PGPROC are unused,
 * but its myProcLocks[] lists are valid.
 *
 * We allow many fields of this struct to be accessed without locks, such as
 * delayChkpt and isBackgroundWorker. However, keep in mind that writing
 * mirrored ones (see below) requires holding ProcArrayLock or XidGenLock in
 * at least shared mode, so that pgxactoff does not change concurrently.
 *
 * Mirrored fields:
 *
 * Some fields in PGPROC (see "mirrored in ..." comment) are mirrored into an
 * element of more densely packed ProcGlobal arrays. These arrays are indexed
 * by PGPROC->pgxactoff. Both copies need to be maintained coherently.
 *
 * NB: The pgxactoff indexed value can *never* be accessed without holding
 * locks.
 *
 * See PROC_HDR for details.
 */
struct PGPROC
{
	/* proc->links MUST BE FIRST IN STRUCT (see ProcSleep,ProcWakeup,etc) */
	SHM_QUEUE	links;			/* list link if process is in a list */
	PGPROC	  **procgloballist; /* procglobal list that owns this PGPROC */

	PGSemaphore sem;			/* ONE semaphore to sleep on */
	ProcWaitStatus waitStatus;

	Latch		procLatch;		/* generic latch for process */


	TransactionId xid;			/* id of top-level transaction currently being
								 * executed by this proc, if running and XID
								 * is assigned; else InvalidTransactionId.
								 * mirrored in ProcGlobal->xids[pgxactoff] */

	TransactionId xmin;			/* minimal running XID as it was when we were
								 * starting our xact, excluding LAZY VACUUM:
								 * vacuum must not remove tuples deleted by
								 * xid >= xmin ! */

	LocalTransactionId lxid;	/* local id of top-level transaction currently
								 * being executed by this proc, if running;
								 * else InvalidLocalTransactionId */
	int			pid;			/* Backend's process ID; 0 if prepared xact */

	int			pgxactoff;		/* offset into various ProcGlobal->arrays with
								 * data mirrored from this PGPROC */
	int			pgprocno;

	/* These fields are zero while a backend is still starting up: */
	BackendId	backendId;		/* This backend's backend ID (if assigned) */
	Oid			databaseId;		/* OID of database this backend is using */
	Oid			roleId;			/* OID of role using this backend */

	Oid			tempNamespaceId;	/* OID of temp schema this backend is
									 * using */

	bool		isBackgroundWorker; /* true if background worker. */

	/*
	 * While in hot standby mode, shows that a conflict signal has been sent
	 * for the current transaction. Set/cleared while holding ProcArrayLock,
	 * though not required. Accessed without lock, if needed.
	 */
	bool		recoveryConflictPending;

	/* Info about LWLock the process is currently waiting for, if any. */
	bool		lwWaiting;		/* true if waiting for an LW lock */
	uint8		lwWaitMode;		/* lwlock mode being waited for */
	proclist_node lwWaitLink;	/* position in LW lock wait list */

	/* Support for condition variables. */
	proclist_node cvWaitLink;	/* position in CV wait list */

	/* Info about lock the process is currently waiting for, if any. */
	/* waitLock and waitProcLock are NULL if not currently waiting. */
	LOCK	   *waitLock;		/* Lock object we're sleeping on ... */
	PROCLOCK   *waitProcLock;	/* Per-holder info for awaited lock */
	LOCKMODE	waitLockMode;	/* type of lock we're waiting for */
	LOCKMASK	heldLocks;		/* bitmask for lock types already held on this
								 * lock object by this backend */
	pg_atomic_uint64 waitStart; /* time at which wait for lock acquisition
								 * started */

	int			delayChkptFlags;	/* for DELAY_CHKPT_* flags */

	uint8		statusFlags;	/* this backend's status flags, see PROC_*
								 * above. mirrored in
								 * ProcGlobal->statusFlags[pgxactoff] */

	/*
	 * Info to allow us to wait for synchronous replication, if needed.
	 * waitLSN is InvalidXLogRecPtr if not waiting; set only by user backend.
	 * syncRepState must not be touched except by owning process or WALSender.
	 * syncRepLinks used only while holding SyncRepLock.
	 */
	XLogRecPtr	waitLSN;		/* waiting for this LSN or higher */
	int			syncRepState;	/* wait state for sync rep */
	SHM_QUEUE	syncRepLinks;	/* list link if process is in syncrep queue */

	/*
	 * All PROCLOCK objects for locks held or awaited by this backend are
	 * linked into one of these lists, according to the partition number of
	 * their lock.
	 */
	SHM_QUEUE	myProcLocks[NUM_LOCK_PARTITIONS];

	XidCacheStatus subxidStatus;	/* mirrored with
									 * ProcGlobal->subxidStates[i] */
	struct XidCache subxids;	/* cache for subtransaction XIDs */

	/* Support for group XID clearing. */
	/* true, if member of ProcArray group waiting for XID clear */
	bool		procArrayGroupMember;
	/* next ProcArray group member waiting for XID clear */
	pg_atomic_uint32 procArrayGroupNext;

	/*
	 * latest transaction id among the transaction's main XID and
	 * subtransactions
	 */
	TransactionId procArrayGroupMemberXid;

	uint32		wait_event_info;	/* proc's wait information */

	/* Support for group transaction status update. */
	bool		clogGroupMember;	/* true, if member of clog group */
	pg_atomic_uint32 clogGroupNext; /* next clog group member */
	TransactionId clogGroupMemberXid;	/* transaction id of clog group member */
	XidStatus	clogGroupMemberXidStatus;	/* transaction status of clog
											 * group member */
	int			clogGroupMemberPage;	/* clog page corresponding to
										 * transaction id of clog group member */
	XLogRecPtr	clogGroupMemberLsn; /* WAL location of commit record for clog
									 * group member */

	/* Lock manager data, recording fast-path locks taken by this backend. */
	LWLock		fpInfoLock;		/* protects per-backend fast-path state */
	uint64		fpLockBits;		/* lock modes held for each fast-path slot */
	Oid			fpRelId[FP_LOCK_SLOTS_PER_BACKEND]; /* slots for rel oids */
	bool		fpVXIDLock;		/* are we holding a fast-path VXID lock? */
	LocalTransactionId fpLocalTransactionId;	/* lxid for fast-path VXID
												 * lock */

	/*
	 * Support for lock groups.  Use LockHashPartitionLockByProc on the group
	 * leader to get the LWLock protecting these fields.
	 */
	PGPROC	   *lockGroupLeader;	/* lock group leader, if I'm a member */
	dlist_head	lockGroupMembers;	/* list of members, if I'm a leader */
	dlist_node	lockGroupLink;	/* my member link, if I'm a member */
};

/* NOTE: "typedef struct PGPROC PGPROC" appears in storage/lock.h. */


extern PGDLLIMPORT PGPROC *MyProc;

/*
 * There is one ProcGlobal struct for the whole database cluster.
 *
 * Adding/Removing an entry into the procarray requires holding *both*
 * ProcArrayLock and XidGenLock in exclusive mode (in that order). Both are
 * needed because the dense arrays (see below) are accessed from
 * GetNewTransactionId() and GetSnapshotData(), and we don't want to add
 * further contention by both using the same lock. Adding/Removing a procarray
 * entry is much less frequent.
 *
 * Some fields in PGPROC are mirrored into more densely packed arrays (e.g.
 * xids), with one entry for each backend. These arrays only contain entries
 * for PGPROCs that have been added to the shared array with ProcArrayAdd()
 * (in contrast to PGPROC array which has unused PGPROCs interspersed).
 *
 * The dense arrays are indexed by PGPROC->pgxactoff. Any concurrent
 * ProcArrayAdd() / ProcArrayRemove() can lead to pgxactoff of a procarray
 * member to change.  Therefore it is only safe to use PGPROC->pgxactoff to
 * access the dense array while holding either ProcArrayLock or XidGenLock.
 *
 * As long as a PGPROC is in the procarray, the mirrored values need to be
 * maintained in both places in a coherent manner.
 *
 * The denser separate arrays are beneficial for three main reasons: First, to
 * allow for as tight loops accessing the data as possible. Second, to prevent
 * updates of frequently changing data (e.g. xmin) from invalidating
 * cachelines also containing less frequently changing data (e.g. xid,
 * statusFlags). Third to condense frequently accessed data into as few
 * cachelines as possible.
 *
 * There are two main reasons to have the data mirrored between these dense
 * arrays and PGPROC. First, as explained above, a PGPROC's array entries can
 * only be accessed with either ProcArrayLock or XidGenLock held, whereas the
 * PGPROC entries do not require that (obviously there may still be locking
 * requirements around the individual field, separate from the concerns
 * here). That is particularly important for a backend to efficiently checks
 * it own values, which it often can safely do without locking.  Second, the
 * PGPROC fields allow to avoid unnecessary accesses and modification to the
 * dense arrays. A backend's own PGPROC is more likely to be in a local cache,
 * whereas the cachelines for the dense array will be modified by other
 * backends (often removing it from the cache for other cores/sockets). At
 * commit/abort time a check of the PGPROC value can avoid accessing/dirtying
 * the corresponding array value.
 *
 * Basically it makes sense to access the PGPROC variable when checking a
 * single backend's data, especially when already looking at the PGPROC for
 * other reasons already.  It makes sense to look at the "dense" arrays if we
 * need to look at many / most entries, because we then benefit from the
 * reduced indirection and better cross-process cache-ability.
 *
 * When entering a PGPROC for 2PC transactions with ProcArrayAdd(), the data
 * in the dense arrays is initialized from the PGPROC while it already holds
 * ProcArrayLock.
 */
typedef struct PROC_HDR
{
	/* Array of PGPROC structures (not including dummies for prepared txns) */
	PGPROC	   *allProcs;

	/* Array mirroring PGPROC.xid for each PGPROC currently in the procarray */
	TransactionId *xids;

	/*
	 * Array mirroring PGPROC.subxidStatus for each PGPROC currently in the
	 * procarray.
	 */
	XidCacheStatus *subxidStates;

	/*
	 * Array mirroring PGPROC.statusFlags for each PGPROC currently in the
	 * procarray.
	 */
	uint8	   *statusFlags;

	/* Length of allProcs array */
	uint32		allProcCount;
	/* Head of list of free PGPROC structures */
	PGPROC	   *freeProcs;
	/* Head of list of autovacuum's free PGPROC structures */
	PGPROC	   *autovacFreeProcs;
	/* Head of list of bgworker free PGPROC structures */
	PGPROC	   *bgworkerFreeProcs;
	/* Head of list of walsender free PGPROC structures */
	PGPROC	   *walsenderFreeProcs;
	/* First pgproc waiting for group XID clear */
	pg_atomic_uint32 procArrayGroupFirst;
	/* First pgproc waiting for group transaction status update */
	pg_atomic_uint32 clogGroupFirst;
	/* WALWriter process's latch */
	Latch	   *walwriterLatch;
	/* Checkpointer process's latch */
	Latch	   *checkpointerLatch;
	/* Current shared estimate of appropriate spins_per_delay value */
	int			spins_per_delay;
	/* Buffer id of the buffer that Startup process waits for pin on, or -1 */
	int			startupBufferPinWaitBufId;
} PROC_HDR;

extern PGDLLIMPORT PROC_HDR *ProcGlobal;

extern PGDLLIMPORT PGPROC *PreparedXactProcs;

/* Accessor for PGPROC given a pgprocno. */
#define GetPGProcByNumber(n) (&ProcGlobal->allProcs[(n)])

/*
 * We set aside some extra PGPROC structures for auxiliary processes,
 * ie things that aren't full-fledged backends but need shmem access.
 *
 * Background writer, checkpointer, WAL writer and archiver run during normal
 * operation.  Startup process and WAL receiver also consume 2 slots, but WAL
 * writer is launched only after startup has exited, so we only need 5 slots.
 */
#define NUM_AUXILIARY_PROCS		5

/* configurable options */
extern PGDLLIMPORT int DeadlockTimeout;
extern PGDLLIMPORT int StatementTimeout;
extern PGDLLIMPORT int LockTimeout;
extern PGDLLIMPORT int IdleInTransactionSessionTimeout;
extern PGDLLIMPORT int IdleSessionTimeout;
extern PGDLLIMPORT bool log_lock_waits;


/*
 * Function Prototypes
 */
extern int	ProcGlobalSemas(void);
extern Size ProcGlobalShmemSize(void);
extern void InitProcGlobal(void);
extern void InitProcess(void);
extern void InitProcessPhase2(void);
extern void InitAuxiliaryProcess(void);

extern void SetStartupBufferPinWaitBufId(int bufid);
extern int	GetStartupBufferPinWaitBufId(void);

extern bool HaveNFreeProcs(int n);
extern void ProcReleaseLocks(bool isCommit);

extern void ProcQueueInit(PROC_QUEUE *queue);
extern ProcWaitStatus ProcSleep(LOCALLOCK *locallock, LockMethod lockMethodTable);
extern PGPROC *ProcWakeup(PGPROC *proc, ProcWaitStatus waitStatus);
extern void ProcLockWakeup(LockMethod lockMethodTable, LOCK *lock);
extern void CheckDeadLockAlert(void);
extern bool IsWaitingForLock(void);
extern void LockErrorCleanup(void);

extern void ProcWaitForSignal(uint32 wait_event_info);
extern void ProcSendSignal(int pgprocno);

extern PGPROC *AuxiliaryPidGetProc(int pid);

extern void BecomeLockGroupLeader(void);
extern bool BecomeLockGroupMember(PGPROC *leader, int pid);

#endif							/* _PROC_H_ */
