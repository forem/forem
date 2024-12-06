/*-------------------------------------------------------------------------
 *
 * tablefunc.h
 *				interface for TableFunc executor node
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/executor/tablefunc.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _TABLEFUNC_H
#define _TABLEFUNC_H

/* Forward-declare this to avoid including execnodes.h here */
struct TableFuncScanState;

/*
 * TableFuncRoutine holds function pointers used for generating content of
 * table-producer functions, such as XMLTABLE.
 *
 * InitOpaque initializes table builder private objects.  The output tuple
 * descriptor, input functions for the columns, and typioparams are passed
 * from executor state.
 *
 * SetDocument is called to define the input document.  The table builder may
 * apply additional transformations not exposed outside the table builder
 * context.
 *
 * SetNamespace is called to pass namespace declarations from the table
 * expression.  This function may be NULL if namespaces are not supported by
 * the table builder.  Namespaces must be given before setting the row and
 * column filters.  If the name is given as NULL, the entry shall be for the
 * default namespace.
 *
 * SetRowFilter is called do define the row-generating filter, which shall be
 * used to extract each row from the input document.
 *
 * SetColumnFilter is called once for each column, to define the column-
 * generating filter for the given column.
 *
 * FetchRow shall be called repeatedly until it returns that no more rows are
 * found in the document.  On each invocation it shall set state in the table
 * builder context such that each subsequent GetValue call returns the values
 * for the indicated column for the row being processed.
 *
 * DestroyOpaque shall release all resources associated with a table builder
 * context.  It may be called either because all rows have been consumed, or
 * because an error occurred while processing the table expression.
 */
typedef struct TableFuncRoutine
{
	void		(*InitOpaque) (struct TableFuncScanState *state, int natts);
	void		(*SetDocument) (struct TableFuncScanState *state, Datum value);
	void		(*SetNamespace) (struct TableFuncScanState *state, const char *name,
								 const char *uri);
	void		(*SetRowFilter) (struct TableFuncScanState *state, const char *path);
	void		(*SetColumnFilter) (struct TableFuncScanState *state,
									const char *path, int colnum);
	bool		(*FetchRow) (struct TableFuncScanState *state);
	Datum		(*GetValue) (struct TableFuncScanState *state, int colnum,
							 Oid typid, int32 typmod, bool *isnull);
	void		(*DestroyOpaque) (struct TableFuncScanState *state);
} TableFuncRoutine;

#endif							/* _TABLEFUNC_H */
