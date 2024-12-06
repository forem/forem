/*
 * reorderbuffer.h
 *	  PostgreSQL logical replay/reorder buffer management.
 *
 * Copyright (c) 2012-2022, PostgreSQL Global Development Group
 *
 * src/include/replication/reorderbuffer.h
 */
#ifndef REORDERBUFFER_H
#define REORDERBUFFER_H

#include "access/htup_details.h"
#include "lib/ilist.h"
#include "storage/sinval.h"
#include "utils/hsearch.h"
#include "utils/relcache.h"
#include "utils/snapshot.h"
#include "utils/timestamp.h"

extern PGDLLIMPORT int logical_decoding_work_mem;

/* an individual tuple, stored in one chunk of memory */
typedef struct ReorderBufferTupleBuf
{
	/* position in preallocated list */
	slist_node	node;

	/* tuple header, the interesting bit for users of logical decoding */
	HeapTupleData tuple;

	/* pre-allocated size of tuple buffer, different from tuple size */
	Size		alloc_tuple_size;

	/* actual tuple data follows */
} ReorderBufferTupleBuf;

/* pointer to the data stored in a TupleBuf */
#define ReorderBufferTupleBufData(p) \
	((HeapTupleHeader) MAXALIGN(((char *) p) + sizeof(ReorderBufferTupleBuf)))

/*
 * Types of the change passed to a 'change' callback.
 *
 * For efficiency and simplicity reasons we want to keep Snapshots, CommandIds
 * and ComboCids in the same list with the user visible INSERT/UPDATE/DELETE
 * changes. Users of the decoding facilities will never see changes with
 * *_INTERNAL_* actions.
 *
 * The INTERNAL_SPEC_INSERT and INTERNAL_SPEC_CONFIRM, and INTERNAL_SPEC_ABORT
 * changes concern "speculative insertions", their confirmation, and abort
 * respectively.  They're used by INSERT .. ON CONFLICT .. UPDATE.  Users of
 * logical decoding don't have to care about these.
 */
typedef enum ReorderBufferChangeType
{
	REORDER_BUFFER_CHANGE_INSERT,
	REORDER_BUFFER_CHANGE_UPDATE,
	REORDER_BUFFER_CHANGE_DELETE,
	REORDER_BUFFER_CHANGE_MESSAGE,
	REORDER_BUFFER_CHANGE_INVALIDATION,
	REORDER_BUFFER_CHANGE_INTERNAL_SNAPSHOT,
	REORDER_BUFFER_CHANGE_INTERNAL_COMMAND_ID,
	REORDER_BUFFER_CHANGE_INTERNAL_TUPLECID,
	REORDER_BUFFER_CHANGE_INTERNAL_SPEC_INSERT,
	REORDER_BUFFER_CHANGE_INTERNAL_SPEC_CONFIRM,
	REORDER_BUFFER_CHANGE_INTERNAL_SPEC_ABORT,
	REORDER_BUFFER_CHANGE_TRUNCATE
} ReorderBufferChangeType;

/* forward declaration */
struct ReorderBufferTXN;

/*
 * a single 'change', can be an insert (with one tuple), an update (old, new),
 * or a delete (old).
 *
 * The same struct is also used internally for other purposes but that should
 * never be visible outside reorderbuffer.c.
 */
typedef struct ReorderBufferChange
{
	XLogRecPtr	lsn;

	/* The type of change. */
	ReorderBufferChangeType action;

	/* Transaction this change belongs to. */
	struct ReorderBufferTXN *txn;

	RepOriginId origin_id;

	/*
	 * Context data for the change. Which part of the union is valid depends
	 * on action.
	 */
	union
	{
		/* Old, new tuples when action == *_INSERT|UPDATE|DELETE */
		struct
		{
			/* relation that has been changed */
			RelFileNode relnode;

			/* no previously reassembled toast chunks are necessary anymore */
			bool		clear_toast_afterwards;

			/* valid for DELETE || UPDATE */
			ReorderBufferTupleBuf *oldtuple;
			/* valid for INSERT || UPDATE */
			ReorderBufferTupleBuf *newtuple;
		}			tp;

		/*
		 * Truncate data for REORDER_BUFFER_CHANGE_TRUNCATE representing one
		 * set of relations to be truncated.
		 */
		struct
		{
			Size		nrelids;
			bool		cascade;
			bool		restart_seqs;
			Oid		   *relids;
		}			truncate;

		/* Message with arbitrary data. */
		struct
		{
			char	   *prefix;
			Size		message_size;
			char	   *message;
		}			msg;

		/* New snapshot, set when action == *_INTERNAL_SNAPSHOT */
		Snapshot	snapshot;

		/*
		 * New command id for existing snapshot in a catalog changing tx. Set
		 * when action == *_INTERNAL_COMMAND_ID.
		 */
		CommandId	command_id;

		/*
		 * New cid mapping for catalog changing transaction, set when action
		 * == *_INTERNAL_TUPLECID.
		 */
		struct
		{
			RelFileNode node;
			ItemPointerData tid;
			CommandId	cmin;
			CommandId	cmax;
			CommandId	combocid;
		}			tuplecid;

		/* Invalidation. */
		struct
		{
			uint32		ninvalidations; /* Number of messages */
			SharedInvalidationMessage *invalidations;	/* invalidation message */
		}			inval;
	}			data;

	/*
	 * While in use this is how a change is linked into a transactions,
	 * otherwise it's the preallocated list.
	 */
	dlist_node	node;
} ReorderBufferChange;

/* ReorderBufferTXN txn_flags */
#define RBTXN_HAS_CATALOG_CHANGES 0x0001
#define RBTXN_IS_SUBXACT          0x0002
#define RBTXN_IS_SERIALIZED       0x0004
#define RBTXN_IS_SERIALIZED_CLEAR 0x0008
#define RBTXN_IS_STREAMED         0x0010
#define RBTXN_HAS_PARTIAL_CHANGE  0x0020
#define RBTXN_PREPARE             0x0040
#define RBTXN_SKIPPED_PREPARE	  0x0080

/* Does the transaction have catalog changes? */
#define rbtxn_has_catalog_changes(txn) \
( \
	 ((txn)->txn_flags & RBTXN_HAS_CATALOG_CHANGES) != 0 \
)

/* Is the transaction known as a subxact? */
#define rbtxn_is_known_subxact(txn) \
( \
	((txn)->txn_flags & RBTXN_IS_SUBXACT) != 0 \
)

/* Has this transaction been spilled to disk? */
#define rbtxn_is_serialized(txn) \
( \
	((txn)->txn_flags & RBTXN_IS_SERIALIZED) != 0 \
)

/* Has this transaction ever been spilled to disk? */
#define rbtxn_is_serialized_clear(txn) \
( \
	((txn)->txn_flags & RBTXN_IS_SERIALIZED_CLEAR) != 0 \
)

/* Has this transaction contains partial changes? */
#define rbtxn_has_partial_change(txn) \
( \
	((txn)->txn_flags & RBTXN_HAS_PARTIAL_CHANGE) != 0 \
)

/*
 * Has this transaction been streamed to downstream?
 *
 * (It's not possible to deduce this from nentries and nentries_mem for
 * various reasons. For example, all changes may be in subtransactions in
 * which case we'd have nentries==0 for the toplevel one, which would say
 * nothing about the streaming. So we maintain this flag, but only for the
 * toplevel transaction.)
 */
#define rbtxn_is_streamed(txn) \
( \
	((txn)->txn_flags & RBTXN_IS_STREAMED) != 0 \
)

/* Has this transaction been prepared? */
#define rbtxn_prepared(txn) \
( \
	((txn)->txn_flags & RBTXN_PREPARE) != 0 \
)

/* prepare for this transaction skipped? */
#define rbtxn_skip_prepared(txn) \
( \
	((txn)->txn_flags & RBTXN_SKIPPED_PREPARE) != 0 \
)

typedef struct ReorderBufferTXN
{
	/* See above */
	bits32		txn_flags;

	/* The transaction's transaction id, can be a toplevel or sub xid. */
	TransactionId xid;

	/* Xid of top-level transaction, if known */
	TransactionId toplevel_xid;

	/*
	 * Global transaction id required for identification of prepared
	 * transactions.
	 */
	char	   *gid;

	/*
	 * LSN of the first data carrying, WAL record with knowledge about this
	 * xid. This is allowed to *not* be first record adorned with this xid, if
	 * the previous records aren't relevant for logical decoding.
	 */
	XLogRecPtr	first_lsn;

	/* ----
	 * LSN of the record that lead to this xact to be prepared or committed or
	 * aborted. This can be a
	 * * plain commit record
	 * * plain commit record, of a parent transaction
	 * * prepared tansaction
	 * * prepared transaction commit
	 * * plain abort record
	 * * prepared transaction abort
	 *
	 * This can also become set to earlier values than transaction end when
	 * a transaction is spilled to disk; specifically it's set to the LSN of
	 * the latest change written to disk so far.
	 * ----
	 */
	XLogRecPtr	final_lsn;

	/*
	 * LSN pointing to the end of the commit record + 1.
	 */
	XLogRecPtr	end_lsn;

	/* Toplevel transaction for this subxact (NULL for top-level). */
	struct ReorderBufferTXN *toptxn;

	/*
	 * LSN of the last lsn at which snapshot information reside, so we can
	 * restart decoding from there and fully recover this transaction from
	 * WAL.
	 */
	XLogRecPtr	restart_decoding_lsn;

	/* origin of the change that caused this transaction */
	RepOriginId origin_id;
	XLogRecPtr	origin_lsn;

	/*
	 * Commit or Prepare time, only known when we read the actual commit or
	 * prepare record.
	 */
	union
	{
		TimestampTz commit_time;
		TimestampTz prepare_time;
	}			xact_time;

	/*
	 * The base snapshot is used to decode all changes until either this
	 * transaction modifies the catalog, or another catalog-modifying
	 * transaction commits.
	 */
	Snapshot	base_snapshot;
	XLogRecPtr	base_snapshot_lsn;
	dlist_node	base_snapshot_node; /* link in txns_by_base_snapshot_lsn */

	/*
	 * Snapshot/CID from the previous streaming run. Only valid for already
	 * streamed transactions (NULL/InvalidCommandId otherwise).
	 */
	Snapshot	snapshot_now;
	CommandId	command_id;

	/*
	 * How many ReorderBufferChange's do we have in this txn.
	 *
	 * Changes in subtransactions are *not* included but tracked separately.
	 */
	uint64		nentries;

	/*
	 * How many of the above entries are stored in memory in contrast to being
	 * spilled to disk.
	 */
	uint64		nentries_mem;

	/*
	 * List of ReorderBufferChange structs, including new Snapshots, new
	 * CommandIds and command invalidation messages.
	 */
	dlist_head	changes;

	/*
	 * List of (relation, ctid) => (cmin, cmax) mappings for catalog tuples.
	 * Those are always assigned to the toplevel transaction. (Keep track of
	 * #entries to create a hash of the right size)
	 */
	dlist_head	tuplecids;
	uint64		ntuplecids;

	/*
	 * On-demand built hash for looking up the above values.
	 */
	HTAB	   *tuplecid_hash;

	/*
	 * Hash containing (potentially partial) toast entries. NULL if no toast
	 * tuples have been found for the current change.
	 */
	HTAB	   *toast_hash;

	/*
	 * non-hierarchical list of subtransactions that are *not* aborted. Only
	 * used in toplevel transactions.
	 */
	dlist_head	subtxns;
	uint32		nsubtxns;

	/*
	 * Stored cache invalidations. This is not a linked list because we get
	 * all the invalidations at once.
	 */
	uint32		ninvalidations;
	SharedInvalidationMessage *invalidations;

	/* ---
	 * Position in one of three lists:
	 * * list of subtransactions if we are *known* to be subxact
	 * * list of toplevel xacts (can be an as-yet unknown subxact)
	 * * list of preallocated ReorderBufferTXNs (if unused)
	 * ---
	 */
	dlist_node	node;

	/*
	 * Size of this transaction (changes currently in memory, in bytes).
	 */
	Size		size;

	/* Size of top-transaction including sub-transactions. */
	Size		total_size;

	/* If we have detected concurrent abort then ignore future changes. */
	bool		concurrent_abort;

	/*
	 * Private data pointer of the output plugin.
	 */
	void	   *output_plugin_private;
} ReorderBufferTXN;

/* so we can define the callbacks used inside struct ReorderBuffer itself */
typedef struct ReorderBuffer ReorderBuffer;

/* change callback signature */
typedef void (*ReorderBufferApplyChangeCB) (ReorderBuffer *rb,
											ReorderBufferTXN *txn,
											Relation relation,
											ReorderBufferChange *change);

/* truncate callback signature */
typedef void (*ReorderBufferApplyTruncateCB) (ReorderBuffer *rb,
											  ReorderBufferTXN *txn,
											  int nrelations,
											  Relation relations[],
											  ReorderBufferChange *change);

/* begin callback signature */
typedef void (*ReorderBufferBeginCB) (ReorderBuffer *rb,
									  ReorderBufferTXN *txn);

/* commit callback signature */
typedef void (*ReorderBufferCommitCB) (ReorderBuffer *rb,
									   ReorderBufferTXN *txn,
									   XLogRecPtr commit_lsn);

/* message callback signature */
typedef void (*ReorderBufferMessageCB) (ReorderBuffer *rb,
										ReorderBufferTXN *txn,
										XLogRecPtr message_lsn,
										bool transactional,
										const char *prefix, Size sz,
										const char *message);

/* begin prepare callback signature */
typedef void (*ReorderBufferBeginPrepareCB) (ReorderBuffer *rb,
											 ReorderBufferTXN *txn);

/* prepare callback signature */
typedef void (*ReorderBufferPrepareCB) (ReorderBuffer *rb,
										ReorderBufferTXN *txn,
										XLogRecPtr prepare_lsn);

/* commit prepared callback signature */
typedef void (*ReorderBufferCommitPreparedCB) (ReorderBuffer *rb,
											   ReorderBufferTXN *txn,
											   XLogRecPtr commit_lsn);

/* rollback  prepared callback signature */
typedef void (*ReorderBufferRollbackPreparedCB) (ReorderBuffer *rb,
												 ReorderBufferTXN *txn,
												 XLogRecPtr prepare_end_lsn,
												 TimestampTz prepare_time);

/* start streaming transaction callback signature */
typedef void (*ReorderBufferStreamStartCB) (
											ReorderBuffer *rb,
											ReorderBufferTXN *txn,
											XLogRecPtr first_lsn);

/* stop streaming transaction callback signature */
typedef void (*ReorderBufferStreamStopCB) (
										   ReorderBuffer *rb,
										   ReorderBufferTXN *txn,
										   XLogRecPtr last_lsn);

/* discard streamed transaction callback signature */
typedef void (*ReorderBufferStreamAbortCB) (
											ReorderBuffer *rb,
											ReorderBufferTXN *txn,
											XLogRecPtr abort_lsn);

/* prepare streamed transaction callback signature */
typedef void (*ReorderBufferStreamPrepareCB) (
											  ReorderBuffer *rb,
											  ReorderBufferTXN *txn,
											  XLogRecPtr prepare_lsn);

/* commit streamed transaction callback signature */
typedef void (*ReorderBufferStreamCommitCB) (
											 ReorderBuffer *rb,
											 ReorderBufferTXN *txn,
											 XLogRecPtr commit_lsn);

/* stream change callback signature */
typedef void (*ReorderBufferStreamChangeCB) (
											 ReorderBuffer *rb,
											 ReorderBufferTXN *txn,
											 Relation relation,
											 ReorderBufferChange *change);

/* stream message callback signature */
typedef void (*ReorderBufferStreamMessageCB) (
											  ReorderBuffer *rb,
											  ReorderBufferTXN *txn,
											  XLogRecPtr message_lsn,
											  bool transactional,
											  const char *prefix, Size sz,
											  const char *message);

/* stream truncate callback signature */
typedef void (*ReorderBufferStreamTruncateCB) (
											   ReorderBuffer *rb,
											   ReorderBufferTXN *txn,
											   int nrelations,
											   Relation relations[],
											   ReorderBufferChange *change);

struct ReorderBuffer
{
	/*
	 * xid => ReorderBufferTXN lookup table
	 */
	HTAB	   *by_txn;

	/*
	 * Transactions that could be a toplevel xact, ordered by LSN of the first
	 * record bearing that xid.
	 */
	dlist_head	toplevel_by_lsn;

	/*
	 * Transactions and subtransactions that have a base snapshot, ordered by
	 * LSN of the record which caused us to first obtain the base snapshot.
	 * This is not the same as toplevel_by_lsn, because we only set the base
	 * snapshot on the first logical-decoding-relevant record (eg. heap
	 * writes), whereas the initial LSN could be set by other operations.
	 */
	dlist_head	txns_by_base_snapshot_lsn;

	/*
	 * one-entry sized cache for by_txn. Very frequently the same txn gets
	 * looked up over and over again.
	 */
	TransactionId by_txn_last_xid;
	ReorderBufferTXN *by_txn_last_txn;

	/*
	 * Callbacks to be called when a transactions commits.
	 */
	ReorderBufferBeginCB begin;
	ReorderBufferApplyChangeCB apply_change;
	ReorderBufferApplyTruncateCB apply_truncate;
	ReorderBufferCommitCB commit;
	ReorderBufferMessageCB message;

	/*
	 * Callbacks to be called when streaming a transaction at prepare time.
	 */
	ReorderBufferBeginCB begin_prepare;
	ReorderBufferPrepareCB prepare;
	ReorderBufferCommitPreparedCB commit_prepared;
	ReorderBufferRollbackPreparedCB rollback_prepared;

	/*
	 * Callbacks to be called when streaming a transaction.
	 */
	ReorderBufferStreamStartCB stream_start;
	ReorderBufferStreamStopCB stream_stop;
	ReorderBufferStreamAbortCB stream_abort;
	ReorderBufferStreamPrepareCB stream_prepare;
	ReorderBufferStreamCommitCB stream_commit;
	ReorderBufferStreamChangeCB stream_change;
	ReorderBufferStreamMessageCB stream_message;
	ReorderBufferStreamTruncateCB stream_truncate;

	/*
	 * Pointer that will be passed untouched to the callbacks.
	 */
	void	   *private_data;

	/*
	 * Saved output plugin option
	 */
	bool		output_rewrites;

	/*
	 * Private memory context.
	 */
	MemoryContext context;

	/*
	 * Memory contexts for specific types objects
	 */
	MemoryContext change_context;
	MemoryContext txn_context;
	MemoryContext tup_context;

	XLogRecPtr	current_restart_decoding_lsn;

	/* buffer for disk<->memory conversions */
	char	   *outbuf;
	Size		outbufsize;

	/* memory accounting */
	Size		size;

	/*
	 * Statistics about transactions spilled to disk.
	 *
	 * A single transaction may be spilled repeatedly, which is why we keep
	 * two different counters. For spilling, the transaction counter includes
	 * both toplevel transactions and subtransactions.
	 */
	int64		spillTxns;		/* number of transactions spilled to disk */
	int64		spillCount;		/* spill-to-disk invocation counter */
	int64		spillBytes;		/* amount of data spilled to disk */

	/* Statistics about transactions streamed to the decoding output plugin */
	int64		streamTxns;		/* number of transactions streamed */
	int64		streamCount;	/* streaming invocation counter */
	int64		streamBytes;	/* amount of data decoded */

	/*
	 * Statistics about all the transactions sent to the decoding output
	 * plugin
	 */
	int64		totalTxns;		/* total number of transactions sent */
	int64		totalBytes;		/* total amount of data decoded */
};


extern ReorderBuffer *ReorderBufferAllocate(void);
extern void ReorderBufferFree(ReorderBuffer *);

extern ReorderBufferTupleBuf *ReorderBufferGetTupleBuf(ReorderBuffer *, Size tuple_len);
extern void ReorderBufferReturnTupleBuf(ReorderBuffer *, ReorderBufferTupleBuf *tuple);
extern ReorderBufferChange *ReorderBufferGetChange(ReorderBuffer *);
extern void ReorderBufferReturnChange(ReorderBuffer *, ReorderBufferChange *, bool);

extern Oid *ReorderBufferGetRelids(ReorderBuffer *, int nrelids);
extern void ReorderBufferReturnRelids(ReorderBuffer *, Oid *relids);

extern void ReorderBufferQueueChange(ReorderBuffer *, TransactionId,
									 XLogRecPtr lsn, ReorderBufferChange *,
									 bool toast_insert);
extern void ReorderBufferQueueMessage(ReorderBuffer *, TransactionId, Snapshot snapshot, XLogRecPtr lsn,
									  bool transactional, const char *prefix,
									  Size message_size, const char *message);
extern void ReorderBufferCommit(ReorderBuffer *, TransactionId,
								XLogRecPtr commit_lsn, XLogRecPtr end_lsn,
								TimestampTz commit_time, RepOriginId origin_id, XLogRecPtr origin_lsn);
extern void ReorderBufferFinishPrepared(ReorderBuffer *rb, TransactionId xid,
										XLogRecPtr commit_lsn, XLogRecPtr end_lsn,
										XLogRecPtr two_phase_at,
										TimestampTz commit_time,
										RepOriginId origin_id, XLogRecPtr origin_lsn,
										char *gid, bool is_commit);
extern void ReorderBufferAssignChild(ReorderBuffer *, TransactionId, TransactionId, XLogRecPtr commit_lsn);
extern void ReorderBufferCommitChild(ReorderBuffer *, TransactionId, TransactionId,
									 XLogRecPtr commit_lsn, XLogRecPtr end_lsn);
extern void ReorderBufferAbort(ReorderBuffer *, TransactionId, XLogRecPtr lsn);
extern void ReorderBufferAbortOld(ReorderBuffer *, TransactionId xid);
extern void ReorderBufferForget(ReorderBuffer *, TransactionId, XLogRecPtr lsn);
extern void ReorderBufferInvalidate(ReorderBuffer *, TransactionId, XLogRecPtr lsn);

extern void ReorderBufferSetBaseSnapshot(ReorderBuffer *, TransactionId, XLogRecPtr lsn, struct SnapshotData *snap);
extern void ReorderBufferAddSnapshot(ReorderBuffer *, TransactionId, XLogRecPtr lsn, struct SnapshotData *snap);
extern void ReorderBufferAddNewCommandId(ReorderBuffer *, TransactionId, XLogRecPtr lsn,
										 CommandId cid);
extern void ReorderBufferAddNewTupleCids(ReorderBuffer *, TransactionId, XLogRecPtr lsn,
										 RelFileNode node, ItemPointerData pt,
										 CommandId cmin, CommandId cmax, CommandId combocid);
extern void ReorderBufferAddInvalidations(ReorderBuffer *, TransactionId, XLogRecPtr lsn,
										  Size nmsgs, SharedInvalidationMessage *msgs);
extern void ReorderBufferImmediateInvalidation(ReorderBuffer *, uint32 ninvalidations,
											   SharedInvalidationMessage *invalidations);
extern void ReorderBufferProcessXid(ReorderBuffer *, TransactionId xid, XLogRecPtr lsn);

extern void ReorderBufferXidSetCatalogChanges(ReorderBuffer *, TransactionId xid, XLogRecPtr lsn);
extern bool ReorderBufferXidHasCatalogChanges(ReorderBuffer *, TransactionId xid);
extern bool ReorderBufferXidHasBaseSnapshot(ReorderBuffer *, TransactionId xid);

extern bool ReorderBufferRememberPrepareInfo(ReorderBuffer *rb, TransactionId xid,
											 XLogRecPtr prepare_lsn, XLogRecPtr end_lsn,
											 TimestampTz prepare_time,
											 RepOriginId origin_id, XLogRecPtr origin_lsn);
extern void ReorderBufferSkipPrepare(ReorderBuffer *rb, TransactionId xid);
extern void ReorderBufferPrepare(ReorderBuffer *rb, TransactionId xid, char *gid);
extern ReorderBufferTXN *ReorderBufferGetOldestTXN(ReorderBuffer *);
extern TransactionId ReorderBufferGetOldestXmin(ReorderBuffer *rb);

extern void ReorderBufferSetRestartPoint(ReorderBuffer *, XLogRecPtr ptr);

extern void StartupReorderBuffer(void);

#endif
