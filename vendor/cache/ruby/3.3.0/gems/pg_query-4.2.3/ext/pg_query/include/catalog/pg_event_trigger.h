/*-------------------------------------------------------------------------
 *
 * pg_event_trigger.h
 *	  definition of the "event trigger" system catalog (pg_event_trigger)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_event_trigger.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_EVENT_TRIGGER_H
#define PG_EVENT_TRIGGER_H

#include "catalog/genbki.h"
#include "catalog/pg_event_trigger_d.h"

/* ----------------
 *		pg_event_trigger definition.    cpp turns this into
 *		typedef struct FormData_pg_event_trigger
 * ----------------
 */
CATALOG(pg_event_trigger,3466,EventTriggerRelationId)
{
	Oid			oid;			/* oid */
	NameData	evtname;		/* trigger's name */
	NameData	evtevent;		/* trigger's event */
	Oid			evtowner BKI_LOOKUP(pg_authid); /* trigger's owner */
	Oid			evtfoid BKI_LOOKUP(pg_proc);	/* OID of function to be
												 * called */
	char		evtenabled;		/* trigger's firing configuration WRT
								 * session_replication_role */

#ifdef CATALOG_VARLEN
	text		evttags[1];		/* command TAGs this event trigger targets */
#endif
} FormData_pg_event_trigger;

/* ----------------
 *		Form_pg_event_trigger corresponds to a pointer to a tuple with
 *		the format of pg_event_trigger relation.
 * ----------------
 */
typedef FormData_pg_event_trigger *Form_pg_event_trigger;

DECLARE_TOAST(pg_event_trigger, 4145, 4146);

DECLARE_UNIQUE_INDEX(pg_event_trigger_evtname_index, 3467, EventTriggerNameIndexId, on pg_event_trigger using btree(evtname name_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_event_trigger_oid_index, 3468, EventTriggerOidIndexId, on pg_event_trigger using btree(oid oid_ops));

#endif							/* PG_EVENT_TRIGGER_H */
