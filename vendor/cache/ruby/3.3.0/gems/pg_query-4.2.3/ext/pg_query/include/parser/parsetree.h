/*-------------------------------------------------------------------------
 *
 * parsetree.h
 *	  Routines to access various components and subcomponents of
 *	  parse trees.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/parser/parsetree.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PARSETREE_H
#define PARSETREE_H

#include "nodes/parsenodes.h"


/* ----------------
 *		range table operations
 * ----------------
 */

/*
 *		rt_fetch
 *
 * NB: this will crash and burn if handed an out-of-range RT index
 */
#define rt_fetch(rangetable_index, rangetable) \
	((RangeTblEntry *) list_nth(rangetable, (rangetable_index)-1))

/*
 * Given an RTE and an attribute number, return the appropriate
 * variable name or alias for that attribute of that RTE.
 */
extern char *get_rte_attribute_name(RangeTblEntry *rte, AttrNumber attnum);

/*
 * Check whether an attribute of an RTE has been dropped
 */
extern bool get_rte_attribute_is_dropped(RangeTblEntry *rte,
										 AttrNumber attnum);


/* ----------------
 *		target list operations
 * ----------------
 */

extern TargetEntry *get_tle_by_resno(List *tlist, AttrNumber resno);

/* ----------------
 *		FOR UPDATE/SHARE info
 * ----------------
 */

extern RowMarkClause *get_parse_rowmark(Query *qry, Index rtindex);

#endif							/* PARSETREE_H */
