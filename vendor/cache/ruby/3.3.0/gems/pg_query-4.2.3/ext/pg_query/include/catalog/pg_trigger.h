/*-------------------------------------------------------------------------
 *
 * pg_trigger.h
 *	  definition of the "trigger" system catalog (pg_trigger)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_trigger.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_TRIGGER_H
#define PG_TRIGGER_H

#include "catalog/genbki.h"
#include "catalog/pg_trigger_d.h"

/* ----------------
 *		pg_trigger definition.  cpp turns this into
 *		typedef struct FormData_pg_trigger
 *
 * Note: when tgconstraint is nonzero, tgconstrrelid, tgconstrindid,
 * tgdeferrable, and tginitdeferred are largely redundant with the referenced
 * pg_constraint entry.  However, it is possible for a non-deferrable trigger
 * to be associated with a deferrable constraint.
 * ----------------
 */
CATALOG(pg_trigger,2620,TriggerRelationId)
{
	Oid			oid;			/* oid */
	Oid			tgrelid BKI_LOOKUP(pg_class);	/* relation trigger is
												 * attached to */
	Oid			tgparentid BKI_LOOKUP_OPT(pg_trigger);	/* OID of parent
														 * trigger, if any */
	NameData	tgname;			/* trigger's name */
	Oid			tgfoid BKI_LOOKUP(pg_proc); /* OID of function to be called */
	int16		tgtype;			/* BEFORE/AFTER/INSTEAD, UPDATE/DELETE/INSERT,
								 * ROW/STATEMENT; see below */
	char		tgenabled;		/* trigger's firing configuration WRT
								 * session_replication_role */
	bool		tgisinternal;	/* trigger is system-generated */
	Oid			tgconstrrelid BKI_LOOKUP_OPT(pg_class); /* constraint's FROM
														 * table, if any */
	Oid			tgconstrindid BKI_LOOKUP_OPT(pg_class); /* constraint's
														 * supporting index, if
														 * any */
	Oid			tgconstraint BKI_LOOKUP_OPT(pg_constraint); /* associated
															 * pg_constraint entry,
															 * if any */
	bool		tgdeferrable;	/* constraint trigger is deferrable */
	bool		tginitdeferred; /* constraint trigger is deferred initially */
	int16		tgnargs;		/* # of extra arguments in tgargs */

	/*
	 * Variable-length fields start here, but we allow direct access to
	 * tgattr. Note: tgattr and tgargs must not be null.
	 */
	int2vector	tgattr BKI_FORCE_NOT_NULL;	/* column numbers, if trigger is
											 * on columns */

#ifdef CATALOG_VARLEN
	bytea		tgargs BKI_FORCE_NOT_NULL;	/* first\000second\000tgnargs\000 */
	pg_node_tree tgqual;		/* WHEN expression, or NULL if none */
	NameData	tgoldtable;		/* old transition table, or NULL if none */
	NameData	tgnewtable;		/* new transition table, or NULL if none */
#endif
} FormData_pg_trigger;

/* ----------------
 *		Form_pg_trigger corresponds to a pointer to a tuple with
 *		the format of pg_trigger relation.
 * ----------------
 */
typedef FormData_pg_trigger *Form_pg_trigger;

DECLARE_TOAST(pg_trigger, 2336, 2337);

DECLARE_INDEX(pg_trigger_tgconstraint_index, 2699, TriggerConstraintIndexId, on pg_trigger using btree(tgconstraint oid_ops));
DECLARE_UNIQUE_INDEX(pg_trigger_tgrelid_tgname_index, 2701, TriggerRelidNameIndexId, on pg_trigger using btree(tgrelid oid_ops, tgname name_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_trigger_oid_index, 2702, TriggerOidIndexId, on pg_trigger using btree(oid oid_ops));

DECLARE_ARRAY_FOREIGN_KEY((tgrelid, tgattr), pg_attribute, (attrelid, attnum));

#ifdef EXPOSE_TO_CLIENT_CODE

/* Bits within tgtype */
#define TRIGGER_TYPE_ROW				(1 << 0)
#define TRIGGER_TYPE_BEFORE				(1 << 1)
#define TRIGGER_TYPE_INSERT				(1 << 2)
#define TRIGGER_TYPE_DELETE				(1 << 3)
#define TRIGGER_TYPE_UPDATE				(1 << 4)
#define TRIGGER_TYPE_TRUNCATE			(1 << 5)
#define TRIGGER_TYPE_INSTEAD			(1 << 6)

#define TRIGGER_TYPE_LEVEL_MASK			(TRIGGER_TYPE_ROW)
#define TRIGGER_TYPE_STATEMENT			0

/* Note bits within TRIGGER_TYPE_TIMING_MASK aren't adjacent */
#define TRIGGER_TYPE_TIMING_MASK \
	(TRIGGER_TYPE_BEFORE | TRIGGER_TYPE_INSTEAD)
#define TRIGGER_TYPE_AFTER				0

#define TRIGGER_TYPE_EVENT_MASK \
	(TRIGGER_TYPE_INSERT | TRIGGER_TYPE_DELETE | TRIGGER_TYPE_UPDATE | TRIGGER_TYPE_TRUNCATE)

/* Macros for manipulating tgtype */
#define TRIGGER_CLEAR_TYPE(type)		((type) = 0)

#define TRIGGER_SETT_ROW(type)			((type) |= TRIGGER_TYPE_ROW)
#define TRIGGER_SETT_STATEMENT(type)	((type) |= TRIGGER_TYPE_STATEMENT)
#define TRIGGER_SETT_BEFORE(type)		((type) |= TRIGGER_TYPE_BEFORE)
#define TRIGGER_SETT_AFTER(type)		((type) |= TRIGGER_TYPE_AFTER)
#define TRIGGER_SETT_INSTEAD(type)		((type) |= TRIGGER_TYPE_INSTEAD)
#define TRIGGER_SETT_INSERT(type)		((type) |= TRIGGER_TYPE_INSERT)
#define TRIGGER_SETT_DELETE(type)		((type) |= TRIGGER_TYPE_DELETE)
#define TRIGGER_SETT_UPDATE(type)		((type) |= TRIGGER_TYPE_UPDATE)
#define TRIGGER_SETT_TRUNCATE(type)		((type) |= TRIGGER_TYPE_TRUNCATE)

#define TRIGGER_FOR_ROW(type)			((type) & TRIGGER_TYPE_ROW)
#define TRIGGER_FOR_BEFORE(type)		(((type) & TRIGGER_TYPE_TIMING_MASK) == TRIGGER_TYPE_BEFORE)
#define TRIGGER_FOR_AFTER(type)			(((type) & TRIGGER_TYPE_TIMING_MASK) == TRIGGER_TYPE_AFTER)
#define TRIGGER_FOR_INSTEAD(type)		(((type) & TRIGGER_TYPE_TIMING_MASK) == TRIGGER_TYPE_INSTEAD)
#define TRIGGER_FOR_INSERT(type)		((type) & TRIGGER_TYPE_INSERT)
#define TRIGGER_FOR_DELETE(type)		((type) & TRIGGER_TYPE_DELETE)
#define TRIGGER_FOR_UPDATE(type)		((type) & TRIGGER_TYPE_UPDATE)
#define TRIGGER_FOR_TRUNCATE(type)		((type) & TRIGGER_TYPE_TRUNCATE)

/*
 * Efficient macro for checking if tgtype matches a particular level
 * (TRIGGER_TYPE_ROW or TRIGGER_TYPE_STATEMENT), timing (TRIGGER_TYPE_BEFORE,
 * TRIGGER_TYPE_AFTER or TRIGGER_TYPE_INSTEAD), and event (TRIGGER_TYPE_INSERT,
 * TRIGGER_TYPE_DELETE, TRIGGER_TYPE_UPDATE, or TRIGGER_TYPE_TRUNCATE).  Note
 * that a tgtype can match more than one event, but only one level or timing.
 */
#define TRIGGER_TYPE_MATCHES(type, level, timing, event) \
	(((type) & (TRIGGER_TYPE_LEVEL_MASK | TRIGGER_TYPE_TIMING_MASK | (event))) == ((level) | (timing) | (event)))

/*
 * Macro to determine whether tgnewtable or tgoldtable has been specified for
 * a trigger.
 */
#define TRIGGER_USES_TRANSITION_TABLE(namepointer) \
	((namepointer) != (char *) NULL)

#endif							/* EXPOSE_TO_CLIENT_CODE */

#endif							/* PG_TRIGGER_H */
