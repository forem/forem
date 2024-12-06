/*-------------------------------------------------------------------------
 *
 * vacuum.h
 *	  header file for postgres vacuum cleaner and statistics analyzer
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/vacuum.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef VACUUM_H
#define VACUUM_H

#include "access/htup.h"
#include "access/genam.h"
#include "access/parallel.h"
#include "catalog/pg_class.h"
#include "catalog/pg_statistic.h"
#include "catalog/pg_type.h"
#include "parser/parse_node.h"
#include "storage/buf.h"
#include "storage/lock.h"
#include "utils/relcache.h"

/*
 * Flags for amparallelvacuumoptions to control the participation of bulkdelete
 * and vacuumcleanup in parallel vacuum.
 */

/*
 * Both bulkdelete and vacuumcleanup are disabled by default.  This will be
 * used by IndexAM's that don't want to or cannot participate in parallel
 * vacuum.  For example, if an index AM doesn't have a way to communicate the
 * index statistics allocated by the first ambulkdelete call to the subsequent
 * ones until amvacuumcleanup, the index AM cannot participate in parallel
 * vacuum.
 */
#define VACUUM_OPTION_NO_PARALLEL			0

/*
 * bulkdelete can be performed in parallel.  This option can be used by
 * index AMs that need to scan indexes to delete tuples.
 */
#define VACUUM_OPTION_PARALLEL_BULKDEL		(1 << 0)

/*
 * vacuumcleanup can be performed in parallel if bulkdelete is not performed
 * yet.  This will be used by IndexAM's that can scan the index if the
 * bulkdelete is not performed.
 */
#define VACUUM_OPTION_PARALLEL_COND_CLEANUP	(1 << 1)

/*
 * vacuumcleanup can be performed in parallel even if bulkdelete has already
 * processed the index.  This will be used by IndexAM's that scan the index
 * during the cleanup phase of index irrespective of whether the index is
 * already scanned or not during bulkdelete phase.
 */
#define VACUUM_OPTION_PARALLEL_CLEANUP		(1 << 2)

/* value for checking vacuum flags */
#define VACUUM_OPTION_MAX_VALID_VALUE		((1 << 3) - 1)

/* Abstract type for parallel vacuum state */
typedef struct ParallelVacuumState ParallelVacuumState;

/*----------
 * ANALYZE builds one of these structs for each attribute (column) that is
 * to be analyzed.  The struct and subsidiary data are in anl_context,
 * so they live until the end of the ANALYZE operation.
 *
 * The type-specific typanalyze function is passed a pointer to this struct
 * and must return true to continue analysis, false to skip analysis of this
 * column.  In the true case it must set the compute_stats and minrows fields,
 * and can optionally set extra_data to pass additional info to compute_stats.
 * minrows is its request for the minimum number of sample rows to be gathered
 * (but note this request might not be honored, eg if there are fewer rows
 * than that in the table).
 *
 * The compute_stats routine will be called after sample rows have been
 * gathered.  Aside from this struct, it is passed:
 *		fetchfunc: a function for accessing the column values from the
 *				   sample rows
 *		samplerows: the number of sample tuples
 *		totalrows: estimated total number of rows in relation
 * The fetchfunc may be called with rownum running from 0 to samplerows-1.
 * It returns a Datum and an isNull flag.
 *
 * compute_stats should set stats_valid true if it is able to compute
 * any useful statistics.  If it does, the remainder of the struct holds
 * the information to be stored in a pg_statistic row for the column.  Be
 * careful to allocate any pointed-to data in anl_context, which will NOT
 * be CurrentMemoryContext when compute_stats is called.
 *
 * Note: all comparisons done for statistical purposes should use the
 * underlying column's collation (attcollation), except in situations
 * where a noncollatable container type contains a collatable type;
 * in that case use the type's default collation.  Be sure to record
 * the appropriate collation in stacoll.
 *----------
 */
typedef struct VacAttrStats *VacAttrStatsP;

typedef Datum (*AnalyzeAttrFetchFunc) (VacAttrStatsP stats, int rownum,
									   bool *isNull);

typedef void (*AnalyzeAttrComputeStatsFunc) (VacAttrStatsP stats,
											 AnalyzeAttrFetchFunc fetchfunc,
											 int samplerows,
											 double totalrows);

typedef struct VacAttrStats
{
	/*
	 * These fields are set up by the main ANALYZE code before invoking the
	 * type-specific typanalyze function.
	 *
	 * Note: do not assume that the data being analyzed has the same datatype
	 * shown in attr, ie do not trust attr->atttypid, attlen, etc.  This is
	 * because some index opclasses store a different type than the underlying
	 * column/expression.  Instead use attrtypid, attrtypmod, and attrtype for
	 * information about the datatype being fed to the typanalyze function.
	 * Likewise, use attrcollid not attr->attcollation.
	 */
	Form_pg_attribute attr;		/* copy of pg_attribute row for column */
	Oid			attrtypid;		/* type of data being analyzed */
	int32		attrtypmod;		/* typmod of data being analyzed */
	Form_pg_type attrtype;		/* copy of pg_type row for attrtypid */
	Oid			attrcollid;		/* collation of data being analyzed */
	MemoryContext anl_context;	/* where to save long-lived data */

	/*
	 * These fields must be filled in by the typanalyze routine, unless it
	 * returns false.
	 */
	AnalyzeAttrComputeStatsFunc compute_stats;	/* function pointer */
	int			minrows;		/* Minimum # of rows wanted for stats */
	void	   *extra_data;		/* for extra type-specific data */

	/*
	 * These fields are to be filled in by the compute_stats routine. (They
	 * are initialized to zero when the struct is created.)
	 */
	bool		stats_valid;
	float4		stanullfrac;	/* fraction of entries that are NULL */
	int32		stawidth;		/* average width of column values */
	float4		stadistinct;	/* # distinct values */
	int16		stakind[STATISTIC_NUM_SLOTS];
	Oid			staop[STATISTIC_NUM_SLOTS];
	Oid			stacoll[STATISTIC_NUM_SLOTS];
	int			numnumbers[STATISTIC_NUM_SLOTS];
	float4	   *stanumbers[STATISTIC_NUM_SLOTS];
	int			numvalues[STATISTIC_NUM_SLOTS];
	Datum	   *stavalues[STATISTIC_NUM_SLOTS];

	/*
	 * These fields describe the stavalues[n] element types. They will be
	 * initialized to match attrtypid, but a custom typanalyze function might
	 * want to store an array of something other than the analyzed column's
	 * elements. It should then overwrite these fields.
	 */
	Oid			statypid[STATISTIC_NUM_SLOTS];
	int16		statyplen[STATISTIC_NUM_SLOTS];
	bool		statypbyval[STATISTIC_NUM_SLOTS];
	char		statypalign[STATISTIC_NUM_SLOTS];

	/*
	 * These fields are private to the main ANALYZE code and should not be
	 * looked at by type-specific functions.
	 */
	int			tupattnum;		/* attribute number within tuples */
	HeapTuple  *rows;			/* access info for std fetch function */
	TupleDesc	tupDesc;
	Datum	   *exprvals;		/* access info for index fetch function */
	bool	   *exprnulls;
	int			rowstride;
} VacAttrStats;

/* flag bits for VacuumParams->options */
#define VACOPT_VACUUM 0x01		/* do VACUUM */
#define VACOPT_ANALYZE 0x02		/* do ANALYZE */
#define VACOPT_VERBOSE 0x04		/* output INFO instrumentation messages */
#define VACOPT_FREEZE 0x08		/* FREEZE option */
#define VACOPT_FULL 0x10		/* FULL (non-concurrent) vacuum */
#define VACOPT_SKIP_LOCKED 0x20 /* skip if cannot get lock */
#define VACOPT_PROCESS_TOAST 0x40	/* process the TOAST table, if any */
#define VACOPT_DISABLE_PAGE_SKIPPING 0x80	/* don't skip any pages */

/*
 * Values used by index_cleanup and truncate params.
 *
 * VACOPTVALUE_UNSPECIFIED is used as an initial placeholder when VACUUM
 * command has no explicit value.  When that happens the final usable value
 * comes from the corresponding reloption (though the reloption default is
 * usually used).
 */
typedef enum VacOptValue
{
	VACOPTVALUE_UNSPECIFIED = 0,
	VACOPTVALUE_AUTO,
	VACOPTVALUE_DISABLED,
	VACOPTVALUE_ENABLED,
} VacOptValue;

/*
 * Parameters customizing behavior of VACUUM and ANALYZE.
 *
 * Note that at least one of VACOPT_VACUUM and VACOPT_ANALYZE must be set
 * in options.
 */
typedef struct VacuumParams
{
	bits32		options;		/* bitmask of VACOPT_* */
	int			freeze_min_age; /* min freeze age, -1 to use default */
	int			freeze_table_age;	/* age at which to scan whole table */
	int			multixact_freeze_min_age;	/* min multixact freeze age, -1 to
											 * use default */
	int			multixact_freeze_table_age; /* multixact age at which to scan
											 * whole table */
	bool		is_wraparound;	/* force a for-wraparound vacuum */
	int			log_min_duration;	/* minimum execution threshold in ms at
									 * which autovacuum is logged, -1 to use
									 * default */
	VacOptValue index_cleanup;	/* Do index vacuum and cleanup */
	VacOptValue truncate;		/* Truncate empty pages at the end */

	/*
	 * The number of parallel vacuum workers.  0 by default which means choose
	 * based on the number of indexes.  -1 indicates parallel vacuum is
	 * disabled.
	 */
	int			nworkers;
} VacuumParams;

/*
 * VacDeadItems stores TIDs whose index tuples are deleted by index vacuuming.
 */
typedef struct VacDeadItems
{
	int			max_items;		/* # slots allocated in array */
	int			num_items;		/* current # of entries */

	/* Sorted array of TIDs to delete from indexes */
	ItemPointerData items[FLEXIBLE_ARRAY_MEMBER];
} VacDeadItems;

#define MAXDEADITEMS(avail_mem) \
	(((avail_mem) - offsetof(VacDeadItems, items)) / sizeof(ItemPointerData))

/* GUC parameters */
extern PGDLLIMPORT int default_statistics_target;	/* PGDLLIMPORT for PostGIS */
extern PGDLLIMPORT int vacuum_freeze_min_age;
extern PGDLLIMPORT int vacuum_freeze_table_age;
extern PGDLLIMPORT int vacuum_multixact_freeze_min_age;
extern PGDLLIMPORT int vacuum_multixact_freeze_table_age;
extern PGDLLIMPORT int vacuum_failsafe_age;
extern PGDLLIMPORT int vacuum_multixact_failsafe_age;

/* Variables for cost-based parallel vacuum */
extern PGDLLIMPORT pg_atomic_uint32 *VacuumSharedCostBalance;
extern PGDLLIMPORT pg_atomic_uint32 *VacuumActiveNWorkers;
extern PGDLLIMPORT int VacuumCostBalanceLocal;


/* in commands/vacuum.c */
extern void ExecVacuum(ParseState *pstate, VacuumStmt *vacstmt, bool isTopLevel);
extern void vacuum(List *relations, VacuumParams *params,
				   BufferAccessStrategy bstrategy, bool isTopLevel);
extern void vac_open_indexes(Relation relation, LOCKMODE lockmode,
							 int *nindexes, Relation **Irel);
extern void vac_close_indexes(int nindexes, Relation *Irel, LOCKMODE lockmode);
extern double vac_estimate_reltuples(Relation relation,
									 BlockNumber total_pages,
									 BlockNumber scanned_pages,
									 double scanned_tuples);
extern void vac_update_relstats(Relation relation,
								BlockNumber num_pages,
								double num_tuples,
								BlockNumber num_all_visible_pages,
								bool hasindex,
								TransactionId frozenxid,
								MultiXactId minmulti,
								bool *frozenxid_updated,
								bool *minmulti_updated,
								bool in_outer_xact);
extern bool vacuum_set_xid_limits(Relation rel,
								  int freeze_min_age, int freeze_table_age,
								  int multixact_freeze_min_age,
								  int multixact_freeze_table_age,
								  TransactionId *oldestXmin,
								  MultiXactId *oldestMxact,
								  TransactionId *freezeLimit,
								  MultiXactId *multiXactCutoff);
extern bool vacuum_xid_failsafe_check(TransactionId relfrozenxid,
									  MultiXactId relminmxid);
extern void vac_update_datfrozenxid(void);
extern void vacuum_delay_point(void);
extern bool vacuum_is_relation_owner(Oid relid, Form_pg_class reltuple,
									 bits32 options);
extern Relation vacuum_open_relation(Oid relid, RangeVar *relation,
									 bits32 options, bool verbose,
									 LOCKMODE lmode);
extern IndexBulkDeleteResult *vac_bulkdel_one_index(IndexVacuumInfo *ivinfo,
													IndexBulkDeleteResult *istat,
													VacDeadItems *dead_items);
extern IndexBulkDeleteResult *vac_cleanup_one_index(IndexVacuumInfo *ivinfo,
													IndexBulkDeleteResult *istat);
extern Size vac_max_items_to_alloc_size(int max_items);

/* in commands/vacuumparallel.c */
extern ParallelVacuumState *parallel_vacuum_init(Relation rel, Relation *indrels,
												 int nindexes, int nrequested_workers,
												 int max_items, int elevel,
												 BufferAccessStrategy bstrategy);
extern void parallel_vacuum_end(ParallelVacuumState *pvs, IndexBulkDeleteResult **istats);
extern VacDeadItems *parallel_vacuum_get_dead_items(ParallelVacuumState *pvs);
extern void parallel_vacuum_bulkdel_all_indexes(ParallelVacuumState *pvs,
												long num_table_tuples,
												int num_index_scans);
extern void parallel_vacuum_cleanup_all_indexes(ParallelVacuumState *pvs,
												long num_table_tuples,
												int num_index_scans,
												bool estimated_count);
extern void parallel_vacuum_main(dsm_segment *seg, shm_toc *toc);

/* in commands/analyze.c */
extern void analyze_rel(Oid relid, RangeVar *relation,
						VacuumParams *params, List *va_cols, bool in_outer_xact,
						BufferAccessStrategy bstrategy);
extern bool std_typanalyze(VacAttrStats *stats);

/* in utils/misc/sampling.c --- duplicate of declarations in utils/sampling.h */
extern double anl_random_fract(void);
extern double anl_init_selection_state(int n);
extern double anl_get_next_S(double t, int n, double *stateptr);

#endif							/* VACUUM_H */
