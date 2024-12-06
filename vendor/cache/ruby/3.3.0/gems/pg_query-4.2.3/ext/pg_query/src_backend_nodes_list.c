/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - list_make1_impl
 * - new_list
 * - check_list_invariants
 * - lappend
 * - new_tail_cell
 * - enlarge_list
 * - list_make2_impl
 * - list_concat
 * - list_copy
 * - lcons
 * - new_head_cell
 * - list_make3_impl
 * - list_make4_impl
 * - list_delete_cell
 * - list_delete_nth_cell
 * - list_free
 * - list_free_private
 * - list_copy_deep
 * - list_copy_tail
 * - list_truncate
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * list.c
 *	  implementation for PostgreSQL generic list package
 *
 * See comments in pg_list.h.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/nodes/list.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/pg_list.h"
#include "port/pg_bitutils.h"
#include "utils/memdebug.h"
#include "utils/memutils.h"


/*
 * The previous List implementation, since it used a separate palloc chunk
 * for each cons cell, had the property that adding or deleting list cells
 * did not move the storage of other existing cells in the list.  Quite a
 * bit of existing code depended on that, by retaining ListCell pointers
 * across such operations on a list.  There is no such guarantee in this
 * implementation, so instead we have debugging support that is meant to
 * help flush out now-broken assumptions.  Defining DEBUG_LIST_MEMORY_USAGE
 * while building this file causes the List operations to forcibly move
 * all cells in a list whenever a cell is added or deleted.  In combination
 * with MEMORY_CONTEXT_CHECKING and/or Valgrind, this can usually expose
 * broken code.  It's a bit expensive though, as there's many more palloc
 * cycles and a lot more data-copying than in a default build.
 *
 * By default, we enable this when building for Valgrind.
 */
#ifdef USE_VALGRIND
#define DEBUG_LIST_MEMORY_USAGE
#endif

/* Overhead for the fixed part of a List header, measured in ListCells */
#define LIST_HEADER_OVERHEAD  \
	((int) ((offsetof(List, initial_elements) - 1) / sizeof(ListCell) + 1))

/*
 * Macros to simplify writing assertions about the type of a list; a
 * NIL list is considered to be an empty list of any type.
 */
#define IsPointerList(l)		((l) == NIL || IsA((l), List))
#define IsIntegerList(l)		((l) == NIL || IsA((l), IntList))
#define IsOidList(l)			((l) == NIL || IsA((l), OidList))

#ifdef USE_ASSERT_CHECKING
/*
 * Check that the specified List is valid (so far as we can tell).
 */
static void
check_list_invariants(const List *list)
{
	if (list == NIL)
		return;

	Assert(list->length > 0);
	Assert(list->length <= list->max_length);
	Assert(list->elements != NULL);

	Assert(list->type == T_List ||
		   list->type == T_IntList ||
		   list->type == T_OidList);
}
#else
#define check_list_invariants(l)  ((void) 0)
#endif							/* USE_ASSERT_CHECKING */

/*
 * Return a freshly allocated List with room for at least min_size cells.
 *
 * Since empty non-NIL lists are invalid, new_list() sets the initial length
 * to min_size, effectively marking that number of cells as valid; the caller
 * is responsible for filling in their data.
 */
static List *
new_list(NodeTag type, int min_size)
{
	List	   *newlist;
	int			max_size;

	Assert(min_size > 0);

	/*
	 * We allocate all the requested cells, and possibly some more, as part of
	 * the same palloc request as the List header.  This is a big win for the
	 * typical case of short fixed-length lists.  It can lose if we allocate a
	 * moderately long list and then it gets extended; we'll be wasting more
	 * initial_elements[] space than if we'd made the header small.  However,
	 * rounding up the request as we do in the normal code path provides some
	 * defense against small extensions.
	 */

#ifndef DEBUG_LIST_MEMORY_USAGE

	/*
	 * Normally, we set up a list with some extra cells, to allow it to grow
	 * without a repalloc.  Prefer cell counts chosen to make the total
	 * allocation a power-of-2, since palloc would round it up to that anyway.
	 * (That stops being true for very large allocations, but very long lists
	 * are infrequent, so it doesn't seem worth special logic for such cases.)
	 *
	 * The minimum allocation is 8 ListCell units, providing either 4 or 5
	 * available ListCells depending on the machine's word width.  Counting
	 * palloc's overhead, this uses the same amount of space as a one-cell
	 * list did in the old implementation, and less space for any longer list.
	 *
	 * We needn't worry about integer overflow; no caller passes min_size
	 * that's more than twice the size of an existing list, so the size limits
	 * within palloc will ensure that we don't overflow here.
	 */
	max_size = pg_nextpower2_32(Max(8, min_size + LIST_HEADER_OVERHEAD));
	max_size -= LIST_HEADER_OVERHEAD;
#else

	/*
	 * For debugging, don't allow any extra space.  This forces any cell
	 * addition to go through enlarge_list() and thus move the existing data.
	 */
	max_size = min_size;
#endif

	newlist = (List *) palloc(offsetof(List, initial_elements) +
							  max_size * sizeof(ListCell));
	newlist->type = type;
	newlist->length = min_size;
	newlist->max_length = max_size;
	newlist->elements = newlist->initial_elements;

	return newlist;
}

/*
 * Enlarge an existing non-NIL List to have room for at least min_size cells.
 *
 * This does *not* update list->length, as some callers would find that
 * inconvenient.  (list->length had better be the correct number of existing
 * valid cells, though.)
 */
static void
enlarge_list(List *list, int min_size)
{
	int			new_max_len;

	Assert(min_size > list->max_length);	/* else we shouldn't be here */

#ifndef DEBUG_LIST_MEMORY_USAGE

	/*
	 * As above, we prefer power-of-two total allocations; but here we need
	 * not account for list header overhead.
	 */

	/* clamp the minimum value to 16, a semi-arbitrary small power of 2 */
	new_max_len = pg_nextpower2_32(Max(16, min_size));

#else
	/* As above, don't allocate anything extra */
	new_max_len = min_size;
#endif

	if (list->elements == list->initial_elements)
	{
		/*
		 * Replace original in-line allocation with a separate palloc block.
		 * Ensure it is in the same memory context as the List header.  (The
		 * previous List implementation did not offer any guarantees about
		 * keeping all list cells in the same context, but it seems reasonable
		 * to create such a guarantee now.)
		 */
		list->elements = (ListCell *)
			MemoryContextAlloc(GetMemoryChunkContext(list),
							   new_max_len * sizeof(ListCell));
		memcpy(list->elements, list->initial_elements,
			   list->length * sizeof(ListCell));

		/*
		 * We must not move the list header, so it's unsafe to try to reclaim
		 * the initial_elements[] space via repalloc.  In debugging builds,
		 * however, we can clear that space and/or mark it inaccessible.
		 * (wipe_mem includes VALGRIND_MAKE_MEM_NOACCESS.)
		 */
#ifdef CLOBBER_FREED_MEMORY
		wipe_mem(list->initial_elements,
				 list->max_length * sizeof(ListCell));
#else
		VALGRIND_MAKE_MEM_NOACCESS(list->initial_elements,
								   list->max_length * sizeof(ListCell));
#endif
	}
	else
	{
#ifndef DEBUG_LIST_MEMORY_USAGE
		/* Normally, let repalloc deal with enlargement */
		list->elements = (ListCell *) repalloc(list->elements,
											   new_max_len * sizeof(ListCell));
#else
		/*
		 * repalloc() might enlarge the space in-place, which we don't want
		 * for debugging purposes, so forcibly move the data somewhere else.
		 */
		ListCell   *newelements;

		newelements = (ListCell *)
			MemoryContextAlloc(GetMemoryChunkContext(list),
							   new_max_len * sizeof(ListCell));
		memcpy(newelements, list->elements,
			   list->length * sizeof(ListCell));
		pfree(list->elements);
		list->elements = newelements;
#endif
	}

	list->max_length = new_max_len;
}

/*
 * Convenience functions to construct short Lists from given values.
 * (These are normally invoked via the list_makeN macros.)
 */
List *
list_make1_impl(NodeTag t, ListCell datum1)
{
	List	   *list = new_list(t, 1);

	list->elements[0] = datum1;
	check_list_invariants(list);
	return list;
}

List *
list_make2_impl(NodeTag t, ListCell datum1, ListCell datum2)
{
	List	   *list = new_list(t, 2);

	list->elements[0] = datum1;
	list->elements[1] = datum2;
	check_list_invariants(list);
	return list;
}

List *
list_make3_impl(NodeTag t, ListCell datum1, ListCell datum2,
				ListCell datum3)
{
	List	   *list = new_list(t, 3);

	list->elements[0] = datum1;
	list->elements[1] = datum2;
	list->elements[2] = datum3;
	check_list_invariants(list);
	return list;
}

List *
list_make4_impl(NodeTag t, ListCell datum1, ListCell datum2,
				ListCell datum3, ListCell datum4)
{
	List	   *list = new_list(t, 4);

	list->elements[0] = datum1;
	list->elements[1] = datum2;
	list->elements[2] = datum3;
	list->elements[3] = datum4;
	check_list_invariants(list);
	return list;
}



/*
 * Make room for a new head cell in the given (non-NIL) list.
 *
 * The data in the new head cell is undefined; the caller should be
 * sure to fill it in
 */
static void
new_head_cell(List *list)
{
	/* Enlarge array if necessary */
	if (list->length >= list->max_length)
		enlarge_list(list, list->length + 1);
	/* Now shove the existing data over */
	memmove(&list->elements[1], &list->elements[0],
			list->length * sizeof(ListCell));
	list->length++;
}

/*
 * Make room for a new tail cell in the given (non-NIL) list.
 *
 * The data in the new tail cell is undefined; the caller should be
 * sure to fill it in
 */
static void
new_tail_cell(List *list)
{
	/* Enlarge array if necessary */
	if (list->length >= list->max_length)
		enlarge_list(list, list->length + 1);
	list->length++;
}

/*
 * Append a pointer to the list. A pointer to the modified list is
 * returned. Note that this function may or may not destructively
 * modify the list; callers should always use this function's return
 * value, rather than continuing to use the pointer passed as the
 * first argument.
 */
List *
lappend(List *list, void *datum)
{
	Assert(IsPointerList(list));

	if (list == NIL)
		list = new_list(T_List, 1);
	else
		new_tail_cell(list);

	llast(list) = datum;
	check_list_invariants(list);
	return list;
}

/*
 * Append an integer to the specified list. See lappend()
 */


/*
 * Append an OID to the specified list. See lappend()
 */


/*
 * Make room for a new cell at position 'pos' (measured from 0).
 * The data in the cell is left undefined, and must be filled in by the
 * caller. 'list' is assumed to be non-NIL, and 'pos' must be a valid
 * list position, ie, 0 <= pos <= list's length.
 * Returns address of the new cell.
 */


/*
 * Insert the given datum at position 'pos' (measured from 0) in the list.
 * 'pos' must be valid, ie, 0 <= pos <= list's length.
 *
 * Note that this takes time proportional to the distance to the end of the
 * list, since the following entries must be moved.
 */






/*
 * Prepend a new element to the list. A pointer to the modified list
 * is returned. Note that this function may or may not destructively
 * modify the list; callers should always use this function's return
 * value, rather than continuing to use the pointer passed as the
 * second argument.
 *
 * Note that this takes time proportional to the length of the list,
 * since the existing entries must be moved.
 *
 * Caution: before Postgres 8.0, the original List was unmodified and
 * could be considered to retain its separate identity.  This is no longer
 * the case.
 */
List *
lcons(void *datum, List *list)
{
	Assert(IsPointerList(list));

	if (list == NIL)
		list = new_list(T_List, 1);
	else
		new_head_cell(list);

	linitial(list) = datum;
	check_list_invariants(list);
	return list;
}

/*
 * Prepend an integer to the list. See lcons()
 */


/*
 * Prepend an OID to the list. See lcons()
 */


/*
 * Concatenate list2 to the end of list1, and return list1.
 *
 * This is equivalent to lappend'ing each element of list2, in order, to list1.
 * list1 is destructively changed, list2 is not.  (However, in the case of
 * pointer lists, list1 and list2 will point to the same structures.)
 *
 * Callers should be sure to use the return value as the new pointer to the
 * concatenated list: the 'list1' input pointer may or may not be the same
 * as the returned pointer.
 *
 * Note that this takes at least time proportional to the length of list2.
 * It'd typically be the case that we have to enlarge list1's storage,
 * probably adding time proportional to the length of list1.
 */
List *
list_concat(List *list1, const List *list2)
{
	int			new_len;

	if (list1 == NIL)
		return list_copy(list2);
	if (list2 == NIL)
		return list1;

	Assert(list1->type == list2->type);

	new_len = list1->length + list2->length;
	/* Enlarge array if necessary */
	if (new_len > list1->max_length)
		enlarge_list(list1, new_len);

	/* Even if list1 == list2, using memcpy should be safe here */
	memcpy(&list1->elements[list1->length], &list2->elements[0],
		   list2->length * sizeof(ListCell));
	list1->length = new_len;

	check_list_invariants(list1);
	return list1;
}

/*
 * Form a new list by concatenating the elements of list1 and list2.
 *
 * Neither input list is modified.  (However, if they are pointer lists,
 * the output list will point to the same structures.)
 *
 * This is equivalent to, but more efficient than,
 * list_concat(list_copy(list1), list2).
 * Note that some pre-v13 code might list_copy list2 as well, but that's
 * pointless now.
 */


/*
 * Truncate 'list' to contain no more than 'new_size' elements. This
 * modifies the list in-place! Despite this, callers should use the
 * pointer returned by this function to refer to the newly truncated
 * list -- it may or may not be the same as the pointer that was
 * passed.
 *
 * Note that any cells removed by list_truncate() are NOT pfree'd.
 */
List *
list_truncate(List *list, int new_size)
{
	if (new_size <= 0)
		return NIL;				/* truncate to zero length */

	/* If asked to effectively extend the list, do nothing */
	if (new_size < list_length(list))
		list->length = new_size;

	/*
	 * Note: unlike the individual-list-cell deletion functions, we don't move
	 * the list cells to new storage, even in DEBUG_LIST_MEMORY_USAGE mode.
	 * This is because none of them can move in this operation, so just like
	 * in the old cons-cell-based implementation, this function doesn't
	 * invalidate any pointers to cells of the list.  This is also the reason
	 * for not wiping the memory of the deleted cells: the old code didn't
	 * free them either.  Perhaps later we'll tighten this up.
	 */

	return list;
}

/*
 * Return true iff 'datum' is a member of the list. Equality is
 * determined via equal(), so callers should ensure that they pass a
 * Node as 'datum'.
 *
 * This does a simple linear search --- avoid using it on long lists.
 */


/*
 * Return true iff 'datum' is a member of the list. Equality is
 * determined by using simple pointer comparison.
 */


/*
 * Return true iff the integer 'datum' is a member of the list.
 */


/*
 * Return true iff the OID 'datum' is a member of the list.
 */


/*
 * Delete the n'th cell (counting from 0) in list.
 *
 * The List is pfree'd if this was the last member.
 *
 * Note that this takes time proportional to the distance to the end of the
 * list, since the following entries must be moved.
 */
List *
list_delete_nth_cell(List *list, int n)
{
	check_list_invariants(list);

	Assert(n >= 0 && n < list->length);

	/*
	 * If we're about to delete the last node from the list, free the whole
	 * list instead and return NIL, which is the only valid representation of
	 * a zero-length list.
	 */
	if (list->length == 1)
	{
		list_free(list);
		return NIL;
	}

	/*
	 * Otherwise, we normally just collapse out the removed element.  But for
	 * debugging purposes, move the whole list contents someplace else.
	 *
	 * (Note that we *must* keep the contents in the same memory context.)
	 */
#ifndef DEBUG_LIST_MEMORY_USAGE
	memmove(&list->elements[n], &list->elements[n + 1],
			(list->length - 1 - n) * sizeof(ListCell));
	list->length--;
#else
	{
		ListCell   *newelems;
		int			newmaxlen = list->length - 1;

		newelems = (ListCell *)
			MemoryContextAlloc(GetMemoryChunkContext(list),
							   newmaxlen * sizeof(ListCell));
		memcpy(newelems, list->elements, n * sizeof(ListCell));
		memcpy(&newelems[n], &list->elements[n + 1],
			   (list->length - 1 - n) * sizeof(ListCell));
		if (list->elements != list->initial_elements)
			pfree(list->elements);
		else
		{
			/*
			 * As in enlarge_list(), clear the initial_elements[] space and/or
			 * mark it inaccessible.
			 */
#ifdef CLOBBER_FREED_MEMORY
			wipe_mem(list->initial_elements,
					 list->max_length * sizeof(ListCell));
#else
			VALGRIND_MAKE_MEM_NOACCESS(list->initial_elements,
									   list->max_length * sizeof(ListCell));
#endif
		}
		list->elements = newelems;
		list->max_length = newmaxlen;
		list->length--;
		check_list_invariants(list);
	}
#endif

	return list;
}

/*
 * Delete 'cell' from 'list'.
 *
 * The List is pfree'd if this was the last member.  However, we do not
 * touch any data the cell might've been pointing to.
 *
 * Note that this takes time proportional to the distance to the end of the
 * list, since the following entries must be moved.
 */
List *
list_delete_cell(List *list, ListCell *cell)
{
	return list_delete_nth_cell(list, cell - list->elements);
}

/*
 * Delete the first cell in list that matches datum, if any.
 * Equality is determined via equal().
 *
 * This does a simple linear search --- avoid using it on long lists.
 */


/* As above, but use simple pointer equality */


/* As above, but for integers */


/* As above, but for OIDs */


/*
 * Delete the first element of the list.
 *
 * This is useful to replace the Lisp-y code "list = lnext(list);" in cases
 * where the intent is to alter the list rather than just traverse it.
 * Beware that the list is modified, whereas the Lisp-y coding leaves
 * the original list head intact in case there's another pointer to it.
 *
 * Note that this takes time proportional to the length of the list,
 * since the remaining entries must be moved.  Consider reversing the
 * list order so that you can use list_delete_last() instead.  However,
 * if that causes you to replace lappend() with lcons(), you haven't
 * improved matters.  (In short, you can make an efficient stack from
 * a List, but not an efficient FIFO queue.)
 */


/*
 * Delete the last element of the list.
 */


/*
 * Delete the first N cells of the list.
 *
 * The List is pfree'd if the request causes all cells to be deleted.
 *
 * Note that this takes time proportional to the distance to the end of the
 * list, since the following entries must be moved.
 */
#ifndef DEBUG_LIST_MEMORY_USAGE
#else
#ifdef CLOBBER_FREED_MEMORY
#else
#endif
#endif

/*
 * Generate the union of two lists. This is calculated by copying
 * list1 via list_copy(), then adding to it all the members of list2
 * that aren't already in list1.
 *
 * Whether an element is already a member of the list is determined
 * via equal().
 *
 * The returned list is newly-allocated, although the content of the
 * cells is the same (i.e. any pointed-to objects are not copied).
 *
 * NB: this function will NOT remove any duplicates that are present
 * in list1 (so it only performs a "union" if list1 is known unique to
 * start with).  Also, if you are about to write "x = list_union(x, y)"
 * you probably want to use list_concat_unique() instead to avoid wasting
 * the storage of the old x list.
 *
 * Note that this takes time proportional to the product of the list
 * lengths, so beware of using it on long lists.  (We could probably
 * improve that, but really you should be using some other data structure
 * if this'd be a performance bottleneck.)
 */


/*
 * This variant of list_union() determines duplicates via simple
 * pointer comparison.
 */


/*
 * This variant of list_union() operates upon lists of integers.
 */


/*
 * This variant of list_union() operates upon lists of OIDs.
 */


/*
 * Return a list that contains all the cells that are in both list1 and
 * list2.  The returned list is freshly allocated via palloc(), but the
 * cells themselves point to the same objects as the cells of the
 * input lists.
 *
 * Duplicate entries in list1 will not be suppressed, so it's only a true
 * "intersection" if list1 is known unique beforehand.
 *
 * This variant works on lists of pointers, and determines list
 * membership via equal().  Note that the list1 member will be pointed
 * to in the result.
 *
 * Note that this takes time proportional to the product of the list
 * lengths, so beware of using it on long lists.  (We could probably
 * improve that, but really you should be using some other data structure
 * if this'd be a performance bottleneck.)
 */


/*
 * As list_intersection but operates on lists of integers.
 */


/*
 * Return a list that contains all the cells in list1 that are not in
 * list2. The returned list is freshly allocated via palloc(), but the
 * cells themselves point to the same objects as the cells of the
 * input lists.
 *
 * This variant works on lists of pointers, and determines list
 * membership via equal()
 *
 * Note that this takes time proportional to the product of the list
 * lengths, so beware of using it on long lists.  (We could probably
 * improve that, but really you should be using some other data structure
 * if this'd be a performance bottleneck.)
 */


/*
 * This variant of list_difference() determines list membership via
 * simple pointer equality.
 */


/*
 * This variant of list_difference() operates upon lists of integers.
 */


/*
 * This variant of list_difference() operates upon lists of OIDs.
 */


/*
 * Append datum to list, but only if it isn't already in the list.
 *
 * Whether an element is already a member of the list is determined
 * via equal().
 *
 * This does a simple linear search --- avoid using it on long lists.
 */


/*
 * This variant of list_append_unique() determines list membership via
 * simple pointer equality.
 */


/*
 * This variant of list_append_unique() operates upon lists of integers.
 */


/*
 * This variant of list_append_unique() operates upon lists of OIDs.
 */


/*
 * Append to list1 each member of list2 that isn't already in list1.
 *
 * Whether an element is already a member of the list is determined
 * via equal().
 *
 * This is almost the same functionality as list_union(), but list1 is
 * modified in-place rather than being copied. However, callers of this
 * function may have strict ordering expectations -- i.e. that the relative
 * order of those list2 elements that are not duplicates is preserved.
 *
 * Note that this takes time proportional to the product of the list
 * lengths, so beware of using it on long lists.  (We could probably
 * improve that, but really you should be using some other data structure
 * if this'd be a performance bottleneck.)
 */


/*
 * This variant of list_concat_unique() determines list membership via
 * simple pointer equality.
 */


/*
 * This variant of list_concat_unique() operates upon lists of integers.
 */


/*
 * This variant of list_concat_unique() operates upon lists of OIDs.
 */


/*
 * Remove adjacent duplicates in a list of OIDs.
 *
 * It is caller's responsibility to have sorted the list to bring duplicates
 * together, perhaps via list_sort(list, list_oid_cmp).
 *
 * Note that this takes time proportional to the length of the list.
 */


/*
 * Free all storage in a list, and optionally the pointed-to elements
 */
static void
list_free_private(List *list, bool deep)
{
	if (list == NIL)
		return;					/* nothing to do */

	check_list_invariants(list);

	if (deep)
	{
		for (int i = 0; i < list->length; i++)
			pfree(lfirst(&list->elements[i]));
	}
	if (list->elements != list->initial_elements)
		pfree(list->elements);
	pfree(list);
}

/*
 * Free all the cells of the list, as well as the list itself. Any
 * objects that are pointed-to by the cells of the list are NOT
 * free'd.
 *
 * On return, the argument to this function has been freed, so the
 * caller would be wise to set it to NIL for safety's sake.
 */
void
list_free(List *list)
{
	list_free_private(list, false);
}

/*
 * Free all the cells of the list, the list itself, and all the
 * objects pointed-to by the cells of the list (each element in the
 * list must contain a pointer to a palloc()'d region of memory!)
 *
 * On return, the argument to this function has been freed, so the
 * caller would be wise to set it to NIL for safety's sake.
 */


/*
 * Return a shallow copy of the specified list.
 */
List *
list_copy(const List *oldlist)
{
	List	   *newlist;

	if (oldlist == NIL)
		return NIL;

	newlist = new_list(oldlist->type, oldlist->length);
	memcpy(newlist->elements, oldlist->elements,
		   newlist->length * sizeof(ListCell));

	check_list_invariants(newlist);
	return newlist;
}

/*
 * Return a shallow copy of the specified list containing only the first 'len'
 * elements.  If oldlist is shorter than 'len' then we copy the entire list.
 */


/*
 * Return a shallow copy of the specified list, without the first N elements.
 */
List *
list_copy_tail(const List *oldlist, int nskip)
{
	List	   *newlist;

	if (nskip < 0)
		nskip = 0;				/* would it be better to elog? */

	if (oldlist == NIL || nskip >= oldlist->length)
		return NIL;

	newlist = new_list(oldlist->type, oldlist->length - nskip);
	memcpy(newlist->elements, &oldlist->elements[nskip],
		   newlist->length * sizeof(ListCell));

	check_list_invariants(newlist);
	return newlist;
}

/*
 * Return a deep copy of the specified list.
 *
 * The list elements are copied via copyObject(), so that this function's
 * idea of a "deep" copy is considerably deeper than what list_free_deep()
 * means by the same word.
 */
List *
list_copy_deep(const List *oldlist)
{
	List	   *newlist;

	if (oldlist == NIL)
		return NIL;

	/* This is only sensible for pointer Lists */
	Assert(IsA(oldlist, List));

	newlist = new_list(oldlist->type, oldlist->length);
	for (int i = 0; i < newlist->length; i++)
		lfirst(&newlist->elements[i]) =
			copyObjectImpl(lfirst(&oldlist->elements[i]));

	check_list_invariants(newlist);
	return newlist;
}

/*
 * Sort a list according to the specified comparator function.
 *
 * The list is sorted in-place.
 *
 * The comparator function is declared to receive arguments of type
 * const ListCell *; this allows it to use lfirst() and variants
 * without casting its arguments.  Otherwise it behaves the same as
 * the comparator function for standard qsort().
 *
 * Like qsort(), this provides no guarantees about sort stability
 * for equal keys.
 *
 * This is based on qsort(), so it likewise has O(N log N) runtime.
 */


/*
 * list_sort comparator for sorting a list into ascending int order.
 */


/*
 * list_sort comparator for sorting a list into ascending OID order.
 */

