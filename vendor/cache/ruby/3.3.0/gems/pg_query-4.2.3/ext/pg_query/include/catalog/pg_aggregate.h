/*-------------------------------------------------------------------------
 *
 * pg_aggregate.h
 *	  definition of the "aggregate" system catalog (pg_aggregate)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_aggregate.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_AGGREGATE_H
#define PG_AGGREGATE_H

#include "catalog/genbki.h"
#include "catalog/pg_aggregate_d.h"

#include "catalog/objectaddress.h"
#include "nodes/pg_list.h"

/* ----------------------------------------------------------------
 *		pg_aggregate definition.
 *		cpp turns this into typedef struct FormData_pg_aggregate
 * ----------------------------------------------------------------
 */
CATALOG(pg_aggregate,2600,AggregateRelationId)
{
	/* pg_proc OID of the aggregate itself */
	regproc		aggfnoid BKI_LOOKUP(pg_proc);

	/* aggregate kind, see AGGKIND_ categories below */
	char		aggkind BKI_DEFAULT(n);

	/* number of arguments that are "direct" arguments */
	int16		aggnumdirectargs BKI_DEFAULT(0);

	/* transition function */
	regproc		aggtransfn BKI_LOOKUP(pg_proc);

	/* final function (0 if none) */
	regproc		aggfinalfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* combine function (0 if none) */
	regproc		aggcombinefn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* function to convert transtype to bytea (0 if none) */
	regproc		aggserialfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* function to convert bytea to transtype (0 if none) */
	regproc		aggdeserialfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* forward function for moving-aggregate mode (0 if none) */
	regproc		aggmtransfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* inverse function for moving-aggregate mode (0 if none) */
	regproc		aggminvtransfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* final function for moving-aggregate mode (0 if none) */
	regproc		aggmfinalfn BKI_DEFAULT(-) BKI_LOOKUP_OPT(pg_proc);

	/* true to pass extra dummy arguments to aggfinalfn */
	bool		aggfinalextra BKI_DEFAULT(f);

	/* true to pass extra dummy arguments to aggmfinalfn */
	bool		aggmfinalextra BKI_DEFAULT(f);

	/* tells whether aggfinalfn modifies transition state */
	char		aggfinalmodify BKI_DEFAULT(r);

	/* tells whether aggmfinalfn modifies transition state */
	char		aggmfinalmodify BKI_DEFAULT(r);

	/* associated sort operator (0 if none) */
	Oid			aggsortop BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_operator);

	/* type of aggregate's transition (state) data */
	Oid			aggtranstype BKI_LOOKUP(pg_type);

	/* estimated size of state data (0 for default estimate) */
	int32		aggtransspace BKI_DEFAULT(0);

	/* type of moving-aggregate state data (0 if none) */
	Oid			aggmtranstype BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_type);

	/* estimated size of moving-agg state (0 for default est) */
	int32		aggmtransspace BKI_DEFAULT(0);

#ifdef CATALOG_VARLEN			/* variable-length fields start here */

	/* initial value for transition state (can be NULL) */
	text		agginitval BKI_DEFAULT(_null_);

	/* initial value for moving-agg state (can be NULL) */
	text		aggminitval BKI_DEFAULT(_null_);
#endif
} FormData_pg_aggregate;

/* ----------------
 *		Form_pg_aggregate corresponds to a pointer to a tuple with
 *		the format of pg_aggregate relation.
 * ----------------
 */
typedef FormData_pg_aggregate *Form_pg_aggregate;

DECLARE_TOAST(pg_aggregate, 4159, 4160);

DECLARE_UNIQUE_INDEX_PKEY(pg_aggregate_fnoid_index, 2650, AggregateFnoidIndexId, on pg_aggregate using btree(aggfnoid oid_ops));

#ifdef EXPOSE_TO_CLIENT_CODE

/*
 * Symbolic values for aggkind column.  We distinguish normal aggregates
 * from ordered-set aggregates (which have two sets of arguments, namely
 * direct and aggregated arguments) and from hypothetical-set aggregates
 * (which are a subclass of ordered-set aggregates in which the last
 * direct arguments have to match up in number and datatypes with the
 * aggregated arguments).
 */
#define AGGKIND_NORMAL			'n'
#define AGGKIND_ORDERED_SET		'o'
#define AGGKIND_HYPOTHETICAL	'h'

/* Use this macro to test for "ordered-set agg including hypothetical case" */
#define AGGKIND_IS_ORDERED_SET(kind)  ((kind) != AGGKIND_NORMAL)

/*
 * Symbolic values for aggfinalmodify and aggmfinalmodify columns.
 * Preferably, finalfns do not modify the transition state value at all,
 * but in some cases that would cost too much performance.  We distinguish
 * "pure read only" and "trashes it arbitrarily" cases, as well as the
 * intermediate case where multiple finalfn calls are allowed but the
 * transfn cannot be applied anymore after the first finalfn call.
 */
#define AGGMODIFY_READ_ONLY			'r'
#define AGGMODIFY_SHAREABLE			's'
#define AGGMODIFY_READ_WRITE		'w'

#endif							/* EXPOSE_TO_CLIENT_CODE */


extern ObjectAddress AggregateCreate(const char *aggName,
									 Oid aggNamespace,
									 bool replace,
									 char aggKind,
									 int numArgs,
									 int numDirectArgs,
									 oidvector *parameterTypes,
									 Datum allParameterTypes,
									 Datum parameterModes,
									 Datum parameterNames,
									 List *parameterDefaults,
									 Oid variadicArgType,
									 List *aggtransfnName,
									 List *aggfinalfnName,
									 List *aggcombinefnName,
									 List *aggserialfnName,
									 List *aggdeserialfnName,
									 List *aggmtransfnName,
									 List *aggminvtransfnName,
									 List *aggmfinalfnName,
									 bool finalfnExtraArgs,
									 bool mfinalfnExtraArgs,
									 char finalfnModify,
									 char mfinalfnModify,
									 List *aggsortopName,
									 Oid aggTransType,
									 int32 aggTransSpace,
									 Oid aggmTransType,
									 int32 aggmTransSpace,
									 const char *agginitval,
									 const char *aggminitval,
									 char proparallel);

#endif							/* PG_AGGREGATE_H */
