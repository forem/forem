/*-------------------------------------------------------------------------
 *
 * tuplesort.h
 *	  Generalized tuple sorting routines.
 *
 * This module handles sorting of heap tuples, index tuples, or single
 * Datums (and could easily support other kinds of sortable objects,
 * if necessary).  It works efficiently for both small and large amounts
 * of data.  Small amounts are sorted in-memory using qsort().  Large
 * amounts are sorted using temporary files and a standard external sort
 * algorithm.  Parallel sorts use a variant of this external sort
 * algorithm, and are typically only used for large amounts of data.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/tuplesort.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TUPLESORT_H
#define TUPLESORT_H

#include "access/itup.h"
#include "executor/tuptable.h"
#include "storage/dsm.h"
#include "utils/relcache.h"


/*
 * Tuplesortstate and Sharedsort are opaque types whose details are not
 * known outside tuplesort.c.
 */
typedef struct Tuplesortstate Tuplesortstate;
typedef struct Sharedsort Sharedsort;

/*
 * Tuplesort parallel coordination state, allocated by each participant in
 * local memory.  Participant caller initializes everything.  See usage notes
 * below.
 */
typedef struct SortCoordinateData
{
	/* Worker process?  If not, must be leader. */
	bool		isWorker;

	/*
	 * Leader-process-passed number of participants known launched (workers
	 * set this to -1).  Includes state within leader needed for it to
	 * participate as a worker, if any.
	 */
	int			nParticipants;

	/* Private opaque state (points to shared memory) */
	Sharedsort *sharedsort;
}			SortCoordinateData;

typedef struct SortCoordinateData *SortCoordinate;

/*
 * Data structures for reporting sort statistics.  Note that
 * TuplesortInstrumentation can't contain any pointers because we
 * sometimes put it in shared memory.
 *
 * The parallel-sort infrastructure relies on having a zero TuplesortMethod
 * to indicate that a worker never did anything, so we assign zero to
 * SORT_TYPE_STILL_IN_PROGRESS.  The other values of this enum can be
 * OR'ed together to represent a situation where different workers used
 * different methods, so we need a separate bit for each one.  Keep the
 * NUM_TUPLESORTMETHODS constant in sync with the number of bits!
 */
typedef enum
{
	SORT_TYPE_STILL_IN_PROGRESS = 0,
	SORT_TYPE_TOP_N_HEAPSORT = 1 << 0,
	SORT_TYPE_QUICKSORT = 1 << 1,
	SORT_TYPE_EXTERNAL_SORT = 1 << 2,
	SORT_TYPE_EXTERNAL_MERGE = 1 << 3
} TuplesortMethod;

#define NUM_TUPLESORTMETHODS 4

typedef enum
{
	SORT_SPACE_TYPE_DISK,
	SORT_SPACE_TYPE_MEMORY
} TuplesortSpaceType;

/* Bitwise option flags for tuple sorts */
#define TUPLESORT_NONE					0

/* specifies whether non-sequential access to the sort result is required */
#define	TUPLESORT_RANDOMACCESS			(1 << 0)

/* specifies if the tuplesort is able to support bounded sorts */
#define TUPLESORT_ALLOWBOUNDED			(1 << 1)

typedef struct TuplesortInstrumentation
{
	TuplesortMethod sortMethod; /* sort algorithm used */
	TuplesortSpaceType spaceType;	/* type of space spaceUsed represents */
	int64		spaceUsed;		/* space consumption, in kB */
} TuplesortInstrumentation;


/*
 * We provide multiple interfaces to what is essentially the same code,
 * since different callers have different data to be sorted and want to
 * specify the sort key information differently.  There are two APIs for
 * sorting HeapTuples and two more for sorting IndexTuples.  Yet another
 * API supports sorting bare Datums.
 *
 * Serial sort callers should pass NULL for their coordinate argument.
 *
 * The "heap" API actually stores/sorts MinimalTuples, which means it doesn't
 * preserve the system columns (tuple identity and transaction visibility
 * info).  The sort keys are specified by column numbers within the tuples
 * and sort operator OIDs.  We save some cycles by passing and returning the
 * tuples in TupleTableSlots, rather than forming actual HeapTuples (which'd
 * have to be converted to MinimalTuples).  This API works well for sorts
 * executed as parts of plan trees.
 *
 * The "cluster" API stores/sorts full HeapTuples including all visibility
 * info. The sort keys are specified by reference to a btree index that is
 * defined on the relation to be sorted.  Note that putheaptuple/getheaptuple
 * go with this API, not the "begin_heap" one!
 *
 * The "index_btree" API stores/sorts IndexTuples (preserving all their
 * header fields).  The sort keys are specified by a btree index definition.
 *
 * The "index_hash" API is similar to index_btree, but the tuples are
 * actually sorted by their hash codes not the raw data.
 *
 * Parallel sort callers are required to coordinate multiple tuplesort states
 * in a leader process and one or more worker processes.  The leader process
 * must launch workers, and have each perform an independent "partial"
 * tuplesort, typically fed by the parallel heap interface.  The leader later
 * produces the final output (internally, it merges runs output by workers).
 *
 * Callers must do the following to perform a sort in parallel using multiple
 * worker processes:
 *
 * 1. Request tuplesort-private shared memory for n workers.  Use
 *    tuplesort_estimate_shared() to get the required size.
 * 2. Have leader process initialize allocated shared memory using
 *    tuplesort_initialize_shared().  Launch workers.
 * 3. Initialize a coordinate argument within both the leader process, and
 *    for each worker process.  This has a pointer to the shared
 *    tuplesort-private structure, as well as some caller-initialized fields.
 *    Leader's coordinate argument reliably indicates number of workers
 *    launched (this is unused by workers).
 * 4. Begin a tuplesort using some appropriate tuplesort_begin* routine,
 *    (passing the coordinate argument) within each worker.  The workMem
 *    arguments need not be identical.  All other arguments should match
 *    exactly, though.
 * 5. tuplesort_attach_shared() should be called by all workers.  Feed tuples
 *    to each worker, and call tuplesort_performsort() within each when input
 *    is exhausted.
 * 6. Call tuplesort_end() in each worker process.  Worker processes can shut
 *    down once tuplesort_end() returns.
 * 7. Begin a tuplesort in the leader using the same tuplesort_begin*
 *    routine, passing a leader-appropriate coordinate argument (this can
 *    happen as early as during step 3, actually, since we only need to know
 *    the number of workers successfully launched).  The leader must now wait
 *    for workers to finish.  Caller must use own mechanism for ensuring that
 *    next step isn't reached until all workers have called and returned from
 *    tuplesort_performsort().  (Note that it's okay if workers have already
 *    also called tuplesort_end() by then.)
 * 8. Call tuplesort_performsort() in leader.  Consume output using the
 *    appropriate tuplesort_get* routine.  Leader can skip this step if
 *    tuplesort turns out to be unnecessary.
 * 9. Call tuplesort_end() in leader.
 *
 * This division of labor assumes nothing about how input tuples are produced,
 * but does require that caller combine the state of multiple tuplesorts for
 * any purpose other than producing the final output.  For example, callers
 * must consider that tuplesort_get_stats() reports on only one worker's role
 * in a sort (or the leader's role), and not statistics for the sort as a
 * whole.
 *
 * Note that callers may use the leader process to sort runs as if it was an
 * independent worker process (prior to the process performing a leader sort
 * to produce the final sorted output).  Doing so only requires a second
 * "partial" tuplesort within the leader process, initialized like that of a
 * worker process.  The steps above don't touch on this directly.  The only
 * difference is that the tuplesort_attach_shared() call is never needed within
 * leader process, because the backend as a whole holds the shared fileset
 * reference.  A worker Tuplesortstate in leader is expected to do exactly the
 * same amount of total initial processing work as a worker process
 * Tuplesortstate, since the leader process has nothing else to do before
 * workers finish.
 *
 * Note that only a very small amount of memory will be allocated prior to
 * the leader state first consuming input, and that workers will free the
 * vast majority of their memory upon returning from tuplesort_performsort().
 * Callers can rely on this to arrange for memory to be used in a way that
 * respects a workMem-style budget across an entire parallel sort operation.
 *
 * Callers are responsible for parallel safety in general.  However, they
 * can at least rely on there being no parallel safety hazards within
 * tuplesort, because tuplesort thinks of the sort as several independent
 * sorts whose results are combined.  Since, in general, the behavior of
 * sort operators is immutable, caller need only worry about the parallel
 * safety of whatever the process is through which input tuples are
 * generated (typically, caller uses a parallel heap scan).
 */

extern Tuplesortstate *tuplesort_begin_heap(TupleDesc tupDesc,
											int nkeys, AttrNumber *attNums,
											Oid *sortOperators, Oid *sortCollations,
											bool *nullsFirstFlags,
											int workMem, SortCoordinate coordinate,
											int sortopt);
extern Tuplesortstate *tuplesort_begin_cluster(TupleDesc tupDesc,
											   Relation indexRel, int workMem,
											   SortCoordinate coordinate,
											   int sortopt);
extern Tuplesortstate *tuplesort_begin_index_btree(Relation heapRel,
												   Relation indexRel,
												   bool enforceUnique,
												   bool uniqueNullsNotDistinct,
												   int workMem, SortCoordinate coordinate,
												   int sortopt);
extern Tuplesortstate *tuplesort_begin_index_hash(Relation heapRel,
												  Relation indexRel,
												  uint32 high_mask,
												  uint32 low_mask,
												  uint32 max_buckets,
												  int workMem, SortCoordinate coordinate,
												  int sortopt);
extern Tuplesortstate *tuplesort_begin_index_gist(Relation heapRel,
												  Relation indexRel,
												  int workMem, SortCoordinate coordinate,
												  int sortopt);
extern Tuplesortstate *tuplesort_begin_datum(Oid datumType,
											 Oid sortOperator, Oid sortCollation,
											 bool nullsFirstFlag,
											 int workMem, SortCoordinate coordinate,
											 int sortopt);

extern void tuplesort_set_bound(Tuplesortstate *state, int64 bound);
extern bool tuplesort_used_bound(Tuplesortstate *state);

extern void tuplesort_puttupleslot(Tuplesortstate *state,
								   TupleTableSlot *slot);
extern void tuplesort_putheaptuple(Tuplesortstate *state, HeapTuple tup);
extern void tuplesort_putindextuplevalues(Tuplesortstate *state,
										  Relation rel, ItemPointer self,
										  Datum *values, bool *isnull);
extern void tuplesort_putdatum(Tuplesortstate *state, Datum val,
							   bool isNull);

extern void tuplesort_performsort(Tuplesortstate *state);

extern bool tuplesort_gettupleslot(Tuplesortstate *state, bool forward,
								   bool copy, TupleTableSlot *slot, Datum *abbrev);
extern HeapTuple tuplesort_getheaptuple(Tuplesortstate *state, bool forward);
extern IndexTuple tuplesort_getindextuple(Tuplesortstate *state, bool forward);
extern bool tuplesort_getdatum(Tuplesortstate *state, bool forward,
							   Datum *val, bool *isNull, Datum *abbrev);

extern bool tuplesort_skiptuples(Tuplesortstate *state, int64 ntuples,
								 bool forward);

extern void tuplesort_end(Tuplesortstate *state);

extern void tuplesort_reset(Tuplesortstate *state);

extern void tuplesort_get_stats(Tuplesortstate *state,
								TuplesortInstrumentation *stats);
extern const char *tuplesort_method_name(TuplesortMethod m);
extern const char *tuplesort_space_type_name(TuplesortSpaceType t);

extern int	tuplesort_merge_order(int64 allowedMem);

extern Size tuplesort_estimate_shared(int nworkers);
extern void tuplesort_initialize_shared(Sharedsort *shared, int nWorkers,
										dsm_segment *seg);
extern void tuplesort_attach_shared(Sharedsort *shared, dsm_segment *seg);

/*
 * These routines may only be called if TUPLESORT_RANDOMACCESS was specified
 * during tuplesort_begin_*.  Additionally backwards scan in gettuple/getdatum
 * also require TUPLESORT_RANDOMACCESS.  Note that parallel sorts do not
 * support random access.
 */
extern void tuplesort_rescan(Tuplesortstate *state);
extern void tuplesort_markpos(Tuplesortstate *state);
extern void tuplesort_restorepos(Tuplesortstate *state);

#endif							/* TUPLESORT_H */
