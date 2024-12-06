/*-------------------------------------------------------------------------
 *
 * pg_list.h
 *	  interface for PostgreSQL generic list package
 *
 * Once upon a time, parts of Postgres were written in Lisp and used real
 * cons-cell lists for major data structures.  When that code was rewritten
 * in C, we initially had a faithful emulation of cons-cell lists, which
 * unsurprisingly was a performance bottleneck.  A couple of major rewrites
 * later, these data structures are actually simple expansible arrays;
 * but the "List" name and a lot of the notation survives.
 *
 * One important concession to the original implementation is that an empty
 * list is always represented by a null pointer (preferentially written NIL).
 * Non-empty lists have a header, which will not be relocated as long as the
 * list remains non-empty, and an expansible data array.
 *
 * We support three types of lists:
 *
 *	T_List: lists of pointers
 *		(in practice usually pointers to Nodes, but not always;
 *		declared as "void *" to minimize casting annoyances)
 *	T_IntList: lists of integers
 *	T_OidList: lists of Oids
 *
 * (At the moment, ints and Oids are the same size, but they may not
 * always be so; try to be careful to maintain the distinction.)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/nodes/pg_list.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_LIST_H
#define PG_LIST_H

#include "nodes/nodes.h"


typedef union ListCell
{
	void	   *ptr_value;
	int			int_value;
	Oid			oid_value;
} ListCell;

typedef struct List
{
	NodeTag		type;			/* T_List, T_IntList, or T_OidList */
	int			length;			/* number of elements currently present */
	int			max_length;		/* allocated length of elements[] */
	ListCell   *elements;		/* re-allocatable array of cells */
	/* We may allocate some cells along with the List header: */
	ListCell	initial_elements[FLEXIBLE_ARRAY_MEMBER];
	/* If elements == initial_elements, it's not a separate allocation */
} List;

/*
 * The *only* valid representation of an empty list is NIL; in other
 * words, a non-NIL list is guaranteed to have length >= 1.
 */
#define NIL						((List *) NULL)

/*
 * State structs for various looping macros below.
 */
typedef struct ForEachState
{
	const List *l;				/* list we're looping through */
	int			i;				/* current element index */
} ForEachState;

typedef struct ForBothState
{
	const List *l1;				/* lists we're looping through */
	const List *l2;
	int			i;				/* common element index */
} ForBothState;

typedef struct ForBothCellState
{
	const List *l1;				/* lists we're looping through */
	const List *l2;
	int			i1;				/* current element indexes */
	int			i2;
} ForBothCellState;

typedef struct ForThreeState
{
	const List *l1;				/* lists we're looping through */
	const List *l2;
	const List *l3;
	int			i;				/* common element index */
} ForThreeState;

typedef struct ForFourState
{
	const List *l1;				/* lists we're looping through */
	const List *l2;
	const List *l3;
	const List *l4;
	int			i;				/* common element index */
} ForFourState;

typedef struct ForFiveState
{
	const List *l1;				/* lists we're looping through */
	const List *l2;
	const List *l3;
	const List *l4;
	const List *l5;
	int			i;				/* common element index */
} ForFiveState;

/*
 * These routines are small enough, and used often enough, to justify being
 * inline.
 */

/* Fetch address of list's first cell; NULL if empty list */
static inline ListCell *
list_head(const List *l)
{
	return l ? &l->elements[0] : NULL;
}

/* Fetch address of list's last cell; NULL if empty list */
static inline ListCell *
list_tail(const List *l)
{
	return l ? &l->elements[l->length - 1] : NULL;
}

/* Fetch address of list's second cell, if it has one, else NULL */
static inline ListCell *
list_second_cell(const List *l)
{
	if (l && l->length >= 2)
		return &l->elements[1];
	else
		return NULL;
}

/* Fetch list's length */
static inline int
list_length(const List *l)
{
	return l ? l->length : 0;
}

/*
 * Macros to access the data values within List cells.
 *
 * Note that with the exception of the "xxx_node" macros, these are
 * lvalues and can be assigned to.
 *
 * NB: There is an unfortunate legacy from a previous incarnation of
 * the List API: the macro lfirst() was used to mean "the data in this
 * cons cell". To avoid changing every usage of lfirst(), that meaning
 * has been kept. As a result, lfirst() takes a ListCell and returns
 * the data it contains; to get the data in the first cell of a
 * List, use linitial(). Worse, lsecond() is more closely related to
 * linitial() than lfirst(): given a List, lsecond() returns the data
 * in the second list cell.
 */
#define lfirst(lc)				((lc)->ptr_value)
#define lfirst_int(lc)			((lc)->int_value)
#define lfirst_oid(lc)			((lc)->oid_value)
#define lfirst_node(type,lc)	castNode(type, lfirst(lc))

#define linitial(l)				lfirst(list_nth_cell(l, 0))
#define linitial_int(l)			lfirst_int(list_nth_cell(l, 0))
#define linitial_oid(l)			lfirst_oid(list_nth_cell(l, 0))
#define linitial_node(type,l)	castNode(type, linitial(l))

#define lsecond(l)				lfirst(list_nth_cell(l, 1))
#define lsecond_int(l)			lfirst_int(list_nth_cell(l, 1))
#define lsecond_oid(l)			lfirst_oid(list_nth_cell(l, 1))
#define lsecond_node(type,l)	castNode(type, lsecond(l))

#define lthird(l)				lfirst(list_nth_cell(l, 2))
#define lthird_int(l)			lfirst_int(list_nth_cell(l, 2))
#define lthird_oid(l)			lfirst_oid(list_nth_cell(l, 2))
#define lthird_node(type,l)		castNode(type, lthird(l))

#define lfourth(l)				lfirst(list_nth_cell(l, 3))
#define lfourth_int(l)			lfirst_int(list_nth_cell(l, 3))
#define lfourth_oid(l)			lfirst_oid(list_nth_cell(l, 3))
#define lfourth_node(type,l)	castNode(type, lfourth(l))

#define llast(l)				lfirst(list_last_cell(l))
#define llast_int(l)			lfirst_int(list_last_cell(l))
#define llast_oid(l)			lfirst_oid(list_last_cell(l))
#define llast_node(type,l)		castNode(type, llast(l))

/*
 * Convenience macros for building fixed-length lists
 */
#define list_make_ptr_cell(v)	((ListCell) {.ptr_value = (v)})
#define list_make_int_cell(v)	((ListCell) {.int_value = (v)})
#define list_make_oid_cell(v)	((ListCell) {.oid_value = (v)})

#define list_make1(x1) \
	list_make1_impl(T_List, list_make_ptr_cell(x1))
#define list_make2(x1,x2) \
	list_make2_impl(T_List, list_make_ptr_cell(x1), list_make_ptr_cell(x2))
#define list_make3(x1,x2,x3) \
	list_make3_impl(T_List, list_make_ptr_cell(x1), list_make_ptr_cell(x2), \
					list_make_ptr_cell(x3))
#define list_make4(x1,x2,x3,x4) \
	list_make4_impl(T_List, list_make_ptr_cell(x1), list_make_ptr_cell(x2), \
					list_make_ptr_cell(x3), list_make_ptr_cell(x4))
#define list_make5(x1,x2,x3,x4,x5) \
	list_make5_impl(T_List, list_make_ptr_cell(x1), list_make_ptr_cell(x2), \
					list_make_ptr_cell(x3), list_make_ptr_cell(x4), \
					list_make_ptr_cell(x5))

#define list_make1_int(x1) \
	list_make1_impl(T_IntList, list_make_int_cell(x1))
#define list_make2_int(x1,x2) \
	list_make2_impl(T_IntList, list_make_int_cell(x1), list_make_int_cell(x2))
#define list_make3_int(x1,x2,x3) \
	list_make3_impl(T_IntList, list_make_int_cell(x1), list_make_int_cell(x2), \
					list_make_int_cell(x3))
#define list_make4_int(x1,x2,x3,x4) \
	list_make4_impl(T_IntList, list_make_int_cell(x1), list_make_int_cell(x2), \
					list_make_int_cell(x3), list_make_int_cell(x4))
#define list_make5_int(x1,x2,x3,x4,x5) \
	list_make5_impl(T_IntList, list_make_int_cell(x1), list_make_int_cell(x2), \
					list_make_int_cell(x3), list_make_int_cell(x4), \
					list_make_int_cell(x5))

#define list_make1_oid(x1) \
	list_make1_impl(T_OidList, list_make_oid_cell(x1))
#define list_make2_oid(x1,x2) \
	list_make2_impl(T_OidList, list_make_oid_cell(x1), list_make_oid_cell(x2))
#define list_make3_oid(x1,x2,x3) \
	list_make3_impl(T_OidList, list_make_oid_cell(x1), list_make_oid_cell(x2), \
					list_make_oid_cell(x3))
#define list_make4_oid(x1,x2,x3,x4) \
	list_make4_impl(T_OidList, list_make_oid_cell(x1), list_make_oid_cell(x2), \
					list_make_oid_cell(x3), list_make_oid_cell(x4))
#define list_make5_oid(x1,x2,x3,x4,x5) \
	list_make5_impl(T_OidList, list_make_oid_cell(x1), list_make_oid_cell(x2), \
					list_make_oid_cell(x3), list_make_oid_cell(x4), \
					list_make_oid_cell(x5))

/*
 * Locate the n'th cell (counting from 0) of the list.
 * It is an assertion failure if there is no such cell.
 */
static inline ListCell *
list_nth_cell(const List *list, int n)
{
	Assert(list != NIL);
	Assert(n >= 0 && n < list->length);
	return &list->elements[n];
}

/*
 * Return the last cell in a non-NIL List.
 */
static inline ListCell *
list_last_cell(const List *list)
{
	Assert(list != NIL);
	return &list->elements[list->length - 1];
}

/*
 * Return the pointer value contained in the n'th element of the
 * specified list. (List elements begin at 0.)
 */
static inline void *
list_nth(const List *list, int n)
{
	Assert(IsA(list, List));
	return lfirst(list_nth_cell(list, n));
}

/*
 * Return the integer value contained in the n'th element of the
 * specified list.
 */
static inline int
list_nth_int(const List *list, int n)
{
	Assert(IsA(list, IntList));
	return lfirst_int(list_nth_cell(list, n));
}

/*
 * Return the OID value contained in the n'th element of the specified
 * list.
 */
static inline Oid
list_nth_oid(const List *list, int n)
{
	Assert(IsA(list, OidList));
	return lfirst_oid(list_nth_cell(list, n));
}

#define list_nth_node(type,list,n)	castNode(type, list_nth(list, n))

/*
 * Get the given ListCell's index (from 0) in the given List.
 */
static inline int
list_cell_number(const List *l, const ListCell *c)
{
	Assert(c >= &l->elements[0] && c < &l->elements[l->length]);
	return c - l->elements;
}

/*
 * Get the address of the next cell after "c" within list "l", or NULL if none.
 */
static inline ListCell *
lnext(const List *l, const ListCell *c)
{
	Assert(c >= &l->elements[0] && c < &l->elements[l->length]);
	c++;
	if (c < &l->elements[l->length])
		return (ListCell *) c;
	else
		return NULL;
}

/*
 * foreach -
 *	  a convenience macro for looping through a list
 *
 * "cell" must be the name of a "ListCell *" variable; it's made to point
 * to each List element in turn.  "cell" will be NULL after normal exit from
 * the loop, but an early "break" will leave it pointing at the current
 * List element.
 *
 * Beware of changing the List object while the loop is iterating.
 * The current semantics are that we examine successive list indices in
 * each iteration, so that insertion or deletion of list elements could
 * cause elements to be re-visited or skipped unexpectedly.  Previous
 * implementations of foreach() behaved differently.  However, it's safe
 * to append elements to the List (or in general, insert them after the
 * current element); such new elements are guaranteed to be visited.
 * Also, the current element of the List can be deleted, if you use
 * foreach_delete_current() to do so.  BUT: either of these actions will
 * invalidate the "cell" pointer for the remainder of the current iteration.
 */
#define foreach(cell, lst)	\
	for (ForEachState cell##__state = {(lst), 0}; \
		 (cell##__state.l != NIL && \
		  cell##__state.i < cell##__state.l->length) ? \
		 (cell = &cell##__state.l->elements[cell##__state.i], true) : \
		 (cell = NULL, false); \
		 cell##__state.i++)

/*
 * foreach_delete_current -
 *	  delete the current list element from the List associated with a
 *	  surrounding foreach() loop, returning the new List pointer.
 *
 * This is equivalent to list_delete_cell(), but it also adjusts the foreach
 * loop's state so that no list elements will be missed.  Do not delete
 * elements from an active foreach loop's list in any other way!
 */
#define foreach_delete_current(lst, cell)	\
	(cell##__state.i--, \
	 (List *) (cell##__state.l = list_delete_cell(lst, cell)))

/*
 * foreach_current_index -
 *	  get the zero-based list index of a surrounding foreach() loop's
 *	  current element; pass the name of the "ListCell *" iterator variable.
 *
 * Beware of using this after foreach_delete_current(); the value will be
 * out of sync for the rest of the current loop iteration.  Anyway, since
 * you just deleted the current element, the value is pretty meaningless.
 */
#define foreach_current_index(cell)  (cell##__state.i)

/*
 * for_each_from -
 *	  Like foreach(), but start from the N'th (zero-based) list element,
 *	  not necessarily the first one.
 *
 * It's okay for N to exceed the list length, but not for it to be negative.
 *
 * The caveats for foreach() apply equally here.
 */
#define for_each_from(cell, lst, N)	\
	for (ForEachState cell##__state = for_each_from_setup(lst, N); \
		 (cell##__state.l != NIL && \
		  cell##__state.i < cell##__state.l->length) ? \
		 (cell = &cell##__state.l->elements[cell##__state.i], true) : \
		 (cell = NULL, false); \
		 cell##__state.i++)

static inline ForEachState
for_each_from_setup(const List *lst, int N)
{
	ForEachState r = {lst, N};

	Assert(N >= 0);
	return r;
}

/*
 * for_each_cell -
 *	  a convenience macro which loops through a list starting from a
 *	  specified cell
 *
 * The caveats for foreach() apply equally here.
 */
#define for_each_cell(cell, lst, initcell)	\
	for (ForEachState cell##__state = for_each_cell_setup(lst, initcell); \
		 (cell##__state.l != NIL && \
		  cell##__state.i < cell##__state.l->length) ? \
		 (cell = &cell##__state.l->elements[cell##__state.i], true) : \
		 (cell = NULL, false); \
		 cell##__state.i++)

static inline ForEachState
for_each_cell_setup(const List *lst, const ListCell *initcell)
{
	ForEachState r = {lst,
	initcell ? list_cell_number(lst, initcell) : list_length(lst)};

	return r;
}

/*
 * forboth -
 *	  a convenience macro for advancing through two linked lists
 *	  simultaneously. This macro loops through both lists at the same
 *	  time, stopping when either list runs out of elements. Depending
 *	  on the requirements of the call site, it may also be wise to
 *	  assert that the lengths of the two lists are equal. (But, if they
 *	  are not, some callers rely on the ending cell values being separately
 *	  NULL or non-NULL as defined here; don't try to optimize that.)
 *
 * The caveats for foreach() apply equally here.
 */
#define forboth(cell1, list1, cell2, list2)							\
	for (ForBothState cell1##__state = {(list1), (list2), 0}; \
		 multi_for_advance_cell(cell1, cell1##__state, l1, i), \
		 multi_for_advance_cell(cell2, cell1##__state, l2, i), \
		 (cell1 != NULL && cell2 != NULL); \
		 cell1##__state.i++)

#define multi_for_advance_cell(cell, state, l, i) \
	(cell = (state.l != NIL && state.i < state.l->length) ? \
	 &state.l->elements[state.i] : NULL)

/*
 * for_both_cell -
 *	  a convenience macro which loops through two lists starting from the
 *	  specified cells of each. This macro loops through both lists at the same
 *	  time, stopping when either list runs out of elements.  Depending on the
 *	  requirements of the call site, it may also be wise to assert that the
 *	  lengths of the two lists are equal, and initcell1 and initcell2 are at
 *	  the same position in the respective lists.
 *
 * The caveats for foreach() apply equally here.
 */
#define for_both_cell(cell1, list1, initcell1, cell2, list2, initcell2)	\
	for (ForBothCellState cell1##__state = \
			 for_both_cell_setup(list1, initcell1, list2, initcell2); \
		 multi_for_advance_cell(cell1, cell1##__state, l1, i1), \
		 multi_for_advance_cell(cell2, cell1##__state, l2, i2), \
		 (cell1 != NULL && cell2 != NULL); \
		 cell1##__state.i1++, cell1##__state.i2++)

static inline ForBothCellState
for_both_cell_setup(const List *list1, const ListCell *initcell1,
					const List *list2, const ListCell *initcell2)
{
	ForBothCellState r = {list1, list2,
		initcell1 ? list_cell_number(list1, initcell1) : list_length(list1),
	initcell2 ? list_cell_number(list2, initcell2) : list_length(list2)};

	return r;
}

/*
 * forthree -
 *	  the same for three lists
 */
#define forthree(cell1, list1, cell2, list2, cell3, list3) \
	for (ForThreeState cell1##__state = {(list1), (list2), (list3), 0}; \
		 multi_for_advance_cell(cell1, cell1##__state, l1, i), \
		 multi_for_advance_cell(cell2, cell1##__state, l2, i), \
		 multi_for_advance_cell(cell3, cell1##__state, l3, i), \
		 (cell1 != NULL && cell2 != NULL && cell3 != NULL); \
		 cell1##__state.i++)

/*
 * forfour -
 *	  the same for four lists
 */
#define forfour(cell1, list1, cell2, list2, cell3, list3, cell4, list4) \
	for (ForFourState cell1##__state = {(list1), (list2), (list3), (list4), 0}; \
		 multi_for_advance_cell(cell1, cell1##__state, l1, i), \
		 multi_for_advance_cell(cell2, cell1##__state, l2, i), \
		 multi_for_advance_cell(cell3, cell1##__state, l3, i), \
		 multi_for_advance_cell(cell4, cell1##__state, l4, i), \
		 (cell1 != NULL && cell2 != NULL && cell3 != NULL && cell4 != NULL); \
		 cell1##__state.i++)

/*
 * forfive -
 *	  the same for five lists
 */
#define forfive(cell1, list1, cell2, list2, cell3, list3, cell4, list4, cell5, list5) \
	for (ForFiveState cell1##__state = {(list1), (list2), (list3), (list4), (list5), 0}; \
		 multi_for_advance_cell(cell1, cell1##__state, l1, i), \
		 multi_for_advance_cell(cell2, cell1##__state, l2, i), \
		 multi_for_advance_cell(cell3, cell1##__state, l3, i), \
		 multi_for_advance_cell(cell4, cell1##__state, l4, i), \
		 multi_for_advance_cell(cell5, cell1##__state, l5, i), \
		 (cell1 != NULL && cell2 != NULL && cell3 != NULL && \
		  cell4 != NULL && cell5 != NULL); \
		 cell1##__state.i++)

/* Functions in src/backend/nodes/list.c */

extern List *list_make1_impl(NodeTag t, ListCell datum1);
extern List *list_make2_impl(NodeTag t, ListCell datum1, ListCell datum2);
extern List *list_make3_impl(NodeTag t, ListCell datum1, ListCell datum2,
							 ListCell datum3);
extern List *list_make4_impl(NodeTag t, ListCell datum1, ListCell datum2,
							 ListCell datum3, ListCell datum4);
extern List *list_make5_impl(NodeTag t, ListCell datum1, ListCell datum2,
							 ListCell datum3, ListCell datum4,
							 ListCell datum5);

extern pg_nodiscard List *lappend(List *list, void *datum);
extern pg_nodiscard List *lappend_int(List *list, int datum);
extern pg_nodiscard List *lappend_oid(List *list, Oid datum);

extern pg_nodiscard List *list_insert_nth(List *list, int pos, void *datum);
extern pg_nodiscard List *list_insert_nth_int(List *list, int pos, int datum);
extern pg_nodiscard List *list_insert_nth_oid(List *list, int pos, Oid datum);

extern pg_nodiscard List *lcons(void *datum, List *list);
extern pg_nodiscard List *lcons_int(int datum, List *list);
extern pg_nodiscard List *lcons_oid(Oid datum, List *list);

extern pg_nodiscard List *list_concat(List *list1, const List *list2);
extern pg_nodiscard List *list_concat_copy(const List *list1, const List *list2);

extern pg_nodiscard List *list_truncate(List *list, int new_size);

extern bool list_member(const List *list, const void *datum);
extern bool list_member_ptr(const List *list, const void *datum);
extern bool list_member_int(const List *list, int datum);
extern bool list_member_oid(const List *list, Oid datum);

extern pg_nodiscard List *list_delete(List *list, void *datum);
extern pg_nodiscard List *list_delete_ptr(List *list, void *datum);
extern pg_nodiscard List *list_delete_int(List *list, int datum);
extern pg_nodiscard List *list_delete_oid(List *list, Oid datum);
extern pg_nodiscard List *list_delete_first(List *list);
extern pg_nodiscard List *list_delete_last(List *list);
extern pg_nodiscard List *list_delete_first_n(List *list, int n);
extern pg_nodiscard List *list_delete_nth_cell(List *list, int n);
extern pg_nodiscard List *list_delete_cell(List *list, ListCell *cell);

extern List *list_union(const List *list1, const List *list2);
extern List *list_union_ptr(const List *list1, const List *list2);
extern List *list_union_int(const List *list1, const List *list2);
extern List *list_union_oid(const List *list1, const List *list2);

extern List *list_intersection(const List *list1, const List *list2);
extern List *list_intersection_int(const List *list1, const List *list2);

/* currently, there's no need for list_intersection_ptr etc */

extern List *list_difference(const List *list1, const List *list2);
extern List *list_difference_ptr(const List *list1, const List *list2);
extern List *list_difference_int(const List *list1, const List *list2);
extern List *list_difference_oid(const List *list1, const List *list2);

extern pg_nodiscard List *list_append_unique(List *list, void *datum);
extern pg_nodiscard List *list_append_unique_ptr(List *list, void *datum);
extern pg_nodiscard List *list_append_unique_int(List *list, int datum);
extern pg_nodiscard List *list_append_unique_oid(List *list, Oid datum);

extern pg_nodiscard List *list_concat_unique(List *list1, const List *list2);
extern pg_nodiscard List *list_concat_unique_ptr(List *list1, const List *list2);
extern pg_nodiscard List *list_concat_unique_int(List *list1, const List *list2);
extern pg_nodiscard List *list_concat_unique_oid(List *list1, const List *list2);

extern void list_deduplicate_oid(List *list);

extern void list_free(List *list);
extern void list_free_deep(List *list);

extern pg_nodiscard List *list_copy(const List *list);
extern pg_nodiscard List *list_copy_head(const List *oldlist, int len);
extern pg_nodiscard List *list_copy_tail(const List *list, int nskip);
extern pg_nodiscard List *list_copy_deep(const List *oldlist);

typedef int (*list_sort_comparator) (const ListCell *a, const ListCell *b);
extern void list_sort(List *list, list_sort_comparator cmp);

extern int	list_int_cmp(const ListCell *p1, const ListCell *p2);
extern int	list_oid_cmp(const ListCell *p1, const ListCell *p2);

#endif							/* PG_LIST_H */
