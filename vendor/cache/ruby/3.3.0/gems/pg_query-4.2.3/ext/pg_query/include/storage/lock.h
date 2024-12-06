/*-------------------------------------------------------------------------
 *
 * lock.h
 *	  POSTGRES low-level lock mechanism
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/lock.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef LOCK_H_
#define LOCK_H_

#ifdef FRONTEND
#error "lock.h may not be included from frontend code"
#endif

#include "storage/backendid.h"
#include "storage/lockdefs.h"
#include "storage/lwlock.h"
#include "storage/shmem.h"
#include "utils/timestamp.h"

/* struct PGPROC is declared in proc.h, but must forward-reference it */
typedef struct PGPROC PGPROC;

typedef struct PROC_QUEUE
{
	SHM_QUEUE	links;			/* head of list of PGPROC objects */
	int			size;			/* number of entries in list */
} PROC_QUEUE;

/* GUC variables */
extern PGDLLIMPORT int max_locks_per_xact;

#ifdef LOCK_DEBUG
extern PGDLLIMPORT int Trace_lock_oidmin;
extern PGDLLIMPORT bool Trace_locks;
extern PGDLLIMPORT bool Trace_userlocks;
extern PGDLLIMPORT int Trace_lock_table;
extern PGDLLIMPORT bool Debug_deadlocks;
#endif							/* LOCK_DEBUG */


/*
 * Top-level transactions are identified by VirtualTransactionIDs comprising
 * PGPROC fields backendId and lxid.  For recovered prepared transactions, the
 * LocalTransactionId is an ordinary XID; LOCKTAG_VIRTUALTRANSACTION never
 * refers to that kind.  These are guaranteed unique over the short term, but
 * will be reused after a database restart or XID wraparound; hence they
 * should never be stored on disk.
 *
 * Note that struct VirtualTransactionId can not be assumed to be atomically
 * assignable as a whole.  However, type LocalTransactionId is assumed to
 * be atomically assignable, and the backend ID doesn't change often enough
 * to be a problem, so we can fetch or assign the two fields separately.
 * We deliberately refrain from using the struct within PGPROC, to prevent
 * coding errors from trying to use struct assignment with it; instead use
 * GET_VXID_FROM_PGPROC().
 */
typedef struct
{
	BackendId	backendId;		/* backendId from PGPROC */
	LocalTransactionId localTransactionId;	/* lxid from PGPROC */
} VirtualTransactionId;

#define InvalidLocalTransactionId		0
#define LocalTransactionIdIsValid(lxid) ((lxid) != InvalidLocalTransactionId)
#define VirtualTransactionIdIsValid(vxid) \
	(LocalTransactionIdIsValid((vxid).localTransactionId))
#define VirtualTransactionIdIsRecoveredPreparedXact(vxid) \
	((vxid).backendId == InvalidBackendId)
#define VirtualTransactionIdEquals(vxid1, vxid2) \
	((vxid1).backendId == (vxid2).backendId && \
	 (vxid1).localTransactionId == (vxid2).localTransactionId)
#define SetInvalidVirtualTransactionId(vxid) \
	((vxid).backendId = InvalidBackendId, \
	 (vxid).localTransactionId = InvalidLocalTransactionId)
#define GET_VXID_FROM_PGPROC(vxid, proc) \
	((vxid).backendId = (proc).backendId, \
	 (vxid).localTransactionId = (proc).lxid)

/* MAX_LOCKMODES cannot be larger than the # of bits in LOCKMASK */
#define MAX_LOCKMODES		10

#define LOCKBIT_ON(lockmode) (1 << (lockmode))
#define LOCKBIT_OFF(lockmode) (~(1 << (lockmode)))


/*
 * This data structure defines the locking semantics associated with a
 * "lock method".  The semantics specify the meaning of each lock mode
 * (by defining which lock modes it conflicts with).
 * All of this data is constant and is kept in const tables.
 *
 * numLockModes -- number of lock modes (READ,WRITE,etc) that
 *		are defined in this lock method.  Must be less than MAX_LOCKMODES.
 *
 * conflictTab -- this is an array of bitmasks showing lock
 *		mode conflicts.  conflictTab[i] is a mask with the j-th bit
 *		turned on if lock modes i and j conflict.  Lock modes are
 *		numbered 1..numLockModes; conflictTab[0] is unused.
 *
 * lockModeNames -- ID strings for debug printouts.
 *
 * trace_flag -- pointer to GUC trace flag for this lock method.  (The
 * GUC variable is not constant, but we use "const" here to denote that
 * it can't be changed through this reference.)
 */
typedef struct LockMethodData
{
	int			numLockModes;
	const LOCKMASK *conflictTab;
	const char *const *lockModeNames;
	const bool *trace_flag;
} LockMethodData;

typedef const LockMethodData *LockMethod;

/*
 * Lock methods are identified by LOCKMETHODID.  (Despite the declaration as
 * uint16, we are constrained to 256 lockmethods by the layout of LOCKTAG.)
 */
typedef uint16 LOCKMETHODID;

/* These identify the known lock methods */
#define DEFAULT_LOCKMETHOD	1
#define USER_LOCKMETHOD		2

/*
 * LOCKTAG is the key information needed to look up a LOCK item in the
 * lock hashtable.  A LOCKTAG value uniquely identifies a lockable object.
 *
 * The LockTagType enum defines the different kinds of objects we can lock.
 * We can handle up to 256 different LockTagTypes.
 */
typedef enum LockTagType
{
	LOCKTAG_RELATION,			/* whole relation */
	LOCKTAG_RELATION_EXTEND,	/* the right to extend a relation */
	LOCKTAG_DATABASE_FROZEN_IDS,	/* pg_database.datfrozenxid */
	LOCKTAG_PAGE,				/* one page of a relation */
	LOCKTAG_TUPLE,				/* one physical tuple */
	LOCKTAG_TRANSACTION,		/* transaction (for waiting for xact done) */
	LOCKTAG_VIRTUALTRANSACTION, /* virtual transaction (ditto) */
	LOCKTAG_SPECULATIVE_TOKEN,	/* speculative insertion Xid and token */
	LOCKTAG_OBJECT,				/* non-relation database object */
	LOCKTAG_USERLOCK,			/* reserved for old contrib/userlock code */
	LOCKTAG_ADVISORY			/* advisory user locks */
} LockTagType;

#define LOCKTAG_LAST_TYPE	LOCKTAG_ADVISORY

extern PGDLLIMPORT const char *const LockTagTypeNames[];

/*
 * The LOCKTAG struct is defined with malice aforethought to fit into 16
 * bytes with no padding.  Note that this would need adjustment if we were
 * to widen Oid, BlockNumber, or TransactionId to more than 32 bits.
 *
 * We include lockmethodid in the locktag so that a single hash table in
 * shared memory can store locks of different lockmethods.
 */
typedef struct LOCKTAG
{
	uint32		locktag_field1; /* a 32-bit ID field */
	uint32		locktag_field2; /* a 32-bit ID field */
	uint32		locktag_field3; /* a 32-bit ID field */
	uint16		locktag_field4; /* a 16-bit ID field */
	uint8		locktag_type;	/* see enum LockTagType */
	uint8		locktag_lockmethodid;	/* lockmethod indicator */
} LOCKTAG;

/*
 * These macros define how we map logical IDs of lockable objects into
 * the physical fields of LOCKTAG.  Use these to set up LOCKTAG values,
 * rather than accessing the fields directly.  Note multiple eval of target!
 */

/* ID info for a relation is DB OID + REL OID; DB OID = 0 if shared */
#define SET_LOCKTAG_RELATION(locktag,dboid,reloid) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = (reloid), \
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_RELATION, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* same ID info as RELATION */
#define SET_LOCKTAG_RELATION_EXTEND(locktag,dboid,reloid) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = (reloid), \
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_RELATION_EXTEND, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* ID info for frozen IDs is DB OID */
#define SET_LOCKTAG_DATABASE_FROZEN_IDS(locktag,dboid) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = 0, \
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_DATABASE_FROZEN_IDS, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* ID info for a page is RELATION info + BlockNumber */
#define SET_LOCKTAG_PAGE(locktag,dboid,reloid,blocknum) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = (reloid), \
	 (locktag).locktag_field3 = (blocknum), \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_PAGE, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* ID info for a tuple is PAGE info + OffsetNumber */
#define SET_LOCKTAG_TUPLE(locktag,dboid,reloid,blocknum,offnum) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = (reloid), \
	 (locktag).locktag_field3 = (blocknum), \
	 (locktag).locktag_field4 = (offnum), \
	 (locktag).locktag_type = LOCKTAG_TUPLE, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* ID info for a transaction is its TransactionId */
#define SET_LOCKTAG_TRANSACTION(locktag,xid) \
	((locktag).locktag_field1 = (xid), \
	 (locktag).locktag_field2 = 0, \
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_TRANSACTION, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/* ID info for a virtual transaction is its VirtualTransactionId */
#define SET_LOCKTAG_VIRTUALTRANSACTION(locktag,vxid) \
	((locktag).locktag_field1 = (vxid).backendId, \
	 (locktag).locktag_field2 = (vxid).localTransactionId, \
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_VIRTUALTRANSACTION, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/*
 * ID info for a speculative insert is TRANSACTION info +
 * its speculative insert counter.
 */
#define SET_LOCKTAG_SPECULATIVE_INSERTION(locktag,xid,token) \
	((locktag).locktag_field1 = (xid), \
	 (locktag).locktag_field2 = (token),		\
	 (locktag).locktag_field3 = 0, \
	 (locktag).locktag_field4 = 0, \
	 (locktag).locktag_type = LOCKTAG_SPECULATIVE_TOKEN, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

/*
 * ID info for an object is DB OID + CLASS OID + OBJECT OID + SUBID
 *
 * Note: object ID has same representation as in pg_depend and
 * pg_description, but notice that we are constraining SUBID to 16 bits.
 * Also, we use DB OID = 0 for shared objects such as tablespaces.
 */
#define SET_LOCKTAG_OBJECT(locktag,dboid,classoid,objoid,objsubid) \
	((locktag).locktag_field1 = (dboid), \
	 (locktag).locktag_field2 = (classoid), \
	 (locktag).locktag_field3 = (objoid), \
	 (locktag).locktag_field4 = (objsubid), \
	 (locktag).locktag_type = LOCKTAG_OBJECT, \
	 (locktag).locktag_lockmethodid = DEFAULT_LOCKMETHOD)

#define SET_LOCKTAG_ADVISORY(locktag,id1,id2,id3,id4) \
	((locktag).locktag_field1 = (id1), \
	 (locktag).locktag_field2 = (id2), \
	 (locktag).locktag_field3 = (id3), \
	 (locktag).locktag_field4 = (id4), \
	 (locktag).locktag_type = LOCKTAG_ADVISORY, \
	 (locktag).locktag_lockmethodid = USER_LOCKMETHOD)


/*
 * Per-locked-object lock information:
 *
 * tag -- uniquely identifies the object being locked
 * grantMask -- bitmask for all lock types currently granted on this object.
 * waitMask -- bitmask for all lock types currently awaited on this object.
 * procLocks -- list of PROCLOCK objects for this lock.
 * waitProcs -- queue of processes waiting for this lock.
 * requested -- count of each lock type currently requested on the lock
 *		(includes requests already granted!!).
 * nRequested -- total requested locks of all types.
 * granted -- count of each lock type currently granted on the lock.
 * nGranted -- total granted locks of all types.
 *
 * Note: these counts count 1 for each backend.  Internally to a backend,
 * there may be multiple grabs on a particular lock, but this is not reflected
 * into shared memory.
 */
typedef struct LOCK
{
	/* hash key */
	LOCKTAG		tag;			/* unique identifier of lockable object */

	/* data */
	LOCKMASK	grantMask;		/* bitmask for lock types already granted */
	LOCKMASK	waitMask;		/* bitmask for lock types awaited */
	SHM_QUEUE	procLocks;		/* list of PROCLOCK objects assoc. with lock */
	PROC_QUEUE	waitProcs;		/* list of PGPROC objects waiting on lock */
	int			requested[MAX_LOCKMODES];	/* counts of requested locks */
	int			nRequested;		/* total of requested[] array */
	int			granted[MAX_LOCKMODES]; /* counts of granted locks */
	int			nGranted;		/* total of granted[] array */
} LOCK;

#define LOCK_LOCKMETHOD(lock) ((LOCKMETHODID) (lock).tag.locktag_lockmethodid)
#define LOCK_LOCKTAG(lock) ((LockTagType) (lock).tag.locktag_type)


/*
 * We may have several different backends holding or awaiting locks
 * on the same lockable object.  We need to store some per-holder/waiter
 * information for each such holder (or would-be holder).  This is kept in
 * a PROCLOCK struct.
 *
 * PROCLOCKTAG is the key information needed to look up a PROCLOCK item in the
 * proclock hashtable.  A PROCLOCKTAG value uniquely identifies the combination
 * of a lockable object and a holder/waiter for that object.  (We can use
 * pointers here because the PROCLOCKTAG need only be unique for the lifespan
 * of the PROCLOCK, and it will never outlive the lock or the proc.)
 *
 * Internally to a backend, it is possible for the same lock to be held
 * for different purposes: the backend tracks transaction locks separately
 * from session locks.  However, this is not reflected in the shared-memory
 * state: we only track which backend(s) hold the lock.  This is OK since a
 * backend can never block itself.
 *
 * The holdMask field shows the already-granted locks represented by this
 * proclock.  Note that there will be a proclock object, possibly with
 * zero holdMask, for any lock that the process is currently waiting on.
 * Otherwise, proclock objects whose holdMasks are zero are recycled
 * as soon as convenient.
 *
 * releaseMask is workspace for LockReleaseAll(): it shows the locks due
 * to be released during the current call.  This must only be examined or
 * set by the backend owning the PROCLOCK.
 *
 * Each PROCLOCK object is linked into lists for both the associated LOCK
 * object and the owning PGPROC object.  Note that the PROCLOCK is entered
 * into these lists as soon as it is created, even if no lock has yet been
 * granted.  A PGPROC that is waiting for a lock to be granted will also be
 * linked into the lock's waitProcs queue.
 */
typedef struct PROCLOCKTAG
{
	/* NB: we assume this struct contains no padding! */
	LOCK	   *myLock;			/* link to per-lockable-object information */
	PGPROC	   *myProc;			/* link to PGPROC of owning backend */
} PROCLOCKTAG;

typedef struct PROCLOCK
{
	/* tag */
	PROCLOCKTAG tag;			/* unique identifier of proclock object */

	/* data */
	PGPROC	   *groupLeader;	/* proc's lock group leader, or proc itself */
	LOCKMASK	holdMask;		/* bitmask for lock types currently held */
	LOCKMASK	releaseMask;	/* bitmask for lock types to be released */
	SHM_QUEUE	lockLink;		/* list link in LOCK's list of proclocks */
	SHM_QUEUE	procLink;		/* list link in PGPROC's list of proclocks */
} PROCLOCK;

#define PROCLOCK_LOCKMETHOD(proclock) \
	LOCK_LOCKMETHOD(*((proclock).tag.myLock))

/*
 * Each backend also maintains a local hash table with information about each
 * lock it is currently interested in.  In particular the local table counts
 * the number of times that lock has been acquired.  This allows multiple
 * requests for the same lock to be executed without additional accesses to
 * shared memory.  We also track the number of lock acquisitions per
 * ResourceOwner, so that we can release just those locks belonging to a
 * particular ResourceOwner.
 *
 * When holding a lock taken "normally", the lock and proclock fields always
 * point to the associated objects in shared memory.  However, if we acquired
 * the lock via the fast-path mechanism, the lock and proclock fields are set
 * to NULL, since there probably aren't any such objects in shared memory.
 * (If the lock later gets promoted to normal representation, we may eventually
 * update our locallock's lock/proclock fields after finding the shared
 * objects.)
 *
 * Caution: a locallock object can be left over from a failed lock acquisition
 * attempt.  In this case its lock/proclock fields are untrustworthy, since
 * the shared lock object is neither held nor awaited, and hence is available
 * to be reclaimed.  If nLocks > 0 then these pointers must either be valid or
 * NULL, but when nLocks == 0 they should be considered garbage.
 */
typedef struct LOCALLOCKTAG
{
	LOCKTAG		lock;			/* identifies the lockable object */
	LOCKMODE	mode;			/* lock mode for this table entry */
} LOCALLOCKTAG;

typedef struct LOCALLOCKOWNER
{
	/*
	 * Note: if owner is NULL then the lock is held on behalf of the session;
	 * otherwise it is held on behalf of my current transaction.
	 *
	 * Must use a forward struct reference to avoid circularity.
	 */
	struct ResourceOwnerData *owner;
	int64		nLocks;			/* # of times held by this owner */
} LOCALLOCKOWNER;

typedef struct LOCALLOCK
{
	/* tag */
	LOCALLOCKTAG tag;			/* unique identifier of locallock entry */

	/* data */
	uint32		hashcode;		/* copy of LOCKTAG's hash value */
	LOCK	   *lock;			/* associated LOCK object, if any */
	PROCLOCK   *proclock;		/* associated PROCLOCK object, if any */
	int64		nLocks;			/* total number of times lock is held */
	int			numLockOwners;	/* # of relevant ResourceOwners */
	int			maxLockOwners;	/* allocated size of array */
	LOCALLOCKOWNER *lockOwners; /* dynamically resizable array */
	bool		holdsStrongLockCount;	/* bumped FastPathStrongRelationLocks */
	bool		lockCleared;	/* we read all sinval msgs for lock */
} LOCALLOCK;

#define LOCALLOCK_LOCKMETHOD(llock) ((llock).tag.lock.locktag_lockmethodid)
#define LOCALLOCK_LOCKTAG(llock) ((LockTagType) (llock).tag.lock.locktag_type)


/*
 * These structures hold information passed from lmgr internals to the lock
 * listing user-level functions (in lockfuncs.c).
 */

typedef struct LockInstanceData
{
	LOCKTAG		locktag;		/* tag for locked object */
	LOCKMASK	holdMask;		/* locks held by this PGPROC */
	LOCKMODE	waitLockMode;	/* lock awaited by this PGPROC, if any */
	BackendId	backend;		/* backend ID of this PGPROC */
	LocalTransactionId lxid;	/* local transaction ID of this PGPROC */
	TimestampTz waitStart;		/* time at which this PGPROC started waiting
								 * for lock */
	int			pid;			/* pid of this PGPROC */
	int			leaderPid;		/* pid of group leader; = pid if no group */
	bool		fastpath;		/* taken via fastpath? */
} LockInstanceData;

typedef struct LockData
{
	int			nelements;		/* The length of the array */
	LockInstanceData *locks;	/* Array of per-PROCLOCK information */
} LockData;

typedef struct BlockedProcData
{
	int			pid;			/* pid of a blocked PGPROC */
	/* Per-PROCLOCK information about PROCLOCKs of the lock the pid awaits */
	/* (these fields refer to indexes in BlockedProcsData.locks[]) */
	int			first_lock;		/* index of first relevant LockInstanceData */
	int			num_locks;		/* number of relevant LockInstanceDatas */
	/* PIDs of PGPROCs that are ahead of "pid" in the lock's wait queue */
	/* (these fields refer to indexes in BlockedProcsData.waiter_pids[]) */
	int			first_waiter;	/* index of first preceding waiter */
	int			num_waiters;	/* number of preceding waiters */
} BlockedProcData;

typedef struct BlockedProcsData
{
	BlockedProcData *procs;		/* Array of per-blocked-proc information */
	LockInstanceData *locks;	/* Array of per-PROCLOCK information */
	int		   *waiter_pids;	/* Array of PIDs of other blocked PGPROCs */
	int			nprocs;			/* # of valid entries in procs[] array */
	int			maxprocs;		/* Allocated length of procs[] array */
	int			nlocks;			/* # of valid entries in locks[] array */
	int			maxlocks;		/* Allocated length of locks[] array */
	int			npids;			/* # of valid entries in waiter_pids[] array */
	int			maxpids;		/* Allocated length of waiter_pids[] array */
} BlockedProcsData;


/* Result codes for LockAcquire() */
typedef enum
{
	LOCKACQUIRE_NOT_AVAIL,		/* lock not available, and dontWait=true */
	LOCKACQUIRE_OK,				/* lock successfully acquired */
	LOCKACQUIRE_ALREADY_HELD,	/* incremented count for lock already held */
	LOCKACQUIRE_ALREADY_CLEAR	/* incremented count for lock already clear */
} LockAcquireResult;

/* Deadlock states identified by DeadLockCheck() */
typedef enum
{
	DS_NOT_YET_CHECKED,			/* no deadlock check has run yet */
	DS_NO_DEADLOCK,				/* no deadlock detected */
	DS_SOFT_DEADLOCK,			/* deadlock avoided by queue rearrangement */
	DS_HARD_DEADLOCK,			/* deadlock, no way out but ERROR */
	DS_BLOCKED_BY_AUTOVACUUM	/* no deadlock; queue blocked by autovacuum
								 * worker */
} DeadLockState;

/*
 * The lockmgr's shared hash tables are partitioned to reduce contention.
 * To determine which partition a given locktag belongs to, compute the tag's
 * hash code with LockTagHashCode(), then apply one of these macros.
 * NB: NUM_LOCK_PARTITIONS must be a power of 2!
 */
#define LockHashPartition(hashcode) \
	((hashcode) % NUM_LOCK_PARTITIONS)
#define LockHashPartitionLock(hashcode) \
	(&MainLWLockArray[LOCK_MANAGER_LWLOCK_OFFSET + \
		LockHashPartition(hashcode)].lock)
#define LockHashPartitionLockByIndex(i) \
	(&MainLWLockArray[LOCK_MANAGER_LWLOCK_OFFSET + (i)].lock)

/*
 * The deadlock detector needs to be able to access lockGroupLeader and
 * related fields in the PGPROC, so we arrange for those fields to be protected
 * by one of the lock hash partition locks.  Since the deadlock detector
 * acquires all such locks anyway, this makes it safe for it to access these
 * fields without doing anything extra.  To avoid contention as much as
 * possible, we map different PGPROCs to different partition locks.  The lock
 * used for a given lock group is determined by the group leader's pgprocno.
 */
#define LockHashPartitionLockByProc(leader_pgproc) \
	LockHashPartitionLock((leader_pgproc)->pgprocno)

/*
 * function prototypes
 */
extern void InitLocks(void);
extern LockMethod GetLocksMethodTable(const LOCK *lock);
extern LockMethod GetLockTagsMethodTable(const LOCKTAG *locktag);
extern uint32 LockTagHashCode(const LOCKTAG *locktag);
extern bool DoLockModesConflict(LOCKMODE mode1, LOCKMODE mode2);
extern LockAcquireResult LockAcquire(const LOCKTAG *locktag,
									 LOCKMODE lockmode,
									 bool sessionLock,
									 bool dontWait);
extern LockAcquireResult LockAcquireExtended(const LOCKTAG *locktag,
											 LOCKMODE lockmode,
											 bool sessionLock,
											 bool dontWait,
											 bool reportMemoryError,
											 LOCALLOCK **locallockp);
extern void AbortStrongLockAcquire(void);
extern void MarkLockClear(LOCALLOCK *locallock);
extern bool LockRelease(const LOCKTAG *locktag,
						LOCKMODE lockmode, bool sessionLock);
extern void LockReleaseAll(LOCKMETHODID lockmethodid, bool allLocks);
extern void LockReleaseSession(LOCKMETHODID lockmethodid);
extern void LockReleaseCurrentOwner(LOCALLOCK **locallocks, int nlocks);
extern void LockReassignCurrentOwner(LOCALLOCK **locallocks, int nlocks);
extern bool LockHeldByMe(const LOCKTAG *locktag, LOCKMODE lockmode);
#ifdef USE_ASSERT_CHECKING
extern HTAB *GetLockMethodLocalHash(void);
#endif
extern bool LockHasWaiters(const LOCKTAG *locktag,
						   LOCKMODE lockmode, bool sessionLock);
extern VirtualTransactionId *GetLockConflicts(const LOCKTAG *locktag,
											  LOCKMODE lockmode, int *countp);
extern void AtPrepare_Locks(void);
extern void PostPrepare_Locks(TransactionId xid);
extern bool LockCheckConflicts(LockMethod lockMethodTable,
							   LOCKMODE lockmode,
							   LOCK *lock, PROCLOCK *proclock);
extern void GrantLock(LOCK *lock, PROCLOCK *proclock, LOCKMODE lockmode);
extern void GrantAwaitedLock(void);
extern void RemoveFromWaitQueue(PGPROC *proc, uint32 hashcode);
extern Size LockShmemSize(void);
extern LockData *GetLockStatusData(void);
extern BlockedProcsData *GetBlockerStatusData(int blocked_pid);

extern xl_standby_lock *GetRunningTransactionLocks(int *nlocks);
extern const char *GetLockmodeName(LOCKMETHODID lockmethodid, LOCKMODE mode);

extern void lock_twophase_recover(TransactionId xid, uint16 info,
								  void *recdata, uint32 len);
extern void lock_twophase_postcommit(TransactionId xid, uint16 info,
									 void *recdata, uint32 len);
extern void lock_twophase_postabort(TransactionId xid, uint16 info,
									void *recdata, uint32 len);
extern void lock_twophase_standby_recover(TransactionId xid, uint16 info,
										  void *recdata, uint32 len);

extern DeadLockState DeadLockCheck(PGPROC *proc);
extern PGPROC *GetBlockingAutoVacuumPgproc(void);
extern void DeadLockReport(void) pg_attribute_noreturn();
extern void RememberSimpleDeadLock(PGPROC *proc1,
								   LOCKMODE lockmode,
								   LOCK *lock,
								   PGPROC *proc2);
extern void InitDeadLockChecking(void);

extern int	LockWaiterCount(const LOCKTAG *locktag);

#ifdef LOCK_DEBUG
extern void DumpLocks(PGPROC *proc);
extern void DumpAllLocks(void);
#endif

/* Lock a VXID (used to wait for a transaction to finish) */
extern void VirtualXactLockTableInsert(VirtualTransactionId vxid);
extern void VirtualXactLockTableCleanup(void);
extern bool VirtualXactLock(VirtualTransactionId vxid, bool wait);

#endif							/* LOCK_H_ */
