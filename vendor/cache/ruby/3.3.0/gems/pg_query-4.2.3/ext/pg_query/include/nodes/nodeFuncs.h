/*-------------------------------------------------------------------------
 *
 * nodeFuncs.h
 *		Various general-purpose manipulations of Node trees
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/nodes/nodeFuncs.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef NODEFUNCS_H
#define NODEFUNCS_H

#include "nodes/parsenodes.h"


/* flags bits for query_tree_walker and query_tree_mutator */
#define QTW_IGNORE_RT_SUBQUERIES	0x01	/* subqueries in rtable */
#define QTW_IGNORE_CTE_SUBQUERIES	0x02	/* subqueries in cteList */
#define QTW_IGNORE_RC_SUBQUERIES	0x03	/* both of above */
#define QTW_IGNORE_JOINALIASES		0x04	/* JOIN alias var lists */
#define QTW_IGNORE_RANGE_TABLE		0x08	/* skip rangetable entirely */
#define QTW_EXAMINE_RTES_BEFORE		0x10	/* examine RTE nodes before their
											 * contents */
#define QTW_EXAMINE_RTES_AFTER		0x20	/* examine RTE nodes after their
											 * contents */
#define QTW_DONT_COPY_QUERY			0x40	/* do not copy top Query */
#define QTW_EXAMINE_SORTGROUP		0x80	/* include SortGroupNode lists */

/* callback function for check_functions_in_node */
typedef bool (*check_function_callback) (Oid func_id, void *context);


extern Oid	exprType(const Node *expr);
extern int32 exprTypmod(const Node *expr);
extern bool exprIsLengthCoercion(const Node *expr, int32 *coercedTypmod);
extern Node *applyRelabelType(Node *arg, Oid rtype, int32 rtypmod, Oid rcollid,
							  CoercionForm rformat, int rlocation,
							  bool overwrite_ok);
extern Node *relabel_to_typmod(Node *expr, int32 typmod);
extern Node *strip_implicit_coercions(Node *node);
extern bool expression_returns_set(Node *clause);

extern Oid	exprCollation(const Node *expr);
extern Oid	exprInputCollation(const Node *expr);
extern void exprSetCollation(Node *expr, Oid collation);
extern void exprSetInputCollation(Node *expr, Oid inputcollation);

extern int	exprLocation(const Node *expr);

extern void fix_opfuncids(Node *node);
extern void set_opfuncid(OpExpr *opexpr);
extern void set_sa_opfuncid(ScalarArrayOpExpr *opexpr);

/* Is clause a FuncExpr clause? */
static inline bool
is_funcclause(const void *clause)
{
	return clause != NULL && IsA(clause, FuncExpr);
}

/* Is clause an OpExpr clause? */
static inline bool
is_opclause(const void *clause)
{
	return clause != NULL && IsA(clause, OpExpr);
}

/* Extract left arg of a binary opclause, or only arg of a unary opclause */
static inline Node *
get_leftop(const void *clause)
{
	const OpExpr *expr = (const OpExpr *) clause;

	if (expr->args != NIL)
		return (Node *) linitial(expr->args);
	else
		return NULL;
}

/* Extract right arg of a binary opclause (NULL if it's a unary opclause) */
static inline Node *
get_rightop(const void *clause)
{
	const OpExpr *expr = (const OpExpr *) clause;

	if (list_length(expr->args) >= 2)
		return (Node *) lsecond(expr->args);
	else
		return NULL;
}

/* Is clause an AND clause? */
static inline bool
is_andclause(const void *clause)
{
	return (clause != NULL &&
			IsA(clause, BoolExpr) &&
			((const BoolExpr *) clause)->boolop == AND_EXPR);
}

/* Is clause an OR clause? */
static inline bool
is_orclause(const void *clause)
{
	return (clause != NULL &&
			IsA(clause, BoolExpr) &&
			((const BoolExpr *) clause)->boolop == OR_EXPR);
}

/* Is clause a NOT clause? */
static inline bool
is_notclause(const void *clause)
{
	return (clause != NULL &&
			IsA(clause, BoolExpr) &&
			((const BoolExpr *) clause)->boolop == NOT_EXPR);
}

/* Extract argument from a clause known to be a NOT clause */
static inline Expr *
get_notclausearg(const void *notclause)
{
	return (Expr *) linitial(((const BoolExpr *) notclause)->args);
}

extern bool check_functions_in_node(Node *node, check_function_callback checker,
									void *context);

extern bool expression_tree_walker(Node *node, bool (*walker) (),
								   void *context);
extern Node *expression_tree_mutator(Node *node, Node *(*mutator) (),
									 void *context);

extern bool query_tree_walker(Query *query, bool (*walker) (),
							  void *context, int flags);
extern Query *query_tree_mutator(Query *query, Node *(*mutator) (),
								 void *context, int flags);

extern bool range_table_walker(List *rtable, bool (*walker) (),
							   void *context, int flags);
extern List *range_table_mutator(List *rtable, Node *(*mutator) (),
								 void *context, int flags);

extern bool range_table_entry_walker(RangeTblEntry *rte, bool (*walker) (),
									 void *context, int flags);

extern bool query_or_expression_tree_walker(Node *node, bool (*walker) (),
											void *context, int flags);
extern Node *query_or_expression_tree_mutator(Node *node, Node *(*mutator) (),
											  void *context, int flags);

extern bool raw_expression_tree_walker(Node *node, bool (*walker) (),
									   void *context);

struct PlanState;
extern bool planstate_tree_walker(struct PlanState *planstate, bool (*walker) (),
								  void *context);

#endif							/* NODEFUNCS_H */
