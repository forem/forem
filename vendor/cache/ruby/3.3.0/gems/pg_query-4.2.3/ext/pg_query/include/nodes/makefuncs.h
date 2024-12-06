/*-------------------------------------------------------------------------
 *
 * makefuncs.h
 *	  prototypes for the creator functions of various nodes
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/nodes/makefuncs.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef MAKEFUNC_H
#define MAKEFUNC_H

#include "nodes/execnodes.h"
#include "nodes/parsenodes.h"


extern A_Expr *makeA_Expr(A_Expr_Kind kind, List *name,
						  Node *lexpr, Node *rexpr, int location);

extern A_Expr *makeSimpleA_Expr(A_Expr_Kind kind, char *name,
								Node *lexpr, Node *rexpr, int location);

extern Var *makeVar(int varno,
					AttrNumber varattno,
					Oid vartype,
					int32 vartypmod,
					Oid varcollid,
					Index varlevelsup);

extern Var *makeVarFromTargetEntry(int varno,
								   TargetEntry *tle);

extern Var *makeWholeRowVar(RangeTblEntry *rte,
							int varno,
							Index varlevelsup,
							bool allowScalar);

extern TargetEntry *makeTargetEntry(Expr *expr,
									AttrNumber resno,
									char *resname,
									bool resjunk);

extern TargetEntry *flatCopyTargetEntry(TargetEntry *src_tle);

extern FromExpr *makeFromExpr(List *fromlist, Node *quals);

extern Const *makeConst(Oid consttype,
						int32 consttypmod,
						Oid constcollid,
						int constlen,
						Datum constvalue,
						bool constisnull,
						bool constbyval);

extern Const *makeNullConst(Oid consttype, int32 consttypmod, Oid constcollid);

extern Node *makeBoolConst(bool value, bool isnull);

extern Expr *makeBoolExpr(BoolExprType boolop, List *args, int location);

extern Alias *makeAlias(const char *aliasname, List *colnames);

extern RelabelType *makeRelabelType(Expr *arg, Oid rtype, int32 rtypmod,
									Oid rcollid, CoercionForm rformat);

extern RangeVar *makeRangeVar(char *schemaname, char *relname, int location);

extern TypeName *makeTypeName(char *typnam);
extern TypeName *makeTypeNameFromNameList(List *names);
extern TypeName *makeTypeNameFromOid(Oid typeOid, int32 typmod);

extern ColumnDef *makeColumnDef(const char *colname,
								Oid typeOid, int32 typmod, Oid collOid);

extern FuncExpr *makeFuncExpr(Oid funcid, Oid rettype, List *args,
							  Oid funccollid, Oid inputcollid, CoercionForm fformat);

extern FuncCall *makeFuncCall(List *name, List *args,
							  CoercionForm funcformat, int location);

extern Expr *make_opclause(Oid opno, Oid opresulttype, bool opretset,
						   Expr *leftop, Expr *rightop,
						   Oid opcollid, Oid inputcollid);

extern Expr *make_andclause(List *andclauses);
extern Expr *make_orclause(List *orclauses);
extern Expr *make_notclause(Expr *notclause);

extern Node *make_and_qual(Node *qual1, Node *qual2);
extern Expr *make_ands_explicit(List *andclauses);
extern List *make_ands_implicit(Expr *clause);

extern IndexInfo *makeIndexInfo(int numattrs, int numkeyattrs, Oid amoid,
								List *expressions, List *predicates,
								bool unique, bool nulls_not_distinct, bool isready, bool concurrent);

extern DefElem *makeDefElem(char *name, Node *arg, int location);
extern DefElem *makeDefElemExtended(char *nameSpace, char *name, Node *arg,
									DefElemAction defaction, int location);

extern GroupingSet *makeGroupingSet(GroupingSetKind kind, List *content, int location);

extern VacuumRelation *makeVacuumRelation(RangeVar *relation, Oid oid, List *va_cols);

#endif							/* MAKEFUNC_H */
