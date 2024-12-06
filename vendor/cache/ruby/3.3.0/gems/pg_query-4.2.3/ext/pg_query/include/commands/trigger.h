/*-------------------------------------------------------------------------
 *
 * trigger.h
 *	  Declarations for trigger handling.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/trigger.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TRIGGER_H
#define TRIGGER_H

#include "access/tableam.h"
#include "catalog/objectaddress.h"
#include "nodes/execnodes.h"
#include "nodes/parsenodes.h"

/*
 * TriggerData is the node type that is passed as fmgr "context" info
 * when a function is called by the trigger manager.
 */

#define CALLED_AS_TRIGGER(fcinfo) \
	((fcinfo)->context != NULL && IsA((fcinfo)->context, TriggerData))

typedef uint32 TriggerEvent;

typedef struct TriggerData
{
	NodeTag		type;
	TriggerEvent tg_event;
	Relation	tg_relation;
	HeapTuple	tg_trigtuple;
	HeapTuple	tg_newtuple;
	Trigger    *tg_trigger;
	TupleTableSlot *tg_trigslot;
	TupleTableSlot *tg_newslot;
	Tuplestorestate *tg_oldtable;
	Tuplestorestate *tg_newtable;
	const Bitmapset *tg_updatedcols;
} TriggerData;

/*
 * The state for capturing old and new tuples into transition tables for a
 * single ModifyTable node (or other operation source, e.g. copyfrom.c).
 *
 * This is per-caller to avoid conflicts in setting
 * tcs_original_insert_tuple.  Note, however, that the pointed-to
 * private data may be shared across multiple callers.
 */
struct AfterTriggersTableData;	/* private in trigger.c */

typedef struct TransitionCaptureState
{
	/*
	 * Is there at least one trigger specifying each transition relation on
	 * the relation explicitly named in the DML statement or COPY command?
	 * Note: in current usage, these flags could be part of the private state,
	 * but it seems possibly useful to let callers see them.
	 */
	bool		tcs_delete_old_table;
	bool		tcs_update_old_table;
	bool		tcs_update_new_table;
	bool		tcs_insert_new_table;

	/*
	 * For INSERT and COPY, it would be wasteful to convert tuples from child
	 * format to parent format after they have already been converted in the
	 * opposite direction during routing.  In that case we bypass conversion
	 * and allow the inserting code (copyfrom.c and nodeModifyTable.c) to
	 * provide a slot containing the original tuple directly.
	 */
	TupleTableSlot *tcs_original_insert_tuple;

	/*
	 * Private data including the tuplestore(s) into which to insert tuples.
	 */
	struct AfterTriggersTableData *tcs_private;
} TransitionCaptureState;

/*
 * TriggerEvent bit flags
 *
 * Note that we assume different event types (INSERT/DELETE/UPDATE/TRUNCATE)
 * can't be OR'd together in a single TriggerEvent.  This is unlike the
 * situation for pg_trigger rows, so pg_trigger.tgtype uses a different
 * representation!
 */
#define TRIGGER_EVENT_INSERT			0x00000000
#define TRIGGER_EVENT_DELETE			0x00000001
#define TRIGGER_EVENT_UPDATE			0x00000002
#define TRIGGER_EVENT_TRUNCATE			0x00000003
#define TRIGGER_EVENT_OPMASK			0x00000003

#define TRIGGER_EVENT_ROW				0x00000004

#define TRIGGER_EVENT_BEFORE			0x00000008
#define TRIGGER_EVENT_AFTER				0x00000000
#define TRIGGER_EVENT_INSTEAD			0x00000010
#define TRIGGER_EVENT_TIMINGMASK		0x00000018

/* More TriggerEvent flags, used only within trigger.c */

#define AFTER_TRIGGER_DEFERRABLE		0x00000020
#define AFTER_TRIGGER_INITDEFERRED		0x00000040

#define TRIGGER_FIRED_BY_INSERT(event) \
	(((event) & TRIGGER_EVENT_OPMASK) == TRIGGER_EVENT_INSERT)

#define TRIGGER_FIRED_BY_DELETE(event) \
	(((event) & TRIGGER_EVENT_OPMASK) == TRIGGER_EVENT_DELETE)

#define TRIGGER_FIRED_BY_UPDATE(event) \
	(((event) & TRIGGER_EVENT_OPMASK) == TRIGGER_EVENT_UPDATE)

#define TRIGGER_FIRED_BY_TRUNCATE(event) \
	(((event) & TRIGGER_EVENT_OPMASK) == TRIGGER_EVENT_TRUNCATE)

#define TRIGGER_FIRED_FOR_ROW(event) \
	((event) & TRIGGER_EVENT_ROW)

#define TRIGGER_FIRED_FOR_STATEMENT(event) \
	(!TRIGGER_FIRED_FOR_ROW(event))

#define TRIGGER_FIRED_BEFORE(event) \
	(((event) & TRIGGER_EVENT_TIMINGMASK) == TRIGGER_EVENT_BEFORE)

#define TRIGGER_FIRED_AFTER(event) \
	(((event) & TRIGGER_EVENT_TIMINGMASK) == TRIGGER_EVENT_AFTER)

#define TRIGGER_FIRED_INSTEAD(event) \
	(((event) & TRIGGER_EVENT_TIMINGMASK) == TRIGGER_EVENT_INSTEAD)

/*
 * Definitions for replication role based firing.
 */
#define SESSION_REPLICATION_ROLE_ORIGIN		0
#define SESSION_REPLICATION_ROLE_REPLICA	1
#define SESSION_REPLICATION_ROLE_LOCAL		2
extern PGDLLIMPORT int SessionReplicationRole;

/*
 * States at which a trigger can be fired. These are the
 * possible values for pg_trigger.tgenabled.
 */
#define TRIGGER_FIRES_ON_ORIGIN				'O'
#define TRIGGER_FIRES_ALWAYS				'A'
#define TRIGGER_FIRES_ON_REPLICA			'R'
#define TRIGGER_DISABLED					'D'

extern ObjectAddress CreateTrigger(CreateTrigStmt *stmt, const char *queryString,
								   Oid relOid, Oid refRelOid, Oid constraintOid, Oid indexOid,
								   Oid funcoid, Oid parentTriggerOid, Node *whenClause,
								   bool isInternal, bool in_partition);
extern ObjectAddress CreateTriggerFiringOn(CreateTrigStmt *stmt, const char *queryString,
										   Oid relOid, Oid refRelOid, Oid constraintOid,
										   Oid indexOid, Oid funcoid, Oid parentTriggerOid,
										   Node *whenClause, bool isInternal, bool in_partition,
										   char trigger_fires_when);

extern void TriggerSetParentTrigger(Relation trigRel,
									Oid childTrigId,
									Oid parentTrigId,
									Oid childTableId);
extern void RemoveTriggerById(Oid trigOid);
extern Oid	get_trigger_oid(Oid relid, const char *name, bool missing_ok);

extern ObjectAddress renametrig(RenameStmt *stmt);

extern void EnableDisableTriggerNew(Relation rel, const char *tgname,
									char fires_when, bool skip_system, bool recurse,
									LOCKMODE lockmode);
extern void EnableDisableTrigger(Relation rel, const char *tgname,
								 char fires_when, bool skip_system, LOCKMODE lockmode);

extern void RelationBuildTriggers(Relation relation);

extern TriggerDesc *CopyTriggerDesc(TriggerDesc *trigdesc);

extern const char *FindTriggerIncompatibleWithInheritance(TriggerDesc *trigdesc);

extern TransitionCaptureState *MakeTransitionCaptureState(TriggerDesc *trigdesc,
														  Oid relid, CmdType cmdType);

extern void FreeTriggerDesc(TriggerDesc *trigdesc);

extern void ExecBSInsertTriggers(EState *estate,
								 ResultRelInfo *relinfo);
extern void ExecASInsertTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TransitionCaptureState *transition_capture);
extern bool ExecBRInsertTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TupleTableSlot *slot);
extern void ExecARInsertTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TupleTableSlot *slot,
								 List *recheckIndexes,
								 TransitionCaptureState *transition_capture);
extern bool ExecIRInsertTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TupleTableSlot *slot);
extern void ExecBSDeleteTriggers(EState *estate,
								 ResultRelInfo *relinfo);
extern void ExecASDeleteTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TransitionCaptureState *transition_capture);
extern bool ExecBRDeleteTriggers(EState *estate,
								 EPQState *epqstate,
								 ResultRelInfo *relinfo,
								 ItemPointer tupleid,
								 HeapTuple fdw_trigtuple,
								 TupleTableSlot **epqslot);
extern void ExecARDeleteTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 ItemPointer tupleid,
								 HeapTuple fdw_trigtuple,
								 TransitionCaptureState *transition_capture,
								 bool is_crosspart_update);
extern bool ExecIRDeleteTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 HeapTuple trigtuple);
extern void ExecBSUpdateTriggers(EState *estate,
								 ResultRelInfo *relinfo);
extern void ExecASUpdateTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 TransitionCaptureState *transition_capture);
extern bool ExecBRUpdateTriggers(EState *estate,
								 EPQState *epqstate,
								 ResultRelInfo *relinfo,
								 ItemPointer tupleid,
								 HeapTuple fdw_trigtuple,
								 TupleTableSlot *slot,
								 TM_FailureData *tmfdp);
extern void ExecARUpdateTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 ResultRelInfo *src_partinfo,
								 ResultRelInfo *dst_partinfo,
								 ItemPointer tupleid,
								 HeapTuple fdw_trigtuple,
								 TupleTableSlot *slot,
								 List *recheckIndexes,
								 TransitionCaptureState *transition_capture,
								 bool is_crosspart_update);
extern bool ExecIRUpdateTriggers(EState *estate,
								 ResultRelInfo *relinfo,
								 HeapTuple trigtuple,
								 TupleTableSlot *slot);
extern void ExecBSTruncateTriggers(EState *estate,
								   ResultRelInfo *relinfo);
extern void ExecASTruncateTriggers(EState *estate,
								   ResultRelInfo *relinfo);

extern void AfterTriggerBeginXact(void);
extern void AfterTriggerBeginQuery(void);
extern void AfterTriggerEndQuery(EState *estate);
extern void AfterTriggerFireDeferred(void);
extern void AfterTriggerEndXact(bool isCommit);
extern void AfterTriggerBeginSubXact(void);
extern void AfterTriggerEndSubXact(bool isCommit);
extern void AfterTriggerSetState(ConstraintsSetStmt *stmt);
extern bool AfterTriggerPendingOnRel(Oid relid);


/*
 * in utils/adt/ri_triggers.c
 */
extern bool RI_FKey_pk_upd_check_required(Trigger *trigger, Relation pk_rel,
										  TupleTableSlot *old_slot, TupleTableSlot *new_slot);
extern bool RI_FKey_fk_upd_check_required(Trigger *trigger, Relation fk_rel,
										  TupleTableSlot *old_slot, TupleTableSlot *new_slot);
extern bool RI_Initial_Check(Trigger *trigger,
							 Relation fk_rel, Relation pk_rel);
extern void RI_PartitionRemove_Check(Trigger *trigger, Relation fk_rel,
									 Relation pk_rel);

/* result values for RI_FKey_trigger_type: */
#define RI_TRIGGER_PK	1		/* is a trigger on the PK relation */
#define RI_TRIGGER_FK	2		/* is a trigger on the FK relation */
#define RI_TRIGGER_NONE 0		/* is not an RI trigger function */

extern int	RI_FKey_trigger_type(Oid tgfoid);

#endif							/* TRIGGER_H */
