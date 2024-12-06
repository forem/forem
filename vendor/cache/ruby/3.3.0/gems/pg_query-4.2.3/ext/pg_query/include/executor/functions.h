/*-------------------------------------------------------------------------
 *
 * functions.h
 *		Declarations for execution of SQL-language functions.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/executor/functions.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include "nodes/execnodes.h"
#include "tcop/dest.h"

/*
 * Data structure needed by the parser callback hooks to resolve parameter
 * references during parsing of a SQL function's body.  This is separate from
 * SQLFunctionCache since we sometimes do parsing separately from execution.
 */
typedef struct SQLFunctionParseInfo
{
	char	   *fname;			/* function's name */
	int			nargs;			/* number of input arguments */
	Oid		   *argtypes;		/* resolved types of input arguments */
	char	  **argnames;		/* names of input arguments; NULL if none */
	/* Note that argnames[i] can be NULL, if some args are unnamed */
	Oid			collation;		/* function's input collation, if known */
} SQLFunctionParseInfo;

typedef SQLFunctionParseInfo *SQLFunctionParseInfoPtr;

extern Datum fmgr_sql(PG_FUNCTION_ARGS);

extern SQLFunctionParseInfoPtr prepare_sql_fn_parse_info(HeapTuple procedureTuple,
														 Node *call_expr,
														 Oid inputCollation);

extern void sql_fn_parser_setup(struct ParseState *pstate,
								SQLFunctionParseInfoPtr pinfo);

extern void check_sql_fn_statements(List *queryTreeLists);

extern bool check_sql_fn_retval(List *queryTreeLists,
								Oid rettype, TupleDesc rettupdesc,
								bool insertDroppedCols,
								List **resultTargetList);

extern DestReceiver *CreateSQLFunctionDestReceiver(void);

#endif							/* FUNCTIONS_H */
