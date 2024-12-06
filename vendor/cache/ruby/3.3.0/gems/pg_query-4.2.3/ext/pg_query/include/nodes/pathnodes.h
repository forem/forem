/*-------------------------------------------------------------------------
 *
 * pathnodes.h
 *	  Definitions for planner's internal data structures, especially Paths.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/nodes/pathnodes.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PATHNODES_H
#define PATHNODES_H

#include "access/sdir.h"
#include "lib/stringinfo.h"
#include "nodes/params.h"
#include "nodes/parsenodes.h"
#include "storage/block.h"


/*
 * Relids
 *		Set of relation identifiers (indexes into the rangetable).
 */
typedef Bitmapset *Relids;

/*
 * When looking for a "cheapest path", this enum specifies whether we want
 * cheapest startup cost or cheapest total cost.
 */
typedef enum CostSelector
{
	STARTUP_COST, TOTAL_COST
} CostSelector;

/*
 * The cost estimate produced by cost_qual_eval() includes both a one-time
 * (startup) cost, and a per-tuple cost.
 */
typedef struct QualCost
{
	Cost		startup;		/* one-time cost */
	Cost		per_tuple;		/* per-evaluation cost */
} QualCost;

/*
 * Costing aggregate function execution requires these statistics about
 * the aggregates to be executed by a given Agg node.  Note that the costs
 * include the execution costs of the aggregates' argument expressions as
 * well as the aggregate functions themselves.  Also, the fields must be
 * defined so that initializing the struct to zeroes with memset is correct.
 */
typedef struct AggClauseCosts
{
	QualCost	transCost;		/* total per-input-row execution costs */
	QualCost	finalCost;		/* total per-aggregated-row costs */
	Size		transitionSpace;	/* space for pass-by-ref transition data */
} AggClauseCosts;

/*
 * This enum identifies the different types of "upper" (post-scan/join)
 * relations that we might deal with during planning.
 */
typedef enum UpperRelationKind
{
	UPPERREL_SETOP,				/* result of UNION/INTERSECT/EXCEPT, if any */
	UPPERREL_PARTIAL_GROUP_AGG, /* result of partial grouping/aggregation, if
								 * any */
	UPPERREL_GROUP_AGG,			/* result of grouping/aggregation, if any */
	UPPERREL_WINDOW,			/* result of window functions, if any */
	UPPERREL_PARTIAL_DISTINCT,	/* result of partial "SELECT DISTINCT", if any */
	UPPERREL_DISTINCT,			/* result of "SELECT DISTINCT", if any */
	UPPERREL_ORDERED,			/* result of ORDER BY, if any */
	UPPERREL_FINAL				/* result of any remaining top-level actions */
	/* NB: UPPERREL_FINAL must be last enum entry; it's used to size arrays */
} UpperRelationKind;

/*----------
 * PlannerGlobal
 *		Global information for planning/optimization
 *
 * PlannerGlobal holds state for an entire planner invocation; this state
 * is shared across all levels of sub-Queries that exist in the command being
 * planned.
 *----------
 */
typedef struct PlannerGlobal
{
	NodeTag		type;

	ParamListInfo boundParams;	/* Param values provided to planner() */

	List	   *subplans;		/* Plans for SubPlan nodes */

	List	   *subroots;		/* PlannerInfos for SubPlan nodes */

	Bitmapset  *rewindPlanIDs;	/* indices of subplans that require REWIND */

	List	   *finalrtable;	/* "flat" rangetable for executor */

	List	   *finalrowmarks;	/* "flat" list of PlanRowMarks */

	List	   *resultRelations;	/* "flat" list of integer RT indexes */

	List	   *appendRelations;	/* "flat" list of AppendRelInfos */

	List	   *relationOids;	/* OIDs of relations the plan depends on */

	List	   *invalItems;		/* other dependencies, as PlanInvalItems */

	List	   *paramExecTypes; /* type OIDs for PARAM_EXEC Params */

	Index		lastPHId;		/* highest PlaceHolderVar ID assigned */

	Index		lastRowMarkId;	/* highest PlanRowMark ID assigned */

	int			lastPlanNodeId; /* highest plan node ID assigned */

	bool		transientPlan;	/* redo plan when TransactionXmin changes? */

	bool		dependsOnRole;	/* is plan specific to current role? */

	bool		parallelModeOK; /* parallel mode potentially OK? */

	bool		parallelModeNeeded; /* parallel mode actually required? */

	char		maxParallelHazard;	/* worst PROPARALLEL hazard level */

	PartitionDirectory partition_directory; /* partition descriptors */
} PlannerGlobal;

/* macro for fetching the Plan associated with a SubPlan node */
#define planner_subplan_get_plan(root, subplan) \
	((Plan *) list_nth((root)->glob->subplans, (subplan)->plan_id - 1))


/*----------
 * PlannerInfo
 *		Per-query information for planning/optimization
 *
 * This struct is conventionally called "root" in all the planner routines.
 * It holds links to all of the planner's working state, in addition to the
 * original Query.  Note that at present the planner extensively modifies
 * the passed-in Query data structure; someday that should stop.
 *
 * For reasons explained in optimizer/optimizer.h, we define the typedef
 * either here or in that header, whichever is read first.
 *----------
 */
#ifndef HAVE_PLANNERINFO_TYPEDEF
typedef struct PlannerInfo PlannerInfo;
#define HAVE_PLANNERINFO_TYPEDEF 1
#endif

struct PlannerInfo
{
	NodeTag		type;

	Query	   *parse;			/* the Query being planned */

	PlannerGlobal *glob;		/* global info for current planner run */

	Index		query_level;	/* 1 at the outermost Query */

	PlannerInfo *parent_root;	/* NULL at outermost Query */

	/*
	 * plan_params contains the expressions that this query level needs to
	 * make available to a lower query level that is currently being planned.
	 * outer_params contains the paramIds of PARAM_EXEC Params that outer
	 * query levels will make available to this query level.
	 */
	List	   *plan_params;	/* list of PlannerParamItems, see below */
	Bitmapset  *outer_params;

	/*
	 * simple_rel_array holds pointers to "base rels" and "other rels" (see
	 * comments for RelOptInfo for more info).  It is indexed by rangetable
	 * index (so entry 0 is always wasted).  Entries can be NULL when an RTE
	 * does not correspond to a base relation, such as a join RTE or an
	 * unreferenced view RTE; or if the RelOptInfo hasn't been made yet.
	 */
	struct RelOptInfo **simple_rel_array;	/* All 1-rel RelOptInfos */
	int			simple_rel_array_size;	/* allocated size of array */

	/*
	 * simple_rte_array is the same length as simple_rel_array and holds
	 * pointers to the associated rangetable entries.  Using this is a shade
	 * faster than using rt_fetch(), mostly due to fewer indirections.
	 */
	RangeTblEntry **simple_rte_array;	/* rangetable as an array */

	/*
	 * append_rel_array is the same length as the above arrays, and holds
	 * pointers to the corresponding AppendRelInfo entry indexed by
	 * child_relid, or NULL if the rel is not an appendrel child.  The array
	 * itself is not allocated if append_rel_list is empty.
	 */
	struct AppendRelInfo **append_rel_array;

	/*
	 * all_baserels is a Relids set of all base relids (but not "other"
	 * relids) in the query; that is, the Relids identifier of the final join
	 * we need to form.  This is computed in make_one_rel, just before we
	 * start making Paths.
	 */
	Relids		all_baserels;

	/*
	 * nullable_baserels is a Relids set of base relids that are nullable by
	 * some outer join in the jointree; these are rels that are potentially
	 * nullable below the WHERE clause, SELECT targetlist, etc.  This is
	 * computed in deconstruct_jointree.
	 */
	Relids		nullable_baserels;

	/*
	 * join_rel_list is a list of all join-relation RelOptInfos we have
	 * considered in this planning run.  For small problems we just scan the
	 * list to do lookups, but when there are many join relations we build a
	 * hash table for faster lookups.  The hash table is present and valid
	 * when join_rel_hash is not NULL.  Note that we still maintain the list
	 * even when using the hash table for lookups; this simplifies life for
	 * GEQO.
	 */
	List	   *join_rel_list;	/* list of join-relation RelOptInfos */
	struct HTAB *join_rel_hash; /* optional hashtable for join relations */

	/*
	 * When doing a dynamic-programming-style join search, join_rel_level[k]
	 * is a list of all join-relation RelOptInfos of level k, and
	 * join_cur_level is the current level.  New join-relation RelOptInfos are
	 * automatically added to the join_rel_level[join_cur_level] list.
	 * join_rel_level is NULL if not in use.
	 */
	List	  **join_rel_level; /* lists of join-relation RelOptInfos */
	int			join_cur_level; /* index of list being extended */

	List	   *init_plans;		/* init SubPlans for query */

	List	   *cte_plan_ids;	/* per-CTE-item list of subplan IDs (or -1 if
								 * no subplan was made for that CTE) */

	List	   *multiexpr_params;	/* List of Lists of Params for MULTIEXPR
									 * subquery outputs */

	List	   *eq_classes;		/* list of active EquivalenceClasses */

	bool		ec_merging_done;	/* set true once ECs are canonical */

	List	   *canon_pathkeys; /* list of "canonical" PathKeys */

	List	   *left_join_clauses;	/* list of RestrictInfos for mergejoinable
									 * outer join clauses w/nonnullable var on
									 * left */

	List	   *right_join_clauses; /* list of RestrictInfos for mergejoinable
									 * outer join clauses w/nonnullable var on
									 * right */

	List	   *full_join_clauses;	/* list of RestrictInfos for mergejoinable
									 * full join clauses */

	List	   *join_info_list; /* list of SpecialJoinInfos */

	/*
	 * all_result_relids is empty for SELECT, otherwise it contains at least
	 * parse->resultRelation.  For UPDATE/DELETE/MERGE across an inheritance
	 * or partitioning tree, the result rel's child relids are added.  When
	 * using multi-level partitioning, intermediate partitioned rels are
	 * included. leaf_result_relids is similar except that only actual result
	 * tables, not partitioned tables, are included in it.
	 */
	Relids		all_result_relids;	/* set of all result relids */
	Relids		leaf_result_relids; /* set of all leaf relids */

	/*
	 * Note: for AppendRelInfos describing partitions of a partitioned table,
	 * we guarantee that partitions that come earlier in the partitioned
	 * table's PartitionDesc will appear earlier in append_rel_list.
	 */
	List	   *append_rel_list;	/* list of AppendRelInfos */

	List	   *row_identity_vars;	/* list of RowIdentityVarInfos */

	List	   *rowMarks;		/* list of PlanRowMarks */

	List	   *placeholder_list;	/* list of PlaceHolderInfos */

	List	   *fkey_list;		/* list of ForeignKeyOptInfos */

	List	   *query_pathkeys; /* desired pathkeys for query_planner() */

	List	   *group_pathkeys; /* groupClause pathkeys, if any */
	List	   *window_pathkeys;	/* pathkeys of bottom window, if any */
	List	   *distinct_pathkeys;	/* distinctClause pathkeys, if any */
	List	   *sort_pathkeys;	/* sortClause pathkeys, if any */

	List	   *part_schemes;	/* Canonicalised partition schemes used in the
								 * query. */

	List	   *initial_rels;	/* RelOptInfos we are now trying to join */

	/* Use fetch_upper_rel() to get any particular upper rel */
	List	   *upper_rels[UPPERREL_FINAL + 1]; /* upper-rel RelOptInfos */

	/* Result tlists chosen by grouping_planner for upper-stage processing */
	struct PathTarget *upper_targets[UPPERREL_FINAL + 1];

	/*
	 * The fully-processed targetlist is kept here.  It differs from
	 * parse->targetList in that (for INSERT) it's been reordered to match the
	 * target table, and defaults have been filled in.  Also, additional
	 * resjunk targets may be present.  preprocess_targetlist() does most of
	 * that work, but note that more resjunk targets can get added during
	 * appendrel expansion.  (Hence, upper_targets mustn't get set up till
	 * after that.)
	 */
	List	   *processed_tlist;

	/*
	 * For UPDATE, this list contains the target table's attribute numbers to
	 * which the first N entries of processed_tlist are to be assigned.  (Any
	 * additional entries in processed_tlist must be resjunk.)  DO NOT use the
	 * resnos in processed_tlist to identify the UPDATE target columns.
	 */
	List	   *update_colnos;

	/* Fields filled during create_plan() for use in setrefs.c */
	AttrNumber *grouping_map;	/* for GroupingFunc fixup */
	List	   *minmax_aggs;	/* List of MinMaxAggInfos */

	MemoryContext planner_cxt;	/* context holding PlannerInfo */

	Cardinality total_table_pages;	/* # of pages in all non-dummy tables of
									 * query */

	Selectivity tuple_fraction; /* tuple_fraction passed to query_planner */
	Cardinality limit_tuples;	/* limit_tuples passed to query_planner */

	Index		qual_security_level;	/* minimum security_level for quals */
	/* Note: qual_security_level is zero if there are no securityQuals */

	bool		hasJoinRTEs;	/* true if any RTEs are RTE_JOIN kind */
	bool		hasLateralRTEs; /* true if any RTEs are marked LATERAL */
	bool		hasHavingQual;	/* true if havingQual was non-null */
	bool		hasPseudoConstantQuals; /* true if any RestrictInfo has
										 * pseudoconstant = true */
	bool		hasAlternativeSubPlans; /* true if we've made any of those */
	bool		hasRecursion;	/* true if planning a recursive WITH item */

	/*
	 * Information about aggregates. Filled by preprocess_aggrefs().
	 */
	List	   *agginfos;		/* AggInfo structs */
	List	   *aggtransinfos;	/* AggTransInfo structs */
	int			numOrderedAggs; /* number w/ DISTINCT/ORDER BY/WITHIN GROUP */
	bool		hasNonPartialAggs;	/* does any agg not support partial mode? */
	bool		hasNonSerialAggs;	/* is any partial agg non-serializable? */

	/* These fields are used only when hasRecursion is true: */
	int			wt_param_id;	/* PARAM_EXEC ID for the work table */
	struct Path *non_recursive_path;	/* a path for non-recursive term */

	/* These fields are workspace for createplan.c */
	Relids		curOuterRels;	/* outer rels above current node */
	List	   *curOuterParams; /* not-yet-assigned NestLoopParams */

	/* These fields are workspace for setrefs.c */
	bool	   *isAltSubplan;	/* array corresponding to glob->subplans */
	bool	   *isUsedSubplan;	/* array corresponding to glob->subplans */

	/* optional private data for join_search_hook, e.g., GEQO */
	void	   *join_search_private;

	/* Does this query modify any partition key columns? */
	bool		partColsUpdated;
};


/*
 * In places where it's known that simple_rte_array[] must have been prepared
 * already, we just index into it to fetch RTEs.  In code that might be
 * executed before or after entering query_planner(), use this macro.
 */
#define planner_rt_fetch(rti, root) \
	((root)->simple_rte_array ? (root)->simple_rte_array[rti] : \
	 rt_fetch(rti, (root)->parse->rtable))

/*
 * If multiple relations are partitioned the same way, all such partitions
 * will have a pointer to the same PartitionScheme.  A list of PartitionScheme
 * objects is attached to the PlannerInfo.  By design, the partition scheme
 * incorporates only the general properties of the partition method (LIST vs.
 * RANGE, number of partitioning columns and the type information for each)
 * and not the specific bounds.
 *
 * We store the opclass-declared input data types instead of the partition key
 * datatypes since the former rather than the latter are used to compare
 * partition bounds. Since partition key data types and the opclass declared
 * input data types are expected to be binary compatible (per ResolveOpClass),
 * both of those should have same byval and length properties.
 */
typedef struct PartitionSchemeData
{
	char		strategy;		/* partition strategy */
	int16		partnatts;		/* number of partition attributes */
	Oid		   *partopfamily;	/* OIDs of operator families */
	Oid		   *partopcintype;	/* OIDs of opclass declared input data types */
	Oid		   *partcollation;	/* OIDs of partitioning collations */

	/* Cached information about partition key data types. */
	int16	   *parttyplen;
	bool	   *parttypbyval;

	/* Cached information about partition comparison functions. */
	struct FmgrInfo *partsupfunc;
}			PartitionSchemeData;

typedef struct PartitionSchemeData *PartitionScheme;

/*----------
 * RelOptInfo
 *		Per-relation information for planning/optimization
 *
 * For planning purposes, a "base rel" is either a plain relation (a table)
 * or the output of a sub-SELECT or function that appears in the range table.
 * In either case it is uniquely identified by an RT index.  A "joinrel"
 * is the joining of two or more base rels.  A joinrel is identified by
 * the set of RT indexes for its component baserels.  We create RelOptInfo
 * nodes for each baserel and joinrel, and store them in the PlannerInfo's
 * simple_rel_array and join_rel_list respectively.
 *
 * Note that there is only one joinrel for any given set of component
 * baserels, no matter what order we assemble them in; so an unordered
 * set is the right datatype to identify it with.
 *
 * We also have "other rels", which are like base rels in that they refer to
 * single RT indexes; but they are not part of the join tree, and are given
 * a different RelOptKind to identify them.
 * Currently the only kind of otherrels are those made for member relations
 * of an "append relation", that is an inheritance set or UNION ALL subquery.
 * An append relation has a parent RTE that is a base rel, which represents
 * the entire append relation.  The member RTEs are otherrels.  The parent
 * is present in the query join tree but the members are not.  The member
 * RTEs and otherrels are used to plan the scans of the individual tables or
 * subqueries of the append set; then the parent baserel is given Append
 * and/or MergeAppend paths comprising the best paths for the individual
 * member rels.  (See comments for AppendRelInfo for more information.)
 *
 * At one time we also made otherrels to represent join RTEs, for use in
 * handling join alias Vars.  Currently this is not needed because all join
 * alias Vars are expanded to non-aliased form during preprocess_expression.
 *
 * We also have relations representing joins between child relations of
 * different partitioned tables. These relations are not added to
 * join_rel_level lists as they are not joined directly by the dynamic
 * programming algorithm.
 *
 * There is also a RelOptKind for "upper" relations, which are RelOptInfos
 * that describe post-scan/join processing steps, such as aggregation.
 * Many of the fields in these RelOptInfos are meaningless, but their Path
 * fields always hold Paths showing ways to do that processing step.
 *
 * Lastly, there is a RelOptKind for "dead" relations, which are base rels
 * that we have proven we don't need to join after all.
 *
 * Parts of this data structure are specific to various scan and join
 * mechanisms.  It didn't seem worth creating new node types for them.
 *
 *		relids - Set of base-relation identifiers; it is a base relation
 *				if there is just one, a join relation if more than one
 *		rows - estimated number of tuples in the relation after restriction
 *			   clauses have been applied (ie, output rows of a plan for it)
 *		consider_startup - true if there is any value in keeping plain paths for
 *						   this rel on the basis of having cheap startup cost
 *		consider_param_startup - the same for parameterized paths
 *		reltarget - Default Path output tlist for this rel; normally contains
 *					Var and PlaceHolderVar nodes for the values we need to
 *					output from this relation.
 *					List is in no particular order, but all rels of an
 *					appendrel set must use corresponding orders.
 *					NOTE: in an appendrel child relation, may contain
 *					arbitrary expressions pulled up from a subquery!
 *		pathlist - List of Path nodes, one for each potentially useful
 *				   method of generating the relation
 *		ppilist - ParamPathInfo nodes for parameterized Paths, if any
 *		cheapest_startup_path - the pathlist member with lowest startup cost
 *			(regardless of ordering) among the unparameterized paths;
 *			or NULL if there is no unparameterized path
 *		cheapest_total_path - the pathlist member with lowest total cost
 *			(regardless of ordering) among the unparameterized paths;
 *			or if there is no unparameterized path, the path with lowest
 *			total cost among the paths with minimum parameterization
 *		cheapest_unique_path - for caching cheapest path to produce unique
 *			(no duplicates) output from relation; NULL if not yet requested
 *		cheapest_parameterized_paths - best paths for their parameterizations;
 *			always includes cheapest_total_path, even if that's unparameterized
 *		direct_lateral_relids - rels this rel has direct LATERAL references to
 *		lateral_relids - required outer rels for LATERAL, as a Relids set
 *			(includes both direct and indirect lateral references)
 *
 * If the relation is a base relation it will have these fields set:
 *
 *		relid - RTE index (this is redundant with the relids field, but
 *				is provided for convenience of access)
 *		rtekind - copy of RTE's rtekind field
 *		min_attr, max_attr - range of valid AttrNumbers for rel
 *		attr_needed - array of bitmapsets indicating the highest joinrel
 *				in which each attribute is needed; if bit 0 is set then
 *				the attribute is needed as part of final targetlist
 *		attr_widths - cache space for per-attribute width estimates;
 *					  zero means not computed yet
 *		lateral_vars - lateral cross-references of rel, if any (list of
 *					   Vars and PlaceHolderVars)
 *		lateral_referencers - relids of rels that reference this one laterally
 *				(includes both direct and indirect lateral references)
 *		indexlist - list of IndexOptInfo nodes for relation's indexes
 *					(always NIL if it's not a table)
 *		pages - number of disk pages in relation (zero if not a table)
 *		tuples - number of tuples in relation (not considering restrictions)
 *		allvisfrac - fraction of disk pages that are marked all-visible
 *		eclass_indexes - EquivalenceClasses that mention this rel (filled
 *						 only after EC merging is complete)
 *		subroot - PlannerInfo for subquery (NULL if it's not a subquery)
 *		subplan_params - list of PlannerParamItems to be passed to subquery
 *
 *		Note: for a subquery, tuples and subroot are not set immediately
 *		upon creation of the RelOptInfo object; they are filled in when
 *		set_subquery_pathlist processes the object.
 *
 *		For otherrels that are appendrel members, these fields are filled
 *		in just as for a baserel, except we don't bother with lateral_vars.
 *
 * If the relation is either a foreign table or a join of foreign tables that
 * all belong to the same foreign server and are assigned to the same user to
 * check access permissions as (cf checkAsUser), these fields will be set:
 *
 *		serverid - OID of foreign server, if foreign table (else InvalidOid)
 *		userid - OID of user to check access as (InvalidOid means current user)
 *		useridiscurrent - we've assumed that userid equals current user
 *		fdwroutine - function hooks for FDW, if foreign table (else NULL)
 *		fdw_private - private state for FDW, if foreign table (else NULL)
 *
 * Two fields are used to cache knowledge acquired during the join search
 * about whether this rel is provably unique when being joined to given other
 * relation(s), ie, it can have at most one row matching any given row from
 * that join relation.  Currently we only attempt such proofs, and thus only
 * populate these fields, for base rels; but someday they might be used for
 * join rels too:
 *
 *		unique_for_rels - list of Relid sets, each one being a set of other
 *					rels for which this one has been proven unique
 *		non_unique_for_rels - list of Relid sets, each one being a set of
 *					other rels for which we have tried and failed to prove
 *					this one unique
 *
 * The presence of the following fields depends on the restrictions
 * and joins that the relation participates in:
 *
 *		baserestrictinfo - List of RestrictInfo nodes, containing info about
 *					each non-join qualification clause in which this relation
 *					participates (only used for base rels)
 *		baserestrictcost - Estimated cost of evaluating the baserestrictinfo
 *					clauses at a single tuple (only used for base rels)
 *		baserestrict_min_security - Smallest security_level found among
 *					clauses in baserestrictinfo
 *		joininfo  - List of RestrictInfo nodes, containing info about each
 *					join clause in which this relation participates (but
 *					note this excludes clauses that might be derivable from
 *					EquivalenceClasses)
 *		has_eclass_joins - flag that EquivalenceClass joins are possible
 *
 * Note: Keeping a restrictinfo list in the RelOptInfo is useful only for
 * base rels, because for a join rel the set of clauses that are treated as
 * restrict clauses varies depending on which sub-relations we choose to join.
 * (For example, in a 3-base-rel join, a clause relating rels 1 and 2 must be
 * treated as a restrictclause if we join {1} and {2 3} to make {1 2 3}; but
 * if we join {1 2} and {3} then that clause will be a restrictclause in {1 2}
 * and should not be processed again at the level of {1 2 3}.)	Therefore,
 * the restrictinfo list in the join case appears in individual JoinPaths
 * (field joinrestrictinfo), not in the parent relation.  But it's OK for
 * the RelOptInfo to store the joininfo list, because that is the same
 * for a given rel no matter how we form it.
 *
 * We store baserestrictcost in the RelOptInfo (for base relations) because
 * we know we will need it at least once (to price the sequential scan)
 * and may need it multiple times to price index scans.
 *
 * A join relation is considered to be partitioned if it is formed from a
 * join of two relations that are partitioned, have matching partitioning
 * schemes, and are joined on an equijoin of the partitioning columns.
 * Under those conditions we can consider the join relation to be partitioned
 * by either relation's partitioning keys, though some care is needed if
 * either relation can be forced to null by outer-joining.  For example, an
 * outer join like (A LEFT JOIN B ON A.a = B.b) may produce rows with B.b
 * NULL.  These rows may not fit the partitioning conditions imposed on B.
 * Hence, strictly speaking, the join is not partitioned by B.b and thus
 * partition keys of an outer join should include partition key expressions
 * from the non-nullable side only.  However, if a subsequent join uses
 * strict comparison operators (and all commonly-used equijoin operators are
 * strict), the presence of nulls doesn't cause a problem: such rows couldn't
 * match anything on the other side and thus they don't create a need to do
 * any cross-partition sub-joins.  Hence we can treat such values as still
 * partitioning the join output for the purpose of additional partitionwise
 * joining, so long as a strict join operator is used by the next join.
 *
 * If the relation is partitioned, these fields will be set:
 *
 *		part_scheme - Partitioning scheme of the relation
 *		nparts - Number of partitions
 *		boundinfo - Partition bounds
 *		partbounds_merged - true if partition bounds are merged ones
 *		partition_qual - Partition constraint if not the root
 *		part_rels - RelOptInfos for each partition
 *		all_partrels - Relids set of all partition relids
 *		partexprs, nullable_partexprs - Partition key expressions
 *
 * The partexprs and nullable_partexprs arrays each contain
 * part_scheme->partnatts elements.  Each of the elements is a list of
 * partition key expressions.  For partitioned base relations, there is one
 * expression in each partexprs element, and nullable_partexprs is empty.
 * For partitioned join relations, each base relation within the join
 * contributes one partition key expression per partitioning column;
 * that expression goes in the partexprs[i] list if the base relation
 * is not nullable by this join or any lower outer join, or in the
 * nullable_partexprs[i] list if the base relation is nullable.
 * Furthermore, FULL JOINs add extra nullable_partexprs expressions
 * corresponding to COALESCE expressions of the left and right join columns,
 * to simplify matching join clauses to those lists.
 *----------
 */

/* Bitmask of flags supported by table AMs */
#define AMFLAG_HAS_TID_RANGE (1 << 0)

typedef enum RelOptKind
{
	RELOPT_BASEREL,
	RELOPT_JOINREL,
	RELOPT_OTHER_MEMBER_REL,
	RELOPT_OTHER_JOINREL,
	RELOPT_UPPER_REL,
	RELOPT_OTHER_UPPER_REL,
	RELOPT_DEADREL
} RelOptKind;

/*
 * Is the given relation a simple relation i.e a base or "other" member
 * relation?
 */
#define IS_SIMPLE_REL(rel) \
	((rel)->reloptkind == RELOPT_BASEREL || \
	 (rel)->reloptkind == RELOPT_OTHER_MEMBER_REL)

/* Is the given relation a join relation? */
#define IS_JOIN_REL(rel)	\
	((rel)->reloptkind == RELOPT_JOINREL || \
	 (rel)->reloptkind == RELOPT_OTHER_JOINREL)

/* Is the given relation an upper relation? */
#define IS_UPPER_REL(rel)	\
	((rel)->reloptkind == RELOPT_UPPER_REL || \
	 (rel)->reloptkind == RELOPT_OTHER_UPPER_REL)

/* Is the given relation an "other" relation? */
#define IS_OTHER_REL(rel) \
	((rel)->reloptkind == RELOPT_OTHER_MEMBER_REL || \
	 (rel)->reloptkind == RELOPT_OTHER_JOINREL || \
	 (rel)->reloptkind == RELOPT_OTHER_UPPER_REL)

typedef struct RelOptInfo
{
	NodeTag		type;

	RelOptKind	reloptkind;

	/* all relations included in this RelOptInfo */
	Relids		relids;			/* set of base relids (rangetable indexes) */

	/* size estimates generated by planner */
	Cardinality rows;			/* estimated number of result tuples */

	/* per-relation planner control flags */
	bool		consider_startup;	/* keep cheap-startup-cost paths? */
	bool		consider_param_startup; /* ditto, for parameterized paths? */
	bool		consider_parallel;	/* consider parallel paths? */

	/* default result targetlist for Paths scanning this relation */
	struct PathTarget *reltarget;	/* list of Vars/Exprs, cost, width */

	/* materialization information */
	List	   *pathlist;		/* Path structures */
	List	   *ppilist;		/* ParamPathInfos used in pathlist */
	List	   *partial_pathlist;	/* partial Paths */
	struct Path *cheapest_startup_path;
	struct Path *cheapest_total_path;
	struct Path *cheapest_unique_path;
	List	   *cheapest_parameterized_paths;

	/* parameterization information needed for both base rels and join rels */
	/* (see also lateral_vars and lateral_referencers) */
	Relids		direct_lateral_relids;	/* rels directly laterally referenced */
	Relids		lateral_relids; /* minimum parameterization of rel */

	/* information about a base rel (not set for join rels!) */
	Index		relid;
	Oid			reltablespace;	/* containing tablespace */
	RTEKind		rtekind;		/* RELATION, SUBQUERY, FUNCTION, etc */
	AttrNumber	min_attr;		/* smallest attrno of rel (often <0) */
	AttrNumber	max_attr;		/* largest attrno of rel */
	Relids	   *attr_needed;	/* array indexed [min_attr .. max_attr] */
	int32	   *attr_widths;	/* array indexed [min_attr .. max_attr] */
	List	   *lateral_vars;	/* LATERAL Vars and PHVs referenced by rel */
	Relids		lateral_referencers;	/* rels that reference me laterally */
	List	   *indexlist;		/* list of IndexOptInfo */
	List	   *statlist;		/* list of StatisticExtInfo */
	BlockNumber pages;			/* size estimates derived from pg_class */
	Cardinality tuples;
	double		allvisfrac;
	Bitmapset  *eclass_indexes; /* Indexes in PlannerInfo's eq_classes list of
								 * ECs that mention this rel */
	PlannerInfo *subroot;		/* if subquery */
	List	   *subplan_params; /* if subquery */
	int			rel_parallel_workers;	/* wanted number of parallel workers */
	uint32		amflags;		/* Bitmask of optional features supported by
								 * the table AM */

	/* Information about foreign tables and foreign joins */
	Oid			serverid;		/* identifies server for the table or join */
	Oid			userid;			/* identifies user to check access as */
	bool		useridiscurrent;	/* join is only valid for current user */
	/* use "struct FdwRoutine" to avoid including fdwapi.h here */
	struct FdwRoutine *fdwroutine;
	void	   *fdw_private;

	/* cache space for remembering if we have proven this relation unique */
	List	   *unique_for_rels;	/* known unique for these other relid
									 * set(s) */
	List	   *non_unique_for_rels;	/* known not unique for these set(s) */

	/* used by various scans and joins: */
	List	   *baserestrictinfo;	/* RestrictInfo structures (if base rel) */
	QualCost	baserestrictcost;	/* cost of evaluating the above */
	Index		baserestrict_min_security;	/* min security_level found in
											 * baserestrictinfo */
	List	   *joininfo;		/* RestrictInfo structures for join clauses
								 * involving this rel */
	bool		has_eclass_joins;	/* T means joininfo is incomplete */

	/* used by partitionwise joins: */
	bool		consider_partitionwise_join;	/* consider partitionwise join
												 * paths? (if partitioned rel) */
	Relids		top_parent_relids;	/* Relids of topmost parents (if "other"
									 * rel) */

	/* used for partitioned relations: */
	PartitionScheme part_scheme;	/* Partitioning scheme */
	int			nparts;			/* Number of partitions; -1 if not yet set; in
								 * case of a join relation 0 means it's
								 * considered unpartitioned */
	struct PartitionBoundInfoData *boundinfo;	/* Partition bounds */
	bool		partbounds_merged;	/* True if partition bounds were created
									 * by partition_bounds_merge() */
	List	   *partition_qual; /* Partition constraint, if not the root */
	struct RelOptInfo **part_rels;	/* Array of RelOptInfos of partitions,
									 * stored in the same order as bounds */
	Bitmapset  *live_parts;		/* Bitmap with members acting as indexes into
								 * the part_rels[] array to indicate which
								 * partitions survived partition pruning. */
	Relids		all_partrels;	/* Relids set of all partition relids */
	List	  **partexprs;		/* Non-nullable partition key expressions */
	List	  **nullable_partexprs; /* Nullable partition key expressions */
} RelOptInfo;

/*
 * Is given relation partitioned?
 *
 * It's not enough to test whether rel->part_scheme is set, because it might
 * be that the basic partitioning properties of the input relations matched
 * but the partition bounds did not.  Also, if we are able to prove a rel
 * dummy (empty), we should henceforth treat it as unpartitioned.
 */
#define IS_PARTITIONED_REL(rel) \
	((rel)->part_scheme && (rel)->boundinfo && (rel)->nparts > 0 && \
	 (rel)->part_rels && !IS_DUMMY_REL(rel))

/*
 * Convenience macro to make sure that a partitioned relation has all the
 * required members set.
 */
#define REL_HAS_ALL_PART_PROPS(rel)	\
	((rel)->part_scheme && (rel)->boundinfo && (rel)->nparts > 0 && \
	 (rel)->part_rels && (rel)->partexprs && (rel)->nullable_partexprs)

/*
 * IndexOptInfo
 *		Per-index information for planning/optimization
 *
 *		indexkeys[], indexcollations[] each have ncolumns entries.
 *		opfamily[], and opcintype[]	each have nkeycolumns entries. They do
 *		not contain any information about included attributes.
 *
 *		sortopfamily[], reverse_sort[], and nulls_first[] have
 *		nkeycolumns entries, if the index is ordered; but if it is unordered,
 *		those pointers are NULL.
 *
 *		Zeroes in the indexkeys[] array indicate index columns that are
 *		expressions; there is one element in indexprs for each such column.
 *
 *		For an ordered index, reverse_sort[] and nulls_first[] describe the
 *		sort ordering of a forward indexscan; we can also consider a backward
 *		indexscan, which will generate the reverse ordering.
 *
 *		The indexprs and indpred expressions have been run through
 *		prepqual.c and eval_const_expressions() for ease of matching to
 *		WHERE clauses. indpred is in implicit-AND form.
 *
 *		indextlist is a TargetEntry list representing the index columns.
 *		It provides an equivalent base-relation Var for each simple column,
 *		and links to the matching indexprs element for each expression column.
 *
 *		While most of these fields are filled when the IndexOptInfo is created
 *		(by plancat.c), indrestrictinfo and predOK are set later, in
 *		check_index_predicates().
 */
#ifndef HAVE_INDEXOPTINFO_TYPEDEF
typedef struct IndexOptInfo IndexOptInfo;
#define HAVE_INDEXOPTINFO_TYPEDEF 1
#endif

struct IndexOptInfo
{
	NodeTag		type;

	Oid			indexoid;		/* OID of the index relation */
	Oid			reltablespace;	/* tablespace of index (not table) */
	RelOptInfo *rel;			/* back-link to index's table */

	/* index-size statistics (from pg_class and elsewhere) */
	BlockNumber pages;			/* number of disk pages in index */
	Cardinality tuples;			/* number of index tuples in index */
	int			tree_height;	/* index tree height, or -1 if unknown */

	/* index descriptor information */
	int			ncolumns;		/* number of columns in index */
	int			nkeycolumns;	/* number of key columns in index */
	int		   *indexkeys;		/* column numbers of index's attributes both
								 * key and included columns, or 0 */
	Oid		   *indexcollations;	/* OIDs of collations of index columns */
	Oid		   *opfamily;		/* OIDs of operator families for columns */
	Oid		   *opcintype;		/* OIDs of opclass declared input data types */
	Oid		   *sortopfamily;	/* OIDs of btree opfamilies, if orderable */
	bool	   *reverse_sort;	/* is sort order descending? */
	bool	   *nulls_first;	/* do NULLs come first in the sort order? */
	bytea	  **opclassoptions; /* opclass-specific options for columns */
	bool	   *canreturn;		/* which index cols can be returned in an
								 * index-only scan? */
	Oid			relam;			/* OID of the access method (in pg_am) */

	List	   *indexprs;		/* expressions for non-simple index columns */
	List	   *indpred;		/* predicate if a partial index, else NIL */

	List	   *indextlist;		/* targetlist representing index columns */

	List	   *indrestrictinfo;	/* parent relation's baserestrictinfo
									 * list, less any conditions implied by
									 * the index's predicate (unless it's a
									 * target rel, see comments in
									 * check_index_predicates()) */

	bool		predOK;			/* true if index predicate matches query */
	bool		unique;			/* true if a unique index */
	bool		immediate;		/* is uniqueness enforced immediately? */
	bool		hypothetical;	/* true if index doesn't really exist */

	/* Remaining fields are copied from the index AM's API struct: */
	bool		amcanorderbyop; /* does AM support order by operator result? */
	bool		amoptionalkey;	/* can query omit key for the first column? */
	bool		amsearcharray;	/* can AM handle ScalarArrayOpExpr quals? */
	bool		amsearchnulls;	/* can AM search for NULL/NOT NULL entries? */
	bool		amhasgettuple;	/* does AM have amgettuple interface? */
	bool		amhasgetbitmap; /* does AM have amgetbitmap interface? */
	bool		amcanparallel;	/* does AM support parallel scan? */
	bool		amcanmarkpos;	/* does AM support mark/restore? */
	/* Rather than include amapi.h here, we declare amcostestimate like this */
	void		(*amcostestimate) ();	/* AM's cost estimator */
};

/*
 * ForeignKeyOptInfo
 *		Per-foreign-key information for planning/optimization
 *
 * The per-FK-column arrays can be fixed-size because we allow at most
 * INDEX_MAX_KEYS columns in a foreign key constraint.  Each array has
 * nkeys valid entries.
 */
typedef struct ForeignKeyOptInfo
{
	NodeTag		type;

	/* Basic data about the foreign key (fetched from catalogs): */
	Index		con_relid;		/* RT index of the referencing table */
	Index		ref_relid;		/* RT index of the referenced table */
	int			nkeys;			/* number of columns in the foreign key */
	AttrNumber	conkey[INDEX_MAX_KEYS]; /* cols in referencing table */
	AttrNumber	confkey[INDEX_MAX_KEYS];	/* cols in referenced table */
	Oid			conpfeqop[INDEX_MAX_KEYS];	/* PK = FK operator OIDs */

	/* Derived info about whether FK's equality conditions match the query: */
	int			nmatched_ec;	/* # of FK cols matched by ECs */
	int			nconst_ec;		/* # of these ECs that are ec_has_const */
	int			nmatched_rcols; /* # of FK cols matched by non-EC rinfos */
	int			nmatched_ri;	/* total # of non-EC rinfos matched to FK */
	/* Pointer to eclass matching each column's condition, if there is one */
	struct EquivalenceClass *eclass[INDEX_MAX_KEYS];
	/* Pointer to eclass member for the referencing Var, if there is one */
	struct EquivalenceMember *fk_eclass_member[INDEX_MAX_KEYS];
	/* List of non-EC RestrictInfos matching each column's condition */
	List	   *rinfos[INDEX_MAX_KEYS];
} ForeignKeyOptInfo;

/*
 * StatisticExtInfo
 *		Information about extended statistics for planning/optimization
 *
 * Each pg_statistic_ext row is represented by one or more nodes of this
 * type, or even zero if ANALYZE has not computed them.
 */
typedef struct StatisticExtInfo
{
	NodeTag		type;

	Oid			statOid;		/* OID of the statistics row */
	bool		inherit;		/* includes child relations */
	RelOptInfo *rel;			/* back-link to statistic's table */
	char		kind;			/* statistics kind of this entry */
	Bitmapset  *keys;			/* attnums of the columns covered */
	List	   *exprs;			/* expressions */
} StatisticExtInfo;

/*
 * EquivalenceClasses
 *
 * Whenever we can determine that a mergejoinable equality clause A = B is
 * not delayed by any outer join, we create an EquivalenceClass containing
 * the expressions A and B to record this knowledge.  If we later find another
 * equivalence B = C, we add C to the existing EquivalenceClass; this may
 * require merging two existing EquivalenceClasses.  At the end of the qual
 * distribution process, we have sets of values that are known all transitively
 * equal to each other, where "equal" is according to the rules of the btree
 * operator family(s) shown in ec_opfamilies, as well as the collation shown
 * by ec_collation.  (We restrict an EC to contain only equalities whose
 * operators belong to the same set of opfamilies.  This could probably be
 * relaxed, but for now it's not worth the trouble, since nearly all equality
 * operators belong to only one btree opclass anyway.  Similarly, we suppose
 * that all or none of the input datatypes are collatable, so that a single
 * collation value is sufficient.)
 *
 * We also use EquivalenceClasses as the base structure for PathKeys, letting
 * us represent knowledge about different sort orderings being equivalent.
 * Since every PathKey must reference an EquivalenceClass, we will end up
 * with single-member EquivalenceClasses whenever a sort key expression has
 * not been equivalenced to anything else.  It is also possible that such an
 * EquivalenceClass will contain a volatile expression ("ORDER BY random()"),
 * which is a case that can't arise otherwise since clauses containing
 * volatile functions are never considered mergejoinable.  We mark such
 * EquivalenceClasses specially to prevent them from being merged with
 * ordinary EquivalenceClasses.  Also, for volatile expressions we have
 * to be careful to match the EquivalenceClass to the correct targetlist
 * entry: consider SELECT random() AS a, random() AS b ... ORDER BY b,a.
 * So we record the SortGroupRef of the originating sort clause.
 *
 * We allow equality clauses appearing below the nullable side of an outer join
 * to form EquivalenceClasses, but these have a slightly different meaning:
 * the included values might be all NULL rather than all the same non-null
 * values.  See src/backend/optimizer/README for more on that point.
 *
 * NB: if ec_merged isn't NULL, this class has been merged into another, and
 * should be ignored in favor of using the pointed-to class.
 */
typedef struct EquivalenceClass
{
	NodeTag		type;

	List	   *ec_opfamilies;	/* btree operator family OIDs */
	Oid			ec_collation;	/* collation, if datatypes are collatable */
	List	   *ec_members;		/* list of EquivalenceMembers */
	List	   *ec_sources;		/* list of generating RestrictInfos */
	List	   *ec_derives;		/* list of derived RestrictInfos */
	Relids		ec_relids;		/* all relids appearing in ec_members, except
								 * for child members (see below) */
	bool		ec_has_const;	/* any pseudoconstants in ec_members? */
	bool		ec_has_volatile;	/* the (sole) member is a volatile expr */
	bool		ec_below_outer_join;	/* equivalence applies below an OJ */
	bool		ec_broken;		/* failed to generate needed clauses? */
	Index		ec_sortref;		/* originating sortclause label, or 0 */
	Index		ec_min_security;	/* minimum security_level in ec_sources */
	Index		ec_max_security;	/* maximum security_level in ec_sources */
	struct EquivalenceClass *ec_merged; /* set if merged into another EC */
} EquivalenceClass;

/*
 * If an EC contains a const and isn't below-outer-join, any PathKey depending
 * on it must be redundant, since there's only one possible value of the key.
 */
#define EC_MUST_BE_REDUNDANT(eclass)  \
	((eclass)->ec_has_const && !(eclass)->ec_below_outer_join)

/*
 * EquivalenceMember - one member expression of an EquivalenceClass
 *
 * em_is_child signifies that this element was built by transposing a member
 * for an appendrel parent relation to represent the corresponding expression
 * for an appendrel child.  These members are used for determining the
 * pathkeys of scans on the child relation and for explicitly sorting the
 * child when necessary to build a MergeAppend path for the whole appendrel
 * tree.  An em_is_child member has no impact on the properties of the EC as a
 * whole; in particular the EC's ec_relids field does NOT include the child
 * relation.  An em_is_child member should never be marked em_is_const nor
 * cause ec_has_const or ec_has_volatile to be set, either.  Thus, em_is_child
 * members are not really full-fledged members of the EC, but just reflections
 * or doppelgangers of real members.  Most operations on EquivalenceClasses
 * should ignore em_is_child members, and those that don't should test
 * em_relids to make sure they only consider relevant members.
 *
 * em_datatype is usually the same as exprType(em_expr), but can be
 * different when dealing with a binary-compatible opfamily; in particular
 * anyarray_ops would never work without this.  Use em_datatype when
 * looking up a specific btree operator to work with this expression.
 */
typedef struct EquivalenceMember
{
	NodeTag		type;

	Expr	   *em_expr;		/* the expression represented */
	Relids		em_relids;		/* all relids appearing in em_expr */
	Relids		em_nullable_relids; /* nullable by lower outer joins */
	bool		em_is_const;	/* expression is pseudoconstant? */
	bool		em_is_child;	/* derived version for a child relation? */
	Oid			em_datatype;	/* the "nominal type" used by the opfamily */
} EquivalenceMember;

/*
 * PathKeys
 *
 * The sort ordering of a path is represented by a list of PathKey nodes.
 * An empty list implies no known ordering.  Otherwise the first item
 * represents the primary sort key, the second the first secondary sort key,
 * etc.  The value being sorted is represented by linking to an
 * EquivalenceClass containing that value and including pk_opfamily among its
 * ec_opfamilies.  The EquivalenceClass tells which collation to use, too.
 * This is a convenient method because it makes it trivial to detect
 * equivalent and closely-related orderings. (See optimizer/README for more
 * information.)
 *
 * Note: pk_strategy is either BTLessStrategyNumber (for ASC) or
 * BTGreaterStrategyNumber (for DESC).  We assume that all ordering-capable
 * index types will use btree-compatible strategy numbers.
 */
typedef struct PathKey
{
	NodeTag		type;

	EquivalenceClass *pk_eclass;	/* the value that is ordered */
	Oid			pk_opfamily;	/* btree opfamily defining the ordering */
	int			pk_strategy;	/* sort direction (ASC or DESC) */
	bool		pk_nulls_first; /* do NULLs come before normal values? */
} PathKey;

/*
 * VolatileFunctionStatus -- allows nodes to cache their
 * contain_volatile_functions properties. VOLATILITY_UNKNOWN means not yet
 * determined.
 */
typedef enum VolatileFunctionStatus
{
	VOLATILITY_UNKNOWN = 0,
	VOLATILITY_VOLATILE,
	VOLATILITY_NOVOLATILE
} VolatileFunctionStatus;

/*
 * PathTarget
 *
 * This struct contains what we need to know during planning about the
 * targetlist (output columns) that a Path will compute.  Each RelOptInfo
 * includes a default PathTarget, which its individual Paths may simply
 * reference.  However, in some cases a Path may compute outputs different
 * from other Paths, and in that case we make a custom PathTarget for it.
 * For example, an indexscan might return index expressions that would
 * otherwise need to be explicitly calculated.  (Note also that "upper"
 * relations generally don't have useful default PathTargets.)
 *
 * exprs contains bare expressions; they do not have TargetEntry nodes on top,
 * though those will appear in finished Plans.
 *
 * sortgrouprefs[] is an array of the same length as exprs, containing the
 * corresponding sort/group refnos, or zeroes for expressions not referenced
 * by sort/group clauses.  If sortgrouprefs is NULL (which it generally is in
 * RelOptInfo.reltarget targets; only upper-level Paths contain this info),
 * we have not identified sort/group columns in this tlist.  This allows us to
 * deal with sort/group refnos when needed with less expense than including
 * TargetEntry nodes in the exprs list.
 */
typedef struct PathTarget
{
	NodeTag		type;
	List	   *exprs;			/* list of expressions to be computed */
	Index	   *sortgrouprefs;	/* corresponding sort/group refnos, or 0 */
	QualCost	cost;			/* cost of evaluating the expressions */
	int			width;			/* estimated avg width of result tuples */
	VolatileFunctionStatus has_volatile_expr;	/* indicates if exprs contain
												 * any volatile functions. */
} PathTarget;

/* Convenience macro to get a sort/group refno from a PathTarget */
#define get_pathtarget_sortgroupref(target, colno) \
	((target)->sortgrouprefs ? (target)->sortgrouprefs[colno] : (Index) 0)


/*
 * ParamPathInfo
 *
 * All parameterized paths for a given relation with given required outer rels
 * link to a single ParamPathInfo, which stores common information such as
 * the estimated rowcount for this parameterization.  We do this partly to
 * avoid recalculations, but mostly to ensure that the estimated rowcount
 * is in fact the same for every such path.
 *
 * Note: ppi_clauses is only used in ParamPathInfos for base relation paths;
 * in join cases it's NIL because the set of relevant clauses varies depending
 * on how the join is formed.  The relevant clauses will appear in each
 * parameterized join path's joinrestrictinfo list, instead.
 */
typedef struct ParamPathInfo
{
	NodeTag		type;

	Relids		ppi_req_outer;	/* rels supplying parameters used by path */
	Cardinality ppi_rows;		/* estimated number of result tuples */
	List	   *ppi_clauses;	/* join clauses available from outer rels */
} ParamPathInfo;


/*
 * Type "Path" is used as-is for sequential-scan paths, as well as some other
 * simple plan types that we don't need any extra information in the path for.
 * For other path types it is the first component of a larger struct.
 *
 * "pathtype" is the NodeTag of the Plan node we could build from this Path.
 * It is partially redundant with the Path's NodeTag, but allows us to use
 * the same Path type for multiple Plan types when there is no need to
 * distinguish the Plan type during path processing.
 *
 * "parent" identifies the relation this Path scans, and "pathtarget"
 * describes the precise set of output columns the Path would compute.
 * In simple cases all Paths for a given rel share the same targetlist,
 * which we represent by having path->pathtarget equal to parent->reltarget.
 *
 * "param_info", if not NULL, links to a ParamPathInfo that identifies outer
 * relation(s) that provide parameter values to each scan of this path.
 * That means this path can only be joined to those rels by means of nestloop
 * joins with this path on the inside.  Also note that a parameterized path
 * is responsible for testing all "movable" joinclauses involving this rel
 * and the specified outer rel(s).
 *
 * "rows" is the same as parent->rows in simple paths, but in parameterized
 * paths and UniquePaths it can be less than parent->rows, reflecting the
 * fact that we've filtered by extra join conditions or removed duplicates.
 *
 * "pathkeys" is a List of PathKey nodes (see above), describing the sort
 * ordering of the path's output rows.
 */
typedef struct Path
{
	NodeTag		type;

	NodeTag		pathtype;		/* tag identifying scan/join method */

	RelOptInfo *parent;			/* the relation this path can build */
	PathTarget *pathtarget;		/* list of Vars/Exprs, cost, width */

	ParamPathInfo *param_info;	/* parameterization info, or NULL if none */

	bool		parallel_aware; /* engage parallel-aware logic? */
	bool		parallel_safe;	/* OK to use as part of parallel plan? */
	int			parallel_workers;	/* desired # of workers; 0 = not parallel */

	/* estimated size/costs for path (see costsize.c for more info) */
	Cardinality rows;			/* estimated number of result tuples */
	Cost		startup_cost;	/* cost expended before fetching any tuples */
	Cost		total_cost;		/* total cost (assuming all tuples fetched) */

	List	   *pathkeys;		/* sort ordering of path's output */
	/* pathkeys is a List of PathKey nodes; see above */
} Path;

/* Macro for extracting a path's parameterization relids; beware double eval */
#define PATH_REQ_OUTER(path)  \
	((path)->param_info ? (path)->param_info->ppi_req_outer : (Relids) NULL)

/*----------
 * IndexPath represents an index scan over a single index.
 *
 * This struct is used for both regular indexscans and index-only scans;
 * path.pathtype is T_IndexScan or T_IndexOnlyScan to show which is meant.
 *
 * 'indexinfo' is the index to be scanned.
 *
 * 'indexclauses' is a list of IndexClause nodes, each representing one
 * index-checkable restriction, with implicit AND semantics across the list.
 * An empty list implies a full index scan.
 *
 * 'indexorderbys', if not NIL, is a list of ORDER BY expressions that have
 * been found to be usable as ordering operators for an amcanorderbyop index.
 * The list must match the path's pathkeys, ie, one expression per pathkey
 * in the same order.  These are not RestrictInfos, just bare expressions,
 * since they generally won't yield booleans.  It's guaranteed that each
 * expression has the index key on the left side of the operator.
 *
 * 'indexorderbycols' is an integer list of index column numbers (zero-based)
 * of the same length as 'indexorderbys', showing which index column each
 * ORDER BY expression is meant to be used with.  (There is no restriction
 * on which index column each ORDER BY can be used with.)
 *
 * 'indexscandir' is one of:
 *		ForwardScanDirection: forward scan of an ordered index
 *		BackwardScanDirection: backward scan of an ordered index
 *		NoMovementScanDirection: scan of an unordered index, or don't care
 * (The executor doesn't care whether it gets ForwardScanDirection or
 * NoMovementScanDirection for an indexscan, but the planner wants to
 * distinguish ordered from unordered indexes for building pathkeys.)
 *
 * 'indextotalcost' and 'indexselectivity' are saved in the IndexPath so that
 * we need not recompute them when considering using the same index in a
 * bitmap index/heap scan (see BitmapHeapPath).  The costs of the IndexPath
 * itself represent the costs of an IndexScan or IndexOnlyScan plan type.
 *----------
 */
typedef struct IndexPath
{
	Path		path;
	IndexOptInfo *indexinfo;
	List	   *indexclauses;
	List	   *indexorderbys;
	List	   *indexorderbycols;
	ScanDirection indexscandir;
	Cost		indextotalcost;
	Selectivity indexselectivity;
} IndexPath;

/*
 * Each IndexClause references a RestrictInfo node from the query's WHERE
 * or JOIN conditions, and shows how that restriction can be applied to
 * the particular index.  We support both indexclauses that are directly
 * usable by the index machinery, which are typically of the form
 * "indexcol OP pseudoconstant", and those from which an indexable qual
 * can be derived.  The simplest such transformation is that a clause
 * of the form "pseudoconstant OP indexcol" can be commuted to produce an
 * indexable qual (the index machinery expects the indexcol to be on the
 * left always).  Another example is that we might be able to extract an
 * indexable range condition from a LIKE condition, as in "x LIKE 'foo%bar'"
 * giving rise to "x >= 'foo' AND x < 'fop'".  Derivation of such lossy
 * conditions is done by a planner support function attached to the
 * indexclause's top-level function or operator.
 *
 * indexquals is a list of RestrictInfos for the directly-usable index
 * conditions associated with this IndexClause.  In the simplest case
 * it's a one-element list whose member is iclause->rinfo.  Otherwise,
 * it contains one or more directly-usable indexqual conditions extracted
 * from the given clause.  The 'lossy' flag indicates whether the
 * indexquals are semantically equivalent to the original clause, or
 * represent a weaker condition.
 *
 * Normally, indexcol is the index of the single index column the clause
 * works on, and indexcols is NIL.  But if the clause is a RowCompareExpr,
 * indexcol is the index of the leading column, and indexcols is a list of
 * all the affected columns.  (Note that indexcols matches up with the
 * columns of the actual indexable RowCompareExpr in indexquals, which
 * might be different from the original in rinfo.)
 *
 * An IndexPath's IndexClause list is required to be ordered by index
 * column, i.e. the indexcol values must form a nondecreasing sequence.
 * (The order of multiple clauses for the same index column is unspecified.)
 */
typedef struct IndexClause
{
	NodeTag		type;
	struct RestrictInfo *rinfo; /* original restriction or join clause */
	List	   *indexquals;		/* indexqual(s) derived from it */
	bool		lossy;			/* are indexquals a lossy version of clause? */
	AttrNumber	indexcol;		/* index column the clause uses (zero-based) */
	List	   *indexcols;		/* multiple index columns, if RowCompare */
} IndexClause;

/*
 * BitmapHeapPath represents one or more indexscans that generate TID bitmaps
 * instead of directly accessing the heap, followed by AND/OR combinations
 * to produce a single bitmap, followed by a heap scan that uses the bitmap.
 * Note that the output is always considered unordered, since it will come
 * out in physical heap order no matter what the underlying indexes did.
 *
 * The individual indexscans are represented by IndexPath nodes, and any
 * logic on top of them is represented by a tree of BitmapAndPath and
 * BitmapOrPath nodes.  Notice that we can use the same IndexPath node both
 * to represent a regular (or index-only) index scan plan, and as the child
 * of a BitmapHeapPath that represents scanning the same index using a
 * BitmapIndexScan.  The startup_cost and total_cost figures of an IndexPath
 * always represent the costs to use it as a regular (or index-only)
 * IndexScan.  The costs of a BitmapIndexScan can be computed using the
 * IndexPath's indextotalcost and indexselectivity.
 */
typedef struct BitmapHeapPath
{
	Path		path;
	Path	   *bitmapqual;		/* IndexPath, BitmapAndPath, BitmapOrPath */
} BitmapHeapPath;

/*
 * BitmapAndPath represents a BitmapAnd plan node; it can only appear as
 * part of the substructure of a BitmapHeapPath.  The Path structure is
 * a bit more heavyweight than we really need for this, but for simplicity
 * we make it a derivative of Path anyway.
 */
typedef struct BitmapAndPath
{
	Path		path;
	List	   *bitmapquals;	/* IndexPaths and BitmapOrPaths */
	Selectivity bitmapselectivity;
} BitmapAndPath;

/*
 * BitmapOrPath represents a BitmapOr plan node; it can only appear as
 * part of the substructure of a BitmapHeapPath.  The Path structure is
 * a bit more heavyweight than we really need for this, but for simplicity
 * we make it a derivative of Path anyway.
 */
typedef struct BitmapOrPath
{
	Path		path;
	List	   *bitmapquals;	/* IndexPaths and BitmapAndPaths */
	Selectivity bitmapselectivity;
} BitmapOrPath;

/*
 * TidPath represents a scan by TID
 *
 * tidquals is an implicitly OR'ed list of qual expressions of the form
 * "CTID = pseudoconstant", or "CTID = ANY(pseudoconstant_array)",
 * or a CurrentOfExpr for the relation.
 */
typedef struct TidPath
{
	Path		path;
	List	   *tidquals;		/* qual(s) involving CTID = something */
} TidPath;

/*
 * TidRangePath represents a scan by a contiguous range of TIDs
 *
 * tidrangequals is an implicitly AND'ed list of qual expressions of the form
 * "CTID relop pseudoconstant", where relop is one of >,>=,<,<=.
 */
typedef struct TidRangePath
{
	Path		path;
	List	   *tidrangequals;
} TidRangePath;

/*
 * SubqueryScanPath represents a scan of an unflattened subquery-in-FROM
 *
 * Note that the subpath comes from a different planning domain; for example
 * RTE indexes within it mean something different from those known to the
 * SubqueryScanPath.  path.parent->subroot is the planning context needed to
 * interpret the subpath.
 */
typedef struct SubqueryScanPath
{
	Path		path;
	Path	   *subpath;		/* path representing subquery execution */
} SubqueryScanPath;

/*
 * ForeignPath represents a potential scan of a foreign table, foreign join
 * or foreign upper-relation.
 *
 * fdw_private stores FDW private data about the scan.  While fdw_private is
 * not actually touched by the core code during normal operations, it's
 * generally a good idea to use a representation that can be dumped by
 * nodeToString(), so that you can examine the structure during debugging
 * with tools like pprint().
 */
typedef struct ForeignPath
{
	Path		path;
	Path	   *fdw_outerpath;
	List	   *fdw_private;
} ForeignPath;

/*
 * CustomPath represents a table scan done by some out-of-core extension.
 *
 * We provide a set of hooks here - which the provider must take care to set
 * up correctly - to allow extensions to supply their own methods of scanning
 * a relation.  For example, a provider might provide GPU acceleration, a
 * cache-based scan, or some other kind of logic we haven't dreamed up yet.
 *
 * CustomPaths can be injected into the planning process for a relation by
 * set_rel_pathlist_hook functions.
 *
 * Core code must avoid assuming that the CustomPath is only as large as
 * the structure declared here; providers are allowed to make it the first
 * element in a larger structure.  (Since the planner never copies Paths,
 * this doesn't add any complication.)  However, for consistency with the
 * FDW case, we provide a "custom_private" field in CustomPath; providers
 * may prefer to use that rather than define another struct type.
 */

struct CustomPathMethods;

typedef struct CustomPath
{
	Path		path;
	uint32		flags;			/* mask of CUSTOMPATH_* flags, see
								 * nodes/extensible.h */
	List	   *custom_paths;	/* list of child Path nodes, if any */
	List	   *custom_private;
	const struct CustomPathMethods *methods;
} CustomPath;

/*
 * AppendPath represents an Append plan, ie, successive execution of
 * several member plans.
 *
 * For partial Append, 'subpaths' contains non-partial subpaths followed by
 * partial subpaths.
 *
 * Note: it is possible for "subpaths" to contain only one, or even no,
 * elements.  These cases are optimized during create_append_plan.
 * In particular, an AppendPath with no subpaths is a "dummy" path that
 * is created to represent the case that a relation is provably empty.
 * (This is a convenient representation because it means that when we build
 * an appendrel and find that all its children have been excluded, no extra
 * action is needed to recognize the relation as dummy.)
 */
typedef struct AppendPath
{
	Path		path;
	List	   *subpaths;		/* list of component Paths */
	/* Index of first partial path in subpaths; list_length(subpaths) if none */
	int			first_partial_path;
	Cardinality limit_tuples;	/* hard limit on output tuples, or -1 */
} AppendPath;

#define IS_DUMMY_APPEND(p) \
	(IsA((p), AppendPath) && ((AppendPath *) (p))->subpaths == NIL)

/*
 * A relation that's been proven empty will have one path that is dummy
 * (but might have projection paths on top).  For historical reasons,
 * this is provided as a macro that wraps is_dummy_rel().
 */
#define IS_DUMMY_REL(r) is_dummy_rel(r)
extern bool is_dummy_rel(RelOptInfo *rel);

/*
 * MergeAppendPath represents a MergeAppend plan, ie, the merging of sorted
 * results from several member plans to produce similarly-sorted output.
 */
typedef struct MergeAppendPath
{
	Path		path;
	List	   *subpaths;		/* list of component Paths */
	Cardinality limit_tuples;	/* hard limit on output tuples, or -1 */
} MergeAppendPath;

/*
 * GroupResultPath represents use of a Result plan node to compute the
 * output of a degenerate GROUP BY case, wherein we know we should produce
 * exactly one row, which might then be filtered by a HAVING qual.
 *
 * Note that quals is a list of bare clauses, not RestrictInfos.
 */
typedef struct GroupResultPath
{
	Path		path;
	List	   *quals;
} GroupResultPath;

/*
 * MaterialPath represents use of a Material plan node, i.e., caching of
 * the output of its subpath.  This is used when the subpath is expensive
 * and needs to be scanned repeatedly, or when we need mark/restore ability
 * and the subpath doesn't have it.
 */
typedef struct MaterialPath
{
	Path		path;
	Path	   *subpath;
} MaterialPath;

/*
 * MemoizePath represents a Memoize plan node, i.e., a cache that caches
 * tuples from parameterized paths to save the underlying node from having to
 * be rescanned for parameter values which are already cached.
 */
typedef struct MemoizePath
{
	Path		path;
	Path	   *subpath;		/* outerpath to cache tuples from */
	List	   *hash_operators; /* hash operators for each key */
	List	   *param_exprs;	/* cache keys */
	bool		singlerow;		/* true if the cache entry is to be marked as
								 * complete after caching the first record. */
	bool		binary_mode;	/* true when cache key should be compared bit
								 * by bit, false when using hash equality ops */
	Cardinality calls;			/* expected number of rescans */
	uint32		est_entries;	/* The maximum number of entries that the
								 * planner expects will fit in the cache, or 0
								 * if unknown */
} MemoizePath;

/*
 * UniquePath represents elimination of distinct rows from the output of
 * its subpath.
 *
 * This can represent significantly different plans: either hash-based or
 * sort-based implementation, or a no-op if the input path can be proven
 * distinct already.  The decision is sufficiently localized that it's not
 * worth having separate Path node types.  (Note: in the no-op case, we could
 * eliminate the UniquePath node entirely and just return the subpath; but
 * it's convenient to have a UniquePath in the path tree to signal upper-level
 * routines that the input is known distinct.)
 */
typedef enum UniquePathMethod
{
	UNIQUE_PATH_NOOP,			/* input is known unique already */
	UNIQUE_PATH_HASH,			/* use hashing */
	UNIQUE_PATH_SORT			/* use sorting */
} UniquePathMethod;

typedef struct UniquePath
{
	Path		path;
	Path	   *subpath;
	UniquePathMethod umethod;
	List	   *in_operators;	/* equality operators of the IN clause */
	List	   *uniq_exprs;		/* expressions to be made unique */
} UniquePath;

/*
 * GatherPath runs several copies of a plan in parallel and collects the
 * results.  The parallel leader may also execute the plan, unless the
 * single_copy flag is set.
 */
typedef struct GatherPath
{
	Path		path;
	Path	   *subpath;		/* path for each worker */
	bool		single_copy;	/* don't execute path more than once */
	int			num_workers;	/* number of workers sought to help */
} GatherPath;

/*
 * GatherMergePath runs several copies of a plan in parallel and collects
 * the results, preserving their common sort order.
 */
typedef struct GatherMergePath
{
	Path		path;
	Path	   *subpath;		/* path for each worker */
	int			num_workers;	/* number of workers sought to help */
} GatherMergePath;


/*
 * All join-type paths share these fields.
 */

typedef struct JoinPath
{
	Path		path;

	JoinType	jointype;

	bool		inner_unique;	/* each outer tuple provably matches no more
								 * than one inner tuple */

	Path	   *outerjoinpath;	/* path for the outer side of the join */
	Path	   *innerjoinpath;	/* path for the inner side of the join */

	List	   *joinrestrictinfo;	/* RestrictInfos to apply to join */

	/*
	 * See the notes for RelOptInfo and ParamPathInfo to understand why
	 * joinrestrictinfo is needed in JoinPath, and can't be merged into the
	 * parent RelOptInfo.
	 */
} JoinPath;

/*
 * A nested-loop path needs no special fields.
 */

typedef struct NestPath
{
	JoinPath	jpath;
} NestPath;

/*
 * A mergejoin path has these fields.
 *
 * Unlike other path types, a MergePath node doesn't represent just a single
 * run-time plan node: it can represent up to four.  Aside from the MergeJoin
 * node itself, there can be a Sort node for the outer input, a Sort node
 * for the inner input, and/or a Material node for the inner input.  We could
 * represent these nodes by separate path nodes, but considering how many
 * different merge paths are investigated during a complex join problem,
 * it seems better to avoid unnecessary palloc overhead.
 *
 * path_mergeclauses lists the clauses (in the form of RestrictInfos)
 * that will be used in the merge.
 *
 * Note that the mergeclauses are a subset of the parent relation's
 * restriction-clause list.  Any join clauses that are not mergejoinable
 * appear only in the parent's restrict list, and must be checked by a
 * qpqual at execution time.
 *
 * outersortkeys (resp. innersortkeys) is NIL if the outer path
 * (resp. inner path) is already ordered appropriately for the
 * mergejoin.  If it is not NIL then it is a PathKeys list describing
 * the ordering that must be created by an explicit Sort node.
 *
 * skip_mark_restore is true if the executor need not do mark/restore calls.
 * Mark/restore overhead is usually required, but can be skipped if we know
 * that the executor need find only one match per outer tuple, and that the
 * mergeclauses are sufficient to identify a match.  In such cases the
 * executor can immediately advance the outer relation after processing a
 * match, and therefore it need never back up the inner relation.
 *
 * materialize_inner is true if a Material node should be placed atop the
 * inner input.  This may appear with or without an inner Sort step.
 */

typedef struct MergePath
{
	JoinPath	jpath;
	List	   *path_mergeclauses;	/* join clauses to be used for merge */
	List	   *outersortkeys;	/* keys for explicit sort, if any */
	List	   *innersortkeys;	/* keys for explicit sort, if any */
	bool		skip_mark_restore;	/* can executor skip mark/restore? */
	bool		materialize_inner;	/* add Materialize to inner? */
} MergePath;

/*
 * A hashjoin path has these fields.
 *
 * The remarks above for mergeclauses apply for hashclauses as well.
 *
 * Hashjoin does not care what order its inputs appear in, so we have
 * no need for sortkeys.
 */

typedef struct HashPath
{
	JoinPath	jpath;
	List	   *path_hashclauses;	/* join clauses used for hashing */
	int			num_batches;	/* number of batches expected */
	Cardinality inner_rows_total;	/* total inner rows expected */
} HashPath;

/*
 * ProjectionPath represents a projection (that is, targetlist computation)
 *
 * Nominally, this path node represents using a Result plan node to do a
 * projection step.  However, if the input plan node supports projection,
 * we can just modify its output targetlist to do the required calculations
 * directly, and not need a Result.  In some places in the planner we can just
 * jam the desired PathTarget into the input path node (and adjust its cost
 * accordingly), so we don't need a ProjectionPath.  But in other places
 * it's necessary to not modify the input path node, so we need a separate
 * ProjectionPath node, which is marked dummy to indicate that we intend to
 * assign the work to the input plan node.  The estimated cost for the
 * ProjectionPath node will account for whether a Result will be used or not.
 */
typedef struct ProjectionPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	bool		dummypp;		/* true if no separate Result is needed */
} ProjectionPath;

/*
 * ProjectSetPath represents evaluation of a targetlist that includes
 * set-returning function(s), which will need to be implemented by a
 * ProjectSet plan node.
 */
typedef struct ProjectSetPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
} ProjectSetPath;

/*
 * SortPath represents an explicit sort step
 *
 * The sort keys are, by definition, the same as path.pathkeys.
 *
 * Note: the Sort plan node cannot project, so path.pathtarget must be the
 * same as the input's pathtarget.
 */
typedef struct SortPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
} SortPath;

/*
 * IncrementalSortPath represents an incremental sort step
 *
 * This is like a regular sort, except some leading key columns are assumed
 * to be ordered already.
 */
typedef struct IncrementalSortPath
{
	SortPath	spath;
	int			nPresortedCols; /* number of presorted columns */
} IncrementalSortPath;

/*
 * GroupPath represents grouping (of presorted input)
 *
 * groupClause represents the columns to be grouped on; the input path
 * must be at least that well sorted.
 *
 * We can also apply a qual to the grouped rows (equivalent of HAVING)
 */
typedef struct GroupPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	List	   *groupClause;	/* a list of SortGroupClause's */
	List	   *qual;			/* quals (HAVING quals), if any */
} GroupPath;

/*
 * UpperUniquePath represents adjacent-duplicate removal (in presorted input)
 *
 * The columns to be compared are the first numkeys columns of the path's
 * pathkeys.  The input is presumed already sorted that way.
 */
typedef struct UpperUniquePath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	int			numkeys;		/* number of pathkey columns to compare */
} UpperUniquePath;

/*
 * AggPath represents generic computation of aggregate functions
 *
 * This may involve plain grouping (but not grouping sets), using either
 * sorted or hashed grouping; for the AGG_SORTED case, the input must be
 * appropriately presorted.
 */
typedef struct AggPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	AggStrategy aggstrategy;	/* basic strategy, see nodes.h */
	AggSplit	aggsplit;		/* agg-splitting mode, see nodes.h */
	Cardinality numGroups;		/* estimated number of groups in input */
	uint64		transitionSpace;	/* for pass-by-ref transition data */
	List	   *groupClause;	/* a list of SortGroupClause's */
	List	   *qual;			/* quals (HAVING quals), if any */
} AggPath;

/*
 * Various annotations used for grouping sets in the planner.
 */

typedef struct GroupingSetData
{
	NodeTag		type;
	List	   *set;			/* grouping set as list of sortgrouprefs */
	Cardinality numGroups;		/* est. number of result groups */
} GroupingSetData;

typedef struct RollupData
{
	NodeTag		type;
	List	   *groupClause;	/* applicable subset of parse->groupClause */
	List	   *gsets;			/* lists of integer indexes into groupClause */
	List	   *gsets_data;		/* list of GroupingSetData */
	Cardinality numGroups;		/* est. number of result groups */
	bool		hashable;		/* can be hashed */
	bool		is_hashed;		/* to be implemented as a hashagg */
} RollupData;

/*
 * GroupingSetsPath represents a GROUPING SETS aggregation
 */

typedef struct GroupingSetsPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	AggStrategy aggstrategy;	/* basic strategy */
	List	   *rollups;		/* list of RollupData */
	List	   *qual;			/* quals (HAVING quals), if any */
	uint64		transitionSpace;	/* for pass-by-ref transition data */
} GroupingSetsPath;

/*
 * MinMaxAggPath represents computation of MIN/MAX aggregates from indexes
 */
typedef struct MinMaxAggPath
{
	Path		path;
	List	   *mmaggregates;	/* list of MinMaxAggInfo */
	List	   *quals;			/* HAVING quals, if any */
} MinMaxAggPath;

/*
 * WindowAggPath represents generic computation of window functions
 */
typedef struct WindowAggPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	WindowClause *winclause;	/* WindowClause we'll be using */
	List	   *qual;			/* lower-level WindowAgg runconditions */
	bool		topwindow;		/* false for all apart from the WindowAgg
								 * that's closest to the root of the plan */
} WindowAggPath;

/*
 * SetOpPath represents a set-operation, that is INTERSECT or EXCEPT
 */
typedef struct SetOpPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	SetOpCmd	cmd;			/* what to do, see nodes.h */
	SetOpStrategy strategy;		/* how to do it, see nodes.h */
	List	   *distinctList;	/* SortGroupClauses identifying target cols */
	AttrNumber	flagColIdx;		/* where is the flag column, if any */
	int			firstFlag;		/* flag value for first input relation */
	Cardinality numGroups;		/* estimated number of groups in input */
} SetOpPath;

/*
 * RecursiveUnionPath represents a recursive UNION node
 */
typedef struct RecursiveUnionPath
{
	Path		path;
	Path	   *leftpath;		/* paths representing input sources */
	Path	   *rightpath;
	List	   *distinctList;	/* SortGroupClauses identifying target cols */
	int			wtParam;		/* ID of Param representing work table */
	Cardinality numGroups;		/* estimated number of groups in input */
} RecursiveUnionPath;

/*
 * LockRowsPath represents acquiring row locks for SELECT FOR UPDATE/SHARE
 */
typedef struct LockRowsPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	List	   *rowMarks;		/* a list of PlanRowMark's */
	int			epqParam;		/* ID of Param for EvalPlanQual re-eval */
} LockRowsPath;

/*
 * ModifyTablePath represents performing INSERT/UPDATE/DELETE/MERGE
 *
 * We represent most things that will be in the ModifyTable plan node
 * literally, except we have a child Path not Plan.  But analysis of the
 * OnConflictExpr is deferred to createplan.c, as is collection of FDW data.
 */
typedef struct ModifyTablePath
{
	Path		path;
	Path	   *subpath;		/* Path producing source data */
	CmdType		operation;		/* INSERT, UPDATE, DELETE, or MERGE */
	bool		canSetTag;		/* do we set the command tag/es_processed? */
	Index		nominalRelation;	/* Parent RT index for use of EXPLAIN */
	Index		rootRelation;	/* Root RT index, if target is partitioned */
	bool		partColsUpdated;	/* some part key in hierarchy updated? */
	List	   *resultRelations;	/* integer list of RT indexes */
	List	   *updateColnosLists;	/* per-target-table update_colnos lists */
	List	   *withCheckOptionLists;	/* per-target-table WCO lists */
	List	   *returningLists; /* per-target-table RETURNING tlists */
	List	   *rowMarks;		/* PlanRowMarks (non-locking only) */
	OnConflictExpr *onconflict; /* ON CONFLICT clause, or NULL */
	int			epqParam;		/* ID of Param for EvalPlanQual re-eval */
	List	   *mergeActionLists;	/* per-target-table lists of actions for
									 * MERGE */
} ModifyTablePath;

/*
 * LimitPath represents applying LIMIT/OFFSET restrictions
 */
typedef struct LimitPath
{
	Path		path;
	Path	   *subpath;		/* path representing input source */
	Node	   *limitOffset;	/* OFFSET parameter, or NULL if none */
	Node	   *limitCount;		/* COUNT parameter, or NULL if none */
	LimitOption limitOption;	/* FETCH FIRST with ties or exact number */
} LimitPath;


/*
 * Restriction clause info.
 *
 * We create one of these for each AND sub-clause of a restriction condition
 * (WHERE or JOIN/ON clause).  Since the restriction clauses are logically
 * ANDed, we can use any one of them or any subset of them to filter out
 * tuples, without having to evaluate the rest.  The RestrictInfo node itself
 * stores data used by the optimizer while choosing the best query plan.
 *
 * If a restriction clause references a single base relation, it will appear
 * in the baserestrictinfo list of the RelOptInfo for that base rel.
 *
 * If a restriction clause references more than one base rel, it will
 * appear in the joininfo list of every RelOptInfo that describes a strict
 * subset of the base rels mentioned in the clause.  The joininfo lists are
 * used to drive join tree building by selecting plausible join candidates.
 * The clause cannot actually be applied until we have built a join rel
 * containing all the base rels it references, however.
 *
 * When we construct a join rel that includes all the base rels referenced
 * in a multi-relation restriction clause, we place that clause into the
 * joinrestrictinfo lists of paths for the join rel, if neither left nor
 * right sub-path includes all base rels referenced in the clause.  The clause
 * will be applied at that join level, and will not propagate any further up
 * the join tree.  (Note: the "predicate migration" code was once intended to
 * push restriction clauses up and down the plan tree based on evaluation
 * costs, but it's dead code and is unlikely to be resurrected in the
 * foreseeable future.)
 *
 * Note that in the presence of more than two rels, a multi-rel restriction
 * might reach different heights in the join tree depending on the join
 * sequence we use.  So, these clauses cannot be associated directly with
 * the join RelOptInfo, but must be kept track of on a per-join-path basis.
 *
 * RestrictInfos that represent equivalence conditions (i.e., mergejoinable
 * equalities that are not outerjoin-delayed) are handled a bit differently.
 * Initially we attach them to the EquivalenceClasses that are derived from
 * them.  When we construct a scan or join path, we look through all the
 * EquivalenceClasses and generate derived RestrictInfos representing the
 * minimal set of conditions that need to be checked for this particular scan
 * or join to enforce that all members of each EquivalenceClass are in fact
 * equal in all rows emitted by the scan or join.
 *
 * When dealing with outer joins we have to be very careful about pushing qual
 * clauses up and down the tree.  An outer join's own JOIN/ON conditions must
 * be evaluated exactly at that join node, unless they are "degenerate"
 * conditions that reference only Vars from the nullable side of the join.
 * Quals appearing in WHERE or in a JOIN above the outer join cannot be pushed
 * down below the outer join, if they reference any nullable Vars.
 * RestrictInfo nodes contain a flag to indicate whether a qual has been
 * pushed down to a lower level than its original syntactic placement in the
 * join tree would suggest.  If an outer join prevents us from pushing a qual
 * down to its "natural" semantic level (the level associated with just the
 * base rels used in the qual) then we mark the qual with a "required_relids"
 * value including more than just the base rels it actually uses.  By
 * pretending that the qual references all the rels required to form the outer
 * join, we prevent it from being evaluated below the outer join's joinrel.
 * When we do form the outer join's joinrel, we still need to distinguish
 * those quals that are actually in that join's JOIN/ON condition from those
 * that appeared elsewhere in the tree and were pushed down to the join rel
 * because they used no other rels.  That's what the is_pushed_down flag is
 * for; it tells us that a qual is not an OUTER JOIN qual for the set of base
 * rels listed in required_relids.  A clause that originally came from WHERE
 * or an INNER JOIN condition will *always* have its is_pushed_down flag set.
 * It's possible for an OUTER JOIN clause to be marked is_pushed_down too,
 * if we decide that it can be pushed down into the nullable side of the join.
 * In that case it acts as a plain filter qual for wherever it gets evaluated.
 * (In short, is_pushed_down is only false for non-degenerate outer join
 * conditions.  Possibly we should rename it to reflect that meaning?  But
 * see also the comments for RINFO_IS_PUSHED_DOWN, below.)
 *
 * RestrictInfo nodes also contain an outerjoin_delayed flag, which is true
 * if the clause's applicability must be delayed due to any outer joins
 * appearing below it (ie, it has to be postponed to some join level higher
 * than the set of relations it actually references).
 *
 * There is also an outer_relids field, which is NULL except for outer join
 * clauses; for those, it is the set of relids on the outer side of the
 * clause's outer join.  (These are rels that the clause cannot be applied to
 * in parameterized scans, since pushing it into the join's outer side would
 * lead to wrong answers.)
 *
 * There is also a nullable_relids field, which is the set of rels the clause
 * references that can be forced null by some outer join below the clause.
 *
 * outerjoin_delayed = true is subtly different from nullable_relids != NULL:
 * a clause might reference some nullable rels and yet not be
 * outerjoin_delayed because it also references all the other rels of the
 * outer join(s). A clause that is not outerjoin_delayed can be enforced
 * anywhere it is computable.
 *
 * To handle security-barrier conditions efficiently, we mark RestrictInfo
 * nodes with a security_level field, in which higher values identify clauses
 * coming from less-trusted sources.  The exact semantics are that a clause
 * cannot be evaluated before another clause with a lower security_level value
 * unless the first clause is leakproof.  As with outer-join clauses, this
 * creates a reason for clauses to sometimes need to be evaluated higher in
 * the join tree than their contents would suggest; and even at a single plan
 * node, this rule constrains the order of application of clauses.
 *
 * In general, the referenced clause might be arbitrarily complex.  The
 * kinds of clauses we can handle as indexscan quals, mergejoin clauses,
 * or hashjoin clauses are limited (e.g., no volatile functions).  The code
 * for each kind of path is responsible for identifying the restrict clauses
 * it can use and ignoring the rest.  Clauses not implemented by an indexscan,
 * mergejoin, or hashjoin will be placed in the plan qual or joinqual field
 * of the finished Plan node, where they will be enforced by general-purpose
 * qual-expression-evaluation code.  (But we are still entitled to count
 * their selectivity when estimating the result tuple count, if we
 * can guess what it is...)
 *
 * When the referenced clause is an OR clause, we generate a modified copy
 * in which additional RestrictInfo nodes are inserted below the top-level
 * OR/AND structure.  This is a convenience for OR indexscan processing:
 * indexquals taken from either the top level or an OR subclause will have
 * associated RestrictInfo nodes.
 *
 * The can_join flag is set true if the clause looks potentially useful as
 * a merge or hash join clause, that is if it is a binary opclause with
 * nonoverlapping sets of relids referenced in the left and right sides.
 * (Whether the operator is actually merge or hash joinable isn't checked,
 * however.)
 *
 * The pseudoconstant flag is set true if the clause contains no Vars of
 * the current query level and no volatile functions.  Such a clause can be
 * pulled out and used as a one-time qual in a gating Result node.  We keep
 * pseudoconstant clauses in the same lists as other RestrictInfos so that
 * the regular clause-pushing machinery can assign them to the correct join
 * level, but they need to be treated specially for cost and selectivity
 * estimates.  Note that a pseudoconstant clause can never be an indexqual
 * or merge or hash join clause, so it's of no interest to large parts of
 * the planner.
 *
 * When join clauses are generated from EquivalenceClasses, there may be
 * several equally valid ways to enforce join equivalence, of which we need
 * apply only one.  We mark clauses of this kind by setting parent_ec to
 * point to the generating EquivalenceClass.  Multiple clauses with the same
 * parent_ec in the same join are redundant.
 */

typedef struct RestrictInfo
{
	NodeTag		type;

	Expr	   *clause;			/* the represented clause of WHERE or JOIN */

	bool		is_pushed_down; /* true if clause was pushed down in level */

	bool		outerjoin_delayed;	/* true if delayed by lower outer join */

	bool		can_join;		/* see comment above */

	bool		pseudoconstant; /* see comment above */

	bool		leakproof;		/* true if known to contain no leaked Vars */

	VolatileFunctionStatus has_volatile;	/* to indicate if clause contains
											 * any volatile functions. */

	Index		security_level; /* see comment above */

	/* The set of relids (varnos) actually referenced in the clause: */
	Relids		clause_relids;

	/* The set of relids required to evaluate the clause: */
	Relids		required_relids;

	/* If an outer-join clause, the outer-side relations, else NULL: */
	Relids		outer_relids;

	/* The relids used in the clause that are nullable by lower outer joins: */
	Relids		nullable_relids;

	/* These fields are set for any binary opclause: */
	Relids		left_relids;	/* relids in left side of clause */
	Relids		right_relids;	/* relids in right side of clause */

	/* This field is NULL unless clause is an OR clause: */
	Expr	   *orclause;		/* modified clause with RestrictInfos */

	/* This field is NULL unless clause is potentially redundant: */
	EquivalenceClass *parent_ec;	/* generating EquivalenceClass */

	/* cache space for cost and selectivity */
	QualCost	eval_cost;		/* eval cost of clause; -1 if not yet set */
	Selectivity norm_selec;		/* selectivity for "normal" (JOIN_INNER)
								 * semantics; -1 if not yet set; >1 means a
								 * redundant clause */
	Selectivity outer_selec;	/* selectivity for outer join semantics; -1 if
								 * not yet set */

	/* valid if clause is mergejoinable, else NIL */
	List	   *mergeopfamilies;	/* opfamilies containing clause operator */

	/* cache space for mergeclause processing; NULL if not yet set */
	EquivalenceClass *left_ec;	/* EquivalenceClass containing lefthand */
	EquivalenceClass *right_ec; /* EquivalenceClass containing righthand */
	EquivalenceMember *left_em; /* EquivalenceMember for lefthand */
	EquivalenceMember *right_em;	/* EquivalenceMember for righthand */
	List	   *scansel_cache;	/* list of MergeScanSelCache structs */

	/* transient workspace for use while considering a specific join path */
	bool		outer_is_left;	/* T = outer var on left, F = on right */

	/* valid if clause is hashjoinable, else InvalidOid: */
	Oid			hashjoinoperator;	/* copy of clause operator */

	/* cache space for hashclause processing; -1 if not yet set */
	Selectivity left_bucketsize;	/* avg bucketsize of left side */
	Selectivity right_bucketsize;	/* avg bucketsize of right side */
	Selectivity left_mcvfreq;	/* left side's most common val's freq */
	Selectivity right_mcvfreq;	/* right side's most common val's freq */

	/* hash equality operators used for memoize nodes, else InvalidOid */
	Oid			left_hasheqoperator;
	Oid			right_hasheqoperator;
} RestrictInfo;

/*
 * This macro embodies the correct way to test whether a RestrictInfo is
 * "pushed down" to a given outer join, that is, should be treated as a filter
 * clause rather than a join clause at that outer join.  This is certainly so
 * if is_pushed_down is true; but examining that is not sufficient anymore,
 * because outer-join clauses will get pushed down to lower outer joins when
 * we generate a path for the lower outer join that is parameterized by the
 * LHS of the upper one.  We can detect such a clause by noting that its
 * required_relids exceed the scope of the join.
 */
#define RINFO_IS_PUSHED_DOWN(rinfo, joinrelids) \
	((rinfo)->is_pushed_down || \
	 !bms_is_subset((rinfo)->required_relids, joinrelids))

/*
 * Since mergejoinscansel() is a relatively expensive function, and would
 * otherwise be invoked many times while planning a large join tree,
 * we go out of our way to cache its results.  Each mergejoinable
 * RestrictInfo carries a list of the specific sort orderings that have
 * been considered for use with it, and the resulting selectivities.
 */
typedef struct MergeScanSelCache
{
	/* Ordering details (cache lookup key) */
	Oid			opfamily;		/* btree opfamily defining the ordering */
	Oid			collation;		/* collation for the ordering */
	int			strategy;		/* sort direction (ASC or DESC) */
	bool		nulls_first;	/* do NULLs come before normal values? */
	/* Results */
	Selectivity leftstartsel;	/* first-join fraction for clause left side */
	Selectivity leftendsel;		/* last-join fraction for clause left side */
	Selectivity rightstartsel;	/* first-join fraction for clause right side */
	Selectivity rightendsel;	/* last-join fraction for clause right side */
} MergeScanSelCache;

/*
 * Placeholder node for an expression to be evaluated below the top level
 * of a plan tree.  This is used during planning to represent the contained
 * expression.  At the end of the planning process it is replaced by either
 * the contained expression or a Var referring to a lower-level evaluation of
 * the contained expression.  Typically the evaluation occurs below an outer
 * join, and Var references above the outer join might thereby yield NULL
 * instead of the expression value.
 *
 * Although the planner treats this as an expression node type, it is not
 * recognized by the parser or executor, so we declare it here rather than
 * in primnodes.h.
 */

typedef struct PlaceHolderVar
{
	Expr		xpr;
	Expr	   *phexpr;			/* the represented expression */
	Relids		phrels;			/* base relids syntactically within expr src */
	Index		phid;			/* ID for PHV (unique within planner run) */
	Index		phlevelsup;		/* > 0 if PHV belongs to outer query */
} PlaceHolderVar;

/*
 * "Special join" info.
 *
 * One-sided outer joins constrain the order of joining partially but not
 * completely.  We flatten such joins into the planner's top-level list of
 * relations to join, but record information about each outer join in a
 * SpecialJoinInfo struct.  These structs are kept in the PlannerInfo node's
 * join_info_list.
 *
 * Similarly, semijoins and antijoins created by flattening IN (subselect)
 * and EXISTS(subselect) clauses create partial constraints on join order.
 * These are likewise recorded in SpecialJoinInfo structs.
 *
 * We make SpecialJoinInfos for FULL JOINs even though there is no flexibility
 * of planning for them, because this simplifies make_join_rel()'s API.
 *
 * min_lefthand and min_righthand are the sets of base relids that must be
 * available on each side when performing the special join.  lhs_strict is
 * true if the special join's condition cannot succeed when the LHS variables
 * are all NULL (this means that an outer join can commute with upper-level
 * outer joins even if it appears in their RHS).  We don't bother to set
 * lhs_strict for FULL JOINs, however.
 *
 * It is not valid for either min_lefthand or min_righthand to be empty sets;
 * if they were, this would break the logic that enforces join order.
 *
 * syn_lefthand and syn_righthand are the sets of base relids that are
 * syntactically below this special join.  (These are needed to help compute
 * min_lefthand and min_righthand for higher joins.)
 *
 * delay_upper_joins is set true if we detect a pushed-down clause that has
 * to be evaluated after this join is formed (because it references the RHS).
 * Any outer joins that have such a clause and this join in their RHS cannot
 * commute with this join, because that would leave noplace to check the
 * pushed-down clause.  (We don't track this for FULL JOINs, either.)
 *
 * For a semijoin, we also extract the join operators and their RHS arguments
 * and set semi_operators, semi_rhs_exprs, semi_can_btree, and semi_can_hash.
 * This is done in support of possibly unique-ifying the RHS, so we don't
 * bother unless at least one of semi_can_btree and semi_can_hash can be set
 * true.  (You might expect that this information would be computed during
 * join planning; but it's helpful to have it available during planning of
 * parameterized table scans, so we store it in the SpecialJoinInfo structs.)
 *
 * jointype is never JOIN_RIGHT; a RIGHT JOIN is handled by switching
 * the inputs to make it a LEFT JOIN.  So the allowed values of jointype
 * in a join_info_list member are only LEFT, FULL, SEMI, or ANTI.
 *
 * For purposes of join selectivity estimation, we create transient
 * SpecialJoinInfo structures for regular inner joins; so it is possible
 * to have jointype == JOIN_INNER in such a structure, even though this is
 * not allowed within join_info_list.  We also create transient
 * SpecialJoinInfos with jointype == JOIN_INNER for outer joins, since for
 * cost estimation purposes it is sometimes useful to know the join size under
 * plain innerjoin semantics.  Note that lhs_strict, delay_upper_joins, and
 * of course the semi_xxx fields are not set meaningfully within such structs.
 */
#ifndef HAVE_SPECIALJOININFO_TYPEDEF
typedef struct SpecialJoinInfo SpecialJoinInfo;
#define HAVE_SPECIALJOININFO_TYPEDEF 1
#endif

struct SpecialJoinInfo
{
	NodeTag		type;
	Relids		min_lefthand;	/* base relids in minimum LHS for join */
	Relids		min_righthand;	/* base relids in minimum RHS for join */
	Relids		syn_lefthand;	/* base relids syntactically within LHS */
	Relids		syn_righthand;	/* base relids syntactically within RHS */
	JoinType	jointype;		/* always INNER, LEFT, FULL, SEMI, or ANTI */
	bool		lhs_strict;		/* joinclause is strict for some LHS rel */
	bool		delay_upper_joins;	/* can't commute with upper RHS */
	/* Remaining fields are set only for JOIN_SEMI jointype: */
	bool		semi_can_btree; /* true if semi_operators are all btree */
	bool		semi_can_hash;	/* true if semi_operators are all hash */
	List	   *semi_operators; /* OIDs of equality join operators */
	List	   *semi_rhs_exprs; /* righthand-side expressions of these ops */
};

/*
 * Append-relation info.
 *
 * When we expand an inheritable table or a UNION-ALL subselect into an
 * "append relation" (essentially, a list of child RTEs), we build an
 * AppendRelInfo for each child RTE.  The list of AppendRelInfos indicates
 * which child RTEs must be included when expanding the parent, and each node
 * carries information needed to translate between columns of the parent and
 * columns of the child.
 *
 * These structs are kept in the PlannerInfo node's append_rel_list, with
 * append_rel_array[] providing a convenient lookup method for the struct
 * associated with a particular child relid (there can be only one, though
 * parent rels may have many entries in append_rel_list).
 *
 * Note: after completion of the planner prep phase, any given RTE is an
 * append parent having entries in append_rel_list if and only if its
 * "inh" flag is set.  We clear "inh" for plain tables that turn out not
 * to have inheritance children, and (in an abuse of the original meaning
 * of the flag) we set "inh" for subquery RTEs that turn out to be
 * flattenable UNION ALL queries.  This lets us avoid useless searches
 * of append_rel_list.
 *
 * Note: the data structure assumes that append-rel members are single
 * baserels.  This is OK for inheritance, but it prevents us from pulling
 * up a UNION ALL member subquery if it contains a join.  While that could
 * be fixed with a more complex data structure, at present there's not much
 * point because no improvement in the plan could result.
 */

typedef struct AppendRelInfo
{
	NodeTag		type;

	/*
	 * These fields uniquely identify this append relationship.  There can be
	 * (in fact, always should be) multiple AppendRelInfos for the same
	 * parent_relid, but never more than one per child_relid, since a given
	 * RTE cannot be a child of more than one append parent.
	 */
	Index		parent_relid;	/* RT index of append parent rel */
	Index		child_relid;	/* RT index of append child rel */

	/*
	 * For an inheritance appendrel, the parent and child are both regular
	 * relations, and we store their rowtype OIDs here for use in translating
	 * whole-row Vars.  For a UNION-ALL appendrel, the parent and child are
	 * both subqueries with no named rowtype, and we store InvalidOid here.
	 */
	Oid			parent_reltype; /* OID of parent's composite type */
	Oid			child_reltype;	/* OID of child's composite type */

	/*
	 * The N'th element of this list is a Var or expression representing the
	 * child column corresponding to the N'th column of the parent. This is
	 * used to translate Vars referencing the parent rel into references to
	 * the child.  A list element is NULL if it corresponds to a dropped
	 * column of the parent (this is only possible for inheritance cases, not
	 * UNION ALL).  The list elements are always simple Vars for inheritance
	 * cases, but can be arbitrary expressions in UNION ALL cases.
	 *
	 * Notice we only store entries for user columns (attno > 0).  Whole-row
	 * Vars are special-cased, and system columns (attno < 0) need no special
	 * translation since their attnos are the same for all tables.
	 *
	 * Caution: the Vars have varlevelsup = 0.  Be careful to adjust as needed
	 * when copying into a subquery.
	 */
	List	   *translated_vars;	/* Expressions in the child's Vars */

	/*
	 * This array simplifies translations in the reverse direction, from
	 * child's column numbers to parent's.  The entry at [ccolno - 1] is the
	 * 1-based parent column number for child column ccolno, or zero if that
	 * child column is dropped or doesn't exist in the parent.
	 */
	int			num_child_cols; /* length of array */
	AttrNumber *parent_colnos;	/* array of parent attnos, or zeroes */

	/*
	 * We store the parent table's OID here for inheritance, or InvalidOid for
	 * UNION ALL.  This is only needed to help in generating error messages if
	 * an attempt is made to reference a dropped parent column.
	 */
	Oid			parent_reloid;	/* OID of parent relation */
} AppendRelInfo;

/*
 * Information about a row-identity "resjunk" column in UPDATE/DELETE/MERGE.
 *
 * In partitioned UPDATE/DELETE/MERGE it's important for child partitions to
 * share row-identity columns whenever possible, so as not to chew up too many
 * targetlist columns.  We use these structs to track which identity columns
 * have been requested.  In the finished plan, each of these will give rise
 * to one resjunk entry in the targetlist of the ModifyTable's subplan node.
 *
 * All the Vars stored in RowIdentityVarInfos must have varno ROWID_VAR, for
 * convenience of detecting duplicate requests.  We'll replace that, in the
 * final plan, with the varno of the generating rel.
 *
 * Outside this list, a Var with varno ROWID_VAR and varattno k is a reference
 * to the k-th element of the row_identity_vars list (k counting from 1).
 * We add such a reference to root->processed_tlist when creating the entry,
 * and it propagates into the plan tree from there.
 */
typedef struct RowIdentityVarInfo
{
	NodeTag		type;

	Var		   *rowidvar;		/* Var to be evaluated (but varno=ROWID_VAR) */
	int32		rowidwidth;		/* estimated average width */
	char	   *rowidname;		/* name of the resjunk column */
	Relids		rowidrels;		/* RTE indexes of target rels using this */
} RowIdentityVarInfo;

/*
 * For each distinct placeholder expression generated during planning, we
 * store a PlaceHolderInfo node in the PlannerInfo node's placeholder_list.
 * This stores info that is needed centrally rather than in each copy of the
 * PlaceHolderVar.  The phid fields identify which PlaceHolderInfo goes with
 * each PlaceHolderVar.  Note that phid is unique throughout a planner run,
 * not just within a query level --- this is so that we need not reassign ID's
 * when pulling a subquery into its parent.
 *
 * The idea is to evaluate the expression at (only) the ph_eval_at join level,
 * then allow it to bubble up like a Var until the ph_needed join level.
 * ph_needed has the same definition as attr_needed for a regular Var.
 *
 * The PlaceHolderVar's expression might contain LATERAL references to vars
 * coming from outside its syntactic scope.  If so, those rels are *not*
 * included in ph_eval_at, but they are recorded in ph_lateral.
 *
 * Notice that when ph_eval_at is a join rather than a single baserel, the
 * PlaceHolderInfo may create constraints on join order: the ph_eval_at join
 * has to be formed below any outer joins that should null the PlaceHolderVar.
 *
 * We create a PlaceHolderInfo only after determining that the PlaceHolderVar
 * is actually referenced in the plan tree, so that unreferenced placeholders
 * don't result in unnecessary constraints on join order.
 */

typedef struct PlaceHolderInfo
{
	NodeTag		type;

	Index		phid;			/* ID for PH (unique within planner run) */
	PlaceHolderVar *ph_var;		/* copy of PlaceHolderVar tree */
	Relids		ph_eval_at;		/* lowest level we can evaluate value at */
	Relids		ph_lateral;		/* relids of contained lateral refs, if any */
	Relids		ph_needed;		/* highest level the value is needed at */
	int32		ph_width;		/* estimated attribute width */
} PlaceHolderInfo;

/*
 * This struct describes one potentially index-optimizable MIN/MAX aggregate
 * function.  MinMaxAggPath contains a list of these, and if we accept that
 * path, the list is stored into root->minmax_aggs for use during setrefs.c.
 */
typedef struct MinMaxAggInfo
{
	NodeTag		type;

	Oid			aggfnoid;		/* pg_proc Oid of the aggregate */
	Oid			aggsortop;		/* Oid of its sort operator */
	Expr	   *target;			/* expression we are aggregating on */
	PlannerInfo *subroot;		/* modified "root" for planning the subquery */
	Path	   *path;			/* access path for subquery */
	Cost		pathcost;		/* estimated cost to fetch first row */
	Param	   *param;			/* param for subplan's output */
} MinMaxAggInfo;

/*
 * At runtime, PARAM_EXEC slots are used to pass values around from one plan
 * node to another.  They can be used to pass values down into subqueries (for
 * outer references in subqueries), or up out of subqueries (for the results
 * of a subplan), or from a NestLoop plan node into its inner relation (when
 * the inner scan is parameterized with values from the outer relation).
 * The planner is responsible for assigning nonconflicting PARAM_EXEC IDs to
 * the PARAM_EXEC Params it generates.
 *
 * Outer references are managed via root->plan_params, which is a list of
 * PlannerParamItems.  While planning a subquery, each parent query level's
 * plan_params contains the values required from it by the current subquery.
 * During create_plan(), we use plan_params to track values that must be
 * passed from outer to inner sides of NestLoop plan nodes.
 *
 * The item a PlannerParamItem represents can be one of three kinds:
 *
 * A Var: the slot represents a variable of this level that must be passed
 * down because subqueries have outer references to it, or must be passed
 * from a NestLoop node to its inner scan.  The varlevelsup value in the Var
 * will always be zero.
 *
 * A PlaceHolderVar: this works much like the Var case, except that the
 * entry is a PlaceHolderVar node with a contained expression.  The PHV
 * will have phlevelsup = 0, and the contained expression is adjusted
 * to match in level.
 *
 * An Aggref (with an expression tree representing its argument): the slot
 * represents an aggregate expression that is an outer reference for some
 * subquery.  The Aggref itself has agglevelsup = 0, and its argument tree
 * is adjusted to match in level.
 *
 * Note: we detect duplicate Var and PlaceHolderVar parameters and coalesce
 * them into one slot, but we do not bother to do that for Aggrefs.
 * The scope of duplicate-elimination only extends across the set of
 * parameters passed from one query level into a single subquery, or for
 * nestloop parameters across the set of nestloop parameters used in a single
 * query level.  So there is no possibility of a PARAM_EXEC slot being used
 * for conflicting purposes.
 *
 * In addition, PARAM_EXEC slots are assigned for Params representing outputs
 * from subplans (values that are setParam items for those subplans).  These
 * IDs need not be tracked via PlannerParamItems, since we do not need any
 * duplicate-elimination nor later processing of the represented expressions.
 * Instead, we just record the assignment of the slot number by appending to
 * root->glob->paramExecTypes.
 */
typedef struct PlannerParamItem
{
	NodeTag		type;

	Node	   *item;			/* the Var, PlaceHolderVar, or Aggref */
	int			paramId;		/* its assigned PARAM_EXEC slot number */
} PlannerParamItem;

/*
 * When making cost estimates for a SEMI/ANTI/inner_unique join, there are
 * some correction factors that are needed in both nestloop and hash joins
 * to account for the fact that the executor can stop scanning inner rows
 * as soon as it finds a match to the current outer row.  These numbers
 * depend only on the selected outer and inner join relations, not on the
 * particular paths used for them, so it's worthwhile to calculate them
 * just once per relation pair not once per considered path.  This struct
 * is filled by compute_semi_anti_join_factors and must be passed along
 * to the join cost estimation functions.
 *
 * outer_match_frac is the fraction of the outer tuples that are
 *		expected to have at least one match.
 * match_count is the average number of matches expected for
 *		outer tuples that have at least one match.
 */
typedef struct SemiAntiJoinFactors
{
	Selectivity outer_match_frac;
	Selectivity match_count;
} SemiAntiJoinFactors;

/*
 * Struct for extra information passed to subroutines of add_paths_to_joinrel
 *
 * restrictlist contains all of the RestrictInfo nodes for restriction
 *		clauses that apply to this join
 * mergeclause_list is a list of RestrictInfo nodes for available
 *		mergejoin clauses in this join
 * inner_unique is true if each outer tuple provably matches no more
 *		than one inner tuple
 * sjinfo is extra info about special joins for selectivity estimation
 * semifactors is as shown above (only valid for SEMI/ANTI/inner_unique joins)
 * param_source_rels are OK targets for parameterization of result paths
 */
typedef struct JoinPathExtraData
{
	List	   *restrictlist;
	List	   *mergeclause_list;
	bool		inner_unique;
	SpecialJoinInfo *sjinfo;
	SemiAntiJoinFactors semifactors;
	Relids		param_source_rels;
} JoinPathExtraData;

/*
 * Various flags indicating what kinds of grouping are possible.
 *
 * GROUPING_CAN_USE_SORT should be set if it's possible to perform
 * sort-based implementations of grouping.  When grouping sets are in use,
 * this will be true if sorting is potentially usable for any of the grouping
 * sets, even if it's not usable for all of them.
 *
 * GROUPING_CAN_USE_HASH should be set if it's possible to perform
 * hash-based implementations of grouping.
 *
 * GROUPING_CAN_PARTIAL_AGG should be set if the aggregation is of a type
 * for which we support partial aggregation (not, for example, grouping sets).
 * It says nothing about parallel-safety or the availability of suitable paths.
 */
#define GROUPING_CAN_USE_SORT       0x0001
#define GROUPING_CAN_USE_HASH       0x0002
#define GROUPING_CAN_PARTIAL_AGG	0x0004

/*
 * What kind of partitionwise aggregation is in use?
 *
 * PARTITIONWISE_AGGREGATE_NONE: Not used.
 *
 * PARTITIONWISE_AGGREGATE_FULL: Aggregate each partition separately, and
 * append the results.
 *
 * PARTITIONWISE_AGGREGATE_PARTIAL: Partially aggregate each partition
 * separately, append the results, and then finalize aggregation.
 */
typedef enum
{
	PARTITIONWISE_AGGREGATE_NONE,
	PARTITIONWISE_AGGREGATE_FULL,
	PARTITIONWISE_AGGREGATE_PARTIAL
} PartitionwiseAggregateType;

/*
 * Struct for extra information passed to subroutines of create_grouping_paths
 *
 * flags indicating what kinds of grouping are possible.
 * partial_costs_set is true if the agg_partial_costs and agg_final_costs
 * 		have been initialized.
 * agg_partial_costs gives partial aggregation costs.
 * agg_final_costs gives finalization costs.
 * target_parallel_safe is true if target is parallel safe.
 * havingQual gives list of quals to be applied after aggregation.
 * targetList gives list of columns to be projected.
 * patype is the type of partitionwise aggregation that is being performed.
 */
typedef struct
{
	/* Data which remains constant once set. */
	int			flags;
	bool		partial_costs_set;
	AggClauseCosts agg_partial_costs;
	AggClauseCosts agg_final_costs;

	/* Data which may differ across partitions. */
	bool		target_parallel_safe;
	Node	   *havingQual;
	List	   *targetList;
	PartitionwiseAggregateType patype;
} GroupPathExtraData;

/*
 * Struct for extra information passed to subroutines of grouping_planner
 *
 * limit_needed is true if we actually need a Limit plan node.
 * limit_tuples is an estimated bound on the number of output tuples,
 *		or -1 if no LIMIT or couldn't estimate.
 * count_est and offset_est are the estimated values of the LIMIT and OFFSET
 * 		expressions computed by preprocess_limit() (see comments for
 * 		preprocess_limit() for more information).
 */
typedef struct
{
	bool		limit_needed;
	Cardinality limit_tuples;
	int64		count_est;
	int64		offset_est;
} FinalPathExtraData;

/*
 * For speed reasons, cost estimation for join paths is performed in two
 * phases: the first phase tries to quickly derive a lower bound for the
 * join cost, and then we check if that's sufficient to reject the path.
 * If not, we come back for a more refined cost estimate.  The first phase
 * fills a JoinCostWorkspace struct with its preliminary cost estimates
 * and possibly additional intermediate values.  The second phase takes
 * these values as inputs to avoid repeating work.
 *
 * (Ideally we'd declare this in cost.h, but it's also needed in pathnode.h,
 * so seems best to put it here.)
 */
typedef struct JoinCostWorkspace
{
	/* Preliminary cost estimates --- must not be larger than final ones! */
	Cost		startup_cost;	/* cost expended before fetching any tuples */
	Cost		total_cost;		/* total cost (assuming all tuples fetched) */

	/* Fields below here should be treated as private to costsize.c */
	Cost		run_cost;		/* non-startup cost components */

	/* private for cost_nestloop code */
	Cost		inner_run_cost; /* also used by cost_mergejoin code */
	Cost		inner_rescan_run_cost;

	/* private for cost_mergejoin code */
	Cardinality outer_rows;
	Cardinality inner_rows;
	Cardinality outer_skip_rows;
	Cardinality inner_skip_rows;

	/* private for cost_hashjoin code */
	int			numbuckets;
	int			numbatches;
	Cardinality inner_rows_total;
} JoinCostWorkspace;

/*
 * AggInfo holds information about an aggregate that needs to be computed.
 * Multiple Aggrefs in a query can refer to the same AggInfo by having the
 * same 'aggno' value, so that the aggregate is computed only once.
 */
typedef struct AggInfo
{
	/*
	 * Link to an Aggref expr this state value is for.
	 *
	 * There can be multiple identical Aggref's sharing the same per-agg. This
	 * points to the first one of them.
	 */
	Aggref	   *representative_aggref;

	int			transno;

	/*
	 * "shareable" is false if this agg cannot share state values with other
	 * aggregates because the final function is read-write.
	 */
	bool		shareable;

	/* Oid of the final function or InvalidOid */
	Oid			finalfn_oid;

} AggInfo;

/*
 * AggTransInfo holds information about transition state that is used by one
 * or more aggregates in the query.  Multiple aggregates can share the same
 * transition state, if they have the same inputs and the same transition
 * function.  Aggrefs that share the same transition info have the same
 * 'aggtransno' value.
 */
typedef struct AggTransInfo
{
	List	   *args;
	Expr	   *aggfilter;

	/* Oid of the state transition function */
	Oid			transfn_oid;

	/* Oid of the serialization function or InvalidOid */
	Oid			serialfn_oid;

	/* Oid of the deserialization function or InvalidOid */
	Oid			deserialfn_oid;

	/* Oid of the combine function or InvalidOid */
	Oid			combinefn_oid;

	/* Oid of state value's datatype */
	Oid			aggtranstype;
	int32		aggtranstypmod;
	int			transtypeLen;
	bool		transtypeByVal;
	int32		aggtransspace;

	/*
	 * initial value from pg_aggregate entry
	 */
	Datum		initValue;
	bool		initValueIsNull;

} AggTransInfo;

#endif							/* PATHNODES_H */
