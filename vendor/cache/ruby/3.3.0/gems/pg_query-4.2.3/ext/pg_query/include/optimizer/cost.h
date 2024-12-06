/*-------------------------------------------------------------------------
 *
 * cost.h
 *	  prototypes for costsize.c and clausesel.c.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/optimizer/cost.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef COST_H
#define COST_H

#include "nodes/pathnodes.h"
#include "nodes/plannodes.h"


/* defaults for costsize.c's Cost parameters */
/* NB: cost-estimation code should use the variables, not these constants! */
/* If you change these, update backend/utils/misc/postgresql.conf.sample */
#define DEFAULT_SEQ_PAGE_COST  1.0
#define DEFAULT_RANDOM_PAGE_COST  4.0
#define DEFAULT_CPU_TUPLE_COST	0.01
#define DEFAULT_CPU_INDEX_TUPLE_COST 0.005
#define DEFAULT_CPU_OPERATOR_COST  0.0025
#define DEFAULT_PARALLEL_TUPLE_COST 0.1
#define DEFAULT_PARALLEL_SETUP_COST  1000.0

/* defaults for non-Cost parameters */
#define DEFAULT_RECURSIVE_WORKTABLE_FACTOR  10.0
#define DEFAULT_EFFECTIVE_CACHE_SIZE  524288	/* measured in pages */

typedef enum
{
	CONSTRAINT_EXCLUSION_OFF,	/* do not use c_e */
	CONSTRAINT_EXCLUSION_ON,	/* apply c_e to all rels */
	CONSTRAINT_EXCLUSION_PARTITION	/* apply c_e to otherrels only */
}			ConstraintExclusionType;


/*
 * prototypes for costsize.c
 *	  routines to compute costs and sizes
 */

/* parameter variables and flags (see also optimizer.h) */
extern PGDLLIMPORT Cost disable_cost;
extern PGDLLIMPORT int max_parallel_workers_per_gather;
extern PGDLLIMPORT bool enable_seqscan;
extern PGDLLIMPORT bool enable_indexscan;
extern PGDLLIMPORT bool enable_indexonlyscan;
extern PGDLLIMPORT bool enable_bitmapscan;
extern PGDLLIMPORT bool enable_tidscan;
extern PGDLLIMPORT bool enable_sort;
extern PGDLLIMPORT bool enable_incremental_sort;
extern PGDLLIMPORT bool enable_hashagg;
extern PGDLLIMPORT bool enable_nestloop;
extern PGDLLIMPORT bool enable_material;
extern PGDLLIMPORT bool enable_memoize;
extern PGDLLIMPORT bool enable_mergejoin;
extern PGDLLIMPORT bool enable_hashjoin;
extern PGDLLIMPORT bool enable_gathermerge;
extern PGDLLIMPORT bool enable_partitionwise_join;
extern PGDLLIMPORT bool enable_partitionwise_aggregate;
extern PGDLLIMPORT bool enable_parallel_append;
extern PGDLLIMPORT bool enable_parallel_hash;
extern PGDLLIMPORT bool enable_partition_pruning;
extern PGDLLIMPORT bool enable_async_append;
extern PGDLLIMPORT int constraint_exclusion;

extern double index_pages_fetched(double tuples_fetched, BlockNumber pages,
								  double index_pages, PlannerInfo *root);
extern void cost_seqscan(Path *path, PlannerInfo *root, RelOptInfo *baserel,
						 ParamPathInfo *param_info);
extern void cost_samplescan(Path *path, PlannerInfo *root, RelOptInfo *baserel,
							ParamPathInfo *param_info);
extern void cost_index(IndexPath *path, PlannerInfo *root,
					   double loop_count, bool partial_path);
extern void cost_bitmap_heap_scan(Path *path, PlannerInfo *root, RelOptInfo *baserel,
								  ParamPathInfo *param_info,
								  Path *bitmapqual, double loop_count);
extern void cost_bitmap_and_node(BitmapAndPath *path, PlannerInfo *root);
extern void cost_bitmap_or_node(BitmapOrPath *path, PlannerInfo *root);
extern void cost_bitmap_tree_node(Path *path, Cost *cost, Selectivity *selec);
extern void cost_tidscan(Path *path, PlannerInfo *root,
						 RelOptInfo *baserel, List *tidquals, ParamPathInfo *param_info);
extern void cost_tidrangescan(Path *path, PlannerInfo *root,
							  RelOptInfo *baserel, List *tidrangequals,
							  ParamPathInfo *param_info);
extern void cost_subqueryscan(SubqueryScanPath *path, PlannerInfo *root,
							  RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_functionscan(Path *path, PlannerInfo *root,
							  RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_valuesscan(Path *path, PlannerInfo *root,
							RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_tablefuncscan(Path *path, PlannerInfo *root,
							   RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_ctescan(Path *path, PlannerInfo *root,
						 RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_namedtuplestorescan(Path *path, PlannerInfo *root,
									 RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_resultscan(Path *path, PlannerInfo *root,
							RelOptInfo *baserel, ParamPathInfo *param_info);
extern void cost_recursive_union(Path *runion, Path *nrterm, Path *rterm);
extern void cost_sort(Path *path, PlannerInfo *root,
					  List *pathkeys, Cost input_cost, double tuples, int width,
					  Cost comparison_cost, int sort_mem,
					  double limit_tuples);
extern void cost_incremental_sort(Path *path,
								  PlannerInfo *root, List *pathkeys, int presorted_keys,
								  Cost input_startup_cost, Cost input_total_cost,
								  double input_tuples, int width, Cost comparison_cost, int sort_mem,
								  double limit_tuples);
extern void cost_append(AppendPath *path);
extern void cost_merge_append(Path *path, PlannerInfo *root,
							  List *pathkeys, int n_streams,
							  Cost input_startup_cost, Cost input_total_cost,
							  double tuples);
extern void cost_material(Path *path,
						  Cost input_startup_cost, Cost input_total_cost,
						  double tuples, int width);
extern void cost_agg(Path *path, PlannerInfo *root,
					 AggStrategy aggstrategy, const AggClauseCosts *aggcosts,
					 int numGroupCols, double numGroups,
					 List *quals,
					 Cost input_startup_cost, Cost input_total_cost,
					 double input_tuples, double input_width);
extern void cost_windowagg(Path *path, PlannerInfo *root,
						   List *windowFuncs, int numPartCols, int numOrderCols,
						   Cost input_startup_cost, Cost input_total_cost,
						   double input_tuples);
extern void cost_group(Path *path, PlannerInfo *root,
					   int numGroupCols, double numGroups,
					   List *quals,
					   Cost input_startup_cost, Cost input_total_cost,
					   double input_tuples);
extern void initial_cost_nestloop(PlannerInfo *root,
								  JoinCostWorkspace *workspace,
								  JoinType jointype,
								  Path *outer_path, Path *inner_path,
								  JoinPathExtraData *extra);
extern void final_cost_nestloop(PlannerInfo *root, NestPath *path,
								JoinCostWorkspace *workspace,
								JoinPathExtraData *extra);
extern void initial_cost_mergejoin(PlannerInfo *root,
								   JoinCostWorkspace *workspace,
								   JoinType jointype,
								   List *mergeclauses,
								   Path *outer_path, Path *inner_path,
								   List *outersortkeys, List *innersortkeys,
								   JoinPathExtraData *extra);
extern void final_cost_mergejoin(PlannerInfo *root, MergePath *path,
								 JoinCostWorkspace *workspace,
								 JoinPathExtraData *extra);
extern void initial_cost_hashjoin(PlannerInfo *root,
								  JoinCostWorkspace *workspace,
								  JoinType jointype,
								  List *hashclauses,
								  Path *outer_path, Path *inner_path,
								  JoinPathExtraData *extra,
								  bool parallel_hash);
extern void final_cost_hashjoin(PlannerInfo *root, HashPath *path,
								JoinCostWorkspace *workspace,
								JoinPathExtraData *extra);
extern void cost_gather(GatherPath *path, PlannerInfo *root,
						RelOptInfo *baserel, ParamPathInfo *param_info, double *rows);
extern void cost_gather_merge(GatherMergePath *path, PlannerInfo *root,
							  RelOptInfo *rel, ParamPathInfo *param_info,
							  Cost input_startup_cost, Cost input_total_cost,
							  double *rows);
extern void cost_subplan(PlannerInfo *root, SubPlan *subplan, Plan *plan);
extern void cost_qual_eval(QualCost *cost, List *quals, PlannerInfo *root);
extern void cost_qual_eval_node(QualCost *cost, Node *qual, PlannerInfo *root);
extern void compute_semi_anti_join_factors(PlannerInfo *root,
										   RelOptInfo *joinrel,
										   RelOptInfo *outerrel,
										   RelOptInfo *innerrel,
										   JoinType jointype,
										   SpecialJoinInfo *sjinfo,
										   List *restrictlist,
										   SemiAntiJoinFactors *semifactors);
extern void set_baserel_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern double get_parameterized_baserel_size(PlannerInfo *root,
											 RelOptInfo *rel,
											 List *param_clauses);
extern double get_parameterized_joinrel_size(PlannerInfo *root,
											 RelOptInfo *rel,
											 Path *outer_path,
											 Path *inner_path,
											 SpecialJoinInfo *sjinfo,
											 List *restrict_clauses);
extern void set_joinrel_size_estimates(PlannerInfo *root, RelOptInfo *rel,
									   RelOptInfo *outer_rel,
									   RelOptInfo *inner_rel,
									   SpecialJoinInfo *sjinfo,
									   List *restrictlist);
extern void set_subquery_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_function_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_values_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_cte_size_estimates(PlannerInfo *root, RelOptInfo *rel,
								   double cte_rows);
extern void set_tablefunc_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_namedtuplestore_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_result_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern void set_foreign_size_estimates(PlannerInfo *root, RelOptInfo *rel);
extern PathTarget *set_pathtarget_cost_width(PlannerInfo *root, PathTarget *target);
extern double compute_bitmap_pages(PlannerInfo *root, RelOptInfo *baserel,
								   Path *bitmapqual, int loop_count, Cost *cost, double *tuple);

#endif							/* COST_H */
