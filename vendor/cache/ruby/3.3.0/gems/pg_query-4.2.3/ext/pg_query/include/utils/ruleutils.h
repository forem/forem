/*-------------------------------------------------------------------------
 *
 * ruleutils.h
 *		Declarations for ruleutils.c
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/ruleutils.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef RULEUTILS_H
#define RULEUTILS_H

#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"

struct Plan;					/* avoid including plannodes.h here */
struct PlannedStmt;


extern char *pg_get_indexdef_string(Oid indexrelid);
extern char *pg_get_indexdef_columns(Oid indexrelid, bool pretty);
extern char *pg_get_querydef(Query *query, bool pretty);

extern char *pg_get_partkeydef_columns(Oid relid, bool pretty);
extern char *pg_get_partconstrdef_string(Oid partitionId, char *aliasname);

extern char *pg_get_constraintdef_command(Oid constraintId);
extern char *deparse_expression(Node *expr, List *dpcontext,
								bool forceprefix, bool showimplicit);
extern List *deparse_context_for(const char *aliasname, Oid relid);
extern List *deparse_context_for_plan_tree(struct PlannedStmt *pstmt,
										   List *rtable_names);
extern List *set_deparse_context_plan(List *dpcontext,
									  struct Plan *plan, List *ancestors);
extern List *select_rtable_names_for_explain(List *rtable,
											 Bitmapset *rels_used);
extern char *generate_collation_name(Oid collid);
extern char *generate_opclass_name(Oid opclass);
extern char *get_range_partbound_string(List *bound_datums);

extern char *pg_get_statisticsobjdef_string(Oid statextid);

#endif							/* RULEUTILS_H */
