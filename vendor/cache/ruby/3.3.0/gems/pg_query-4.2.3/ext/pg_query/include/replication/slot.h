/*-------------------------------------------------------------------------
 * slot.h
 *	   Replication slot management.
 *
 * Copyright (c) 2012-2022, PostgreSQL Global Development Group
 *
 *-------------------------------------------------------------------------
 */
#ifndef SLOT_H
#define SLOT_H

#include "access/xlog.h"
#include "access/xlogreader.h"
#include "storage/condition_variable.h"
#include "storage/lwlock.h"
#include "storage/shmem.h"
#include "storage/spin.h"
#include "replication/walreceiver.h"

/*
 * Behaviour of replication slots, upon release or crash.
 *
 * Slots marked as PERSISTENT are crash-safe and will not be dropped when
 * released. Slots marked as EPHEMERAL will be dropped when released or after
 * restarts.  Slots marked TEMPORARY will be dropped at the end of a session
 * or on error.
 *
 * EPHEMERAL is used as a not-quite-ready state when creating persistent
 * slots.  EPHEMERAL slots can be made PERSISTENT by calling
 * ReplicationSlotPersist().  For a slot that goes away at the end of a
 * session, TEMPORARY is the appropriate choice.
 */
typedef enum ReplicationSlotPersistency
{
	RS_PERSISTENT,
	RS_EPHEMERAL,
	RS_TEMPORARY
} ReplicationSlotPersistency;

/*
 * On-Disk data of a replication slot, preserved across restarts.
 */
typedef struct ReplicationSlotPersistentData
{
	/* The slot's identifier */
	NameData	name;

	/* database the slot is active on */
	Oid			database;

	/*
	 * The slot's behaviour when being dropped (or restored after a crash).
	 */
	ReplicationSlotPersistency persistency;

	/*
	 * xmin horizon for data
	 *
	 * NB: This may represent a value that hasn't been written to disk yet;
	 * see notes for effective_xmin, below.
	 */
	TransactionId xmin;

	/*
	 * xmin horizon for catalog tuples
	 *
	 * NB: This may represent a value that hasn't been written to disk yet;
	 * see notes for effective_xmin, below.
	 */
	TransactionId catalog_xmin;

	/* oldest LSN that might be required by this replication slot */
	XLogRecPtr	restart_lsn;

	/* restart_lsn is copied here when the slot is invalidated */
	XLogRecPtr	invalidated_at;

	/*
	 * Oldest LSN that the client has acked receipt for.  This is used as the
	 * start_lsn point in case the client doesn't specify one, and also as a
	 * safety measure to jump forwards in case the client specifies a
	 * start_lsn that's further in the past than this value.
	 */
	XLogRecPtr	confirmed_flush;

	/*
	 * LSN at which we enabled two_phase commit for this slot or LSN at which
	 * we found a consistent point at the time of slot creation.
	 */
	XLogRecPtr	two_phase_at;

	/*
	 * Allow decoding of prepared transactions?
	 */
	bool		two_phase;

	/* plugin name */
	NameData	plugin;
} ReplicationSlotPersistentData;

/*
 * Shared memory state of a single replication slot.
 *
 * The in-memory data of replication slots follows a locking model based
 * on two linked concepts:
 * - A replication slot's in_use flag is switched when added or discarded using
 * the LWLock ReplicationSlotControlLock, which needs to be hold in exclusive
 * mode when updating the flag by the backend owning the slot and doing the
 * operation, while readers (concurrent backends not owning the slot) need
 * to hold it in shared mode when looking at replication slot data.
 * - Individual fields are protected by mutex where only the backend owning
 * the slot is authorized to update the fields from its own slot.  The
 * backend owning the slot does not need to take this lock when reading its
 * own fields, while concurrent backends not owning this slot should take the
 * lock when reading this slot's data.
 */
typedef struct ReplicationSlot
{
	/* lock, on same cacheline as effective_xmin */
	slock_t		mutex;

	/* is this slot defined */
	bool		in_use;

	/* Who is streaming out changes for this slot? 0 in unused slots. */
	pid_t		active_pid;

	/* any outstanding modifications? */
	bool		just_dirtied;
	bool		dirty;

	/*
	 * For logical decoding, it's extremely important that we never remove any
	 * data that's still needed for decoding purposes, even after a crash;
	 * otherwise, decoding will produce wrong answers.  Ordinary streaming
	 * replication also needs to prevent old row versions from being removed
	 * too soon, but the worst consequence we might encounter there is
	 * unwanted query cancellations on the standby.  Thus, for logical
	 * decoding, this value represents the latest xmin that has actually been
	 * written to disk, whereas for streaming replication, it's just the same
	 * as the persistent value (data.xmin).
	 */
	TransactionId effective_xmin;
	TransactionId effective_catalog_xmin;

	/* data surviving shutdowns and crashes */
	ReplicationSlotPersistentData data;

	/* is somebody performing io on this slot? */
	LWLock		io_in_progress_lock;

	/* Condition variable signaled when active_pid changes */
	ConditionVariable active_cv;

	/* all the remaining data is only used for logical slots */

	/*
	 * When the client has confirmed flushes >= candidate_xmin_lsn we can
	 * advance the catalog xmin.  When restart_valid has been passed,
	 * restart_lsn can be increased.
	 */
	TransactionId candidate_catalog_xmin;
	XLogRecPtr	candidate_xmin_lsn;
	XLogRecPtr	candidate_restart_valid;
	XLogRecPtr	candidate_restart_lsn;
} ReplicationSlot;

#define SlotIsPhysical(slot) ((slot)->data.database == InvalidOid)
#define SlotIsLogical(slot) ((slot)->data.database != InvalidOid)

/*
 * Shared memory control area for all of replication slots.
 */
typedef struct ReplicationSlotCtlData
{
	/*
	 * This array should be declared [FLEXIBLE_ARRAY_MEMBER], but for some
	 * reason you can't do that in an otherwise-empty struct.
	 */
	ReplicationSlot replication_slots[1];
} ReplicationSlotCtlData;

/*
 * Pointers to shared memory
 */
extern PGDLLIMPORT ReplicationSlotCtlData *ReplicationSlotCtl;
extern PGDLLIMPORT ReplicationSlot *MyReplicationSlot;

/* GUCs */
extern PGDLLIMPORT int max_replication_slots;

/* shmem initialization functions */
extern Size ReplicationSlotsShmemSize(void);
extern void ReplicationSlotsShmemInit(void);

/* management of individual slots */
extern void ReplicationSlotCreate(const char *name, bool db_specific,
								  ReplicationSlotPersistency p, bool two_phase);
extern void ReplicationSlotPersist(void);
extern void ReplicationSlotDrop(const char *name, bool nowait);

extern void ReplicationSlotAcquire(const char *name, bool nowait);
extern void ReplicationSlotRelease(void);
extern void ReplicationSlotCleanup(void);
extern void ReplicationSlotSave(void);
extern void ReplicationSlotMarkDirty(void);

/* misc stuff */
extern void ReplicationSlotInitialize(void);
extern bool ReplicationSlotValidateName(const char *name, int elevel);
extern void ReplicationSlotReserveWal(void);
extern void ReplicationSlotsComputeRequiredXmin(bool already_locked);
extern void ReplicationSlotsComputeRequiredLSN(void);
extern XLogRecPtr ReplicationSlotsComputeLogicalRestartLSN(void);
extern bool ReplicationSlotsCountDBSlots(Oid dboid, int *nslots, int *nactive);
extern void ReplicationSlotsDropDBSlots(Oid dboid);
extern bool InvalidateObsoleteReplicationSlots(XLogSegNo oldestSegno);
extern ReplicationSlot *SearchNamedReplicationSlot(const char *name, bool need_lock);
extern int	ReplicationSlotIndex(ReplicationSlot *slot);
extern bool ReplicationSlotName(int index, Name name);
extern void ReplicationSlotNameForTablesync(Oid suboid, Oid relid, char *syncslotname, int szslot);
extern void ReplicationSlotDropAtPubNode(WalReceiverConn *wrconn, char *slotname, bool missing_ok);

extern void StartupReplicationSlots(void);
extern void CheckPointReplicationSlots(void);

extern void CheckSlotRequirements(void);
extern void CheckSlotPermissions(void);

#endif							/* SLOT_H */
