/*-------------------------------------------------------------------------
 *
 * parse_relation.h
 *	  prototypes for parse_relation.c.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/parser/parse_relation.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PARSE_RELATION_H
#define PARSE_RELATION_H

#include "parser/parse_node.h"


extern ParseNamespaceItem *refnameNamespaceItem(ParseState *pstate,
												const char *schemaname,
												const char *refname,
												int location,
												int *sublevels_up);
extern CommonTableExpr *scanNameSpaceForCTE(ParseState *pstate,
											const char *refname,
											Index *ctelevelsup);
extern bool scanNameSpaceForENR(ParseState *pstate, const char *refname);
extern void checkNameSpaceConflicts(ParseState *pstate, List *namespace1,
									List *namespace2);
extern ParseNamespaceItem *GetNSItemByRangeTablePosn(ParseState *pstate,
													 int varno,
													 int sublevels_up);
extern RangeTblEntry *GetRTEByRangeTablePosn(ParseState *pstate,
											 int varno,
											 int sublevels_up);
extern CommonTableExpr *GetCTEForRTE(ParseState *pstate, RangeTblEntry *rte,
									 int rtelevelsup);
extern Node *scanNSItemForColumn(ParseState *pstate, ParseNamespaceItem *nsitem,
								 int sublevels_up, const char *colname,
								 int location);
extern Node *colNameToVar(ParseState *pstate, const char *colname, bool localonly,
						  int location);
extern void markVarForSelectPriv(ParseState *pstate, Var *var);
extern Relation parserOpenTable(ParseState *pstate, const RangeVar *relation,
								int lockmode);
extern ParseNamespaceItem *addRangeTableEntry(ParseState *pstate,
											  RangeVar *relation,
											  Alias *alias,
											  bool inh,
											  bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForRelation(ParseState *pstate,
														 Relation rel,
														 int lockmode,
														 Alias *alias,
														 bool inh,
														 bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForSubquery(ParseState *pstate,
														 Query *subquery,
														 Alias *alias,
														 bool lateral,
														 bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForFunction(ParseState *pstate,
														 List *funcnames,
														 List *funcexprs,
														 List *coldeflists,
														 RangeFunction *rangefunc,
														 bool lateral,
														 bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForValues(ParseState *pstate,
													   List *exprs,
													   List *coltypes,
													   List *coltypmods,
													   List *colcollations,
													   Alias *alias,
													   bool lateral,
													   bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForTableFunc(ParseState *pstate,
														  TableFunc *tf,
														  Alias *alias,
														  bool lateral,
														  bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForJoin(ParseState *pstate,
													 List *colnames,
													 ParseNamespaceColumn *nscolumns,
													 JoinType jointype,
													 int nummergedcols,
													 List *aliasvars,
													 List *leftcols,
													 List *rightcols,
													 Alias *joinalias,
													 Alias *alias,
													 bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForCTE(ParseState *pstate,
													CommonTableExpr *cte,
													Index levelsup,
													RangeVar *rv,
													bool inFromCl);
extern ParseNamespaceItem *addRangeTableEntryForENR(ParseState *pstate,
													RangeVar *rv,
													bool inFromCl);
extern bool isLockedRefname(ParseState *pstate, const char *refname);
extern void addNSItemToQuery(ParseState *pstate, ParseNamespaceItem *nsitem,
							 bool addToJoinList,
							 bool addToRelNameSpace, bool addToVarNameSpace);
extern void errorMissingRTE(ParseState *pstate, RangeVar *relation) pg_attribute_noreturn();
extern void errorMissingColumn(ParseState *pstate,
							   const char *relname, const char *colname, int location) pg_attribute_noreturn();
extern void expandRTE(RangeTblEntry *rte, int rtindex, int sublevels_up,
					  int location, bool include_dropped,
					  List **colnames, List **colvars);
extern List *expandNSItemVars(ParseNamespaceItem *nsitem,
							  int sublevels_up, int location,
							  List **colnames);
extern List *expandNSItemAttrs(ParseState *pstate, ParseNamespaceItem *nsitem,
							   int sublevels_up, bool require_col_privs,
							   int location);
extern int	attnameAttNum(Relation rd, const char *attname, bool sysColOK);
extern const NameData *attnumAttName(Relation rd, int attid);
extern Oid	attnumTypeId(Relation rd, int attid);
extern Oid	attnumCollationId(Relation rd, int attid);
extern bool isQueryUsingTempRelation(Query *query);

#endif							/* PARSE_RELATION_H */
