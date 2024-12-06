/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_qsort_strcmp
 *--------------------------------------------------------------------
 */

/*
 *	qsort.c: standard quicksort algorithm
 */

#include "c.h"

#define ST_SORT pg_qsort
#define ST_ELEMENT_TYPE_VOID
#define ST_COMPARE_RUNTIME_POINTER
#define ST_SCOPE
#define ST_DECLARE
#define ST_DEFINE
#include "lib/sort_template.h"

/*
 * qsort comparator wrapper for strcmp.
 */
int
pg_qsort_strcmp(const void *a, const void *b)
{
	return strcmp(*(const char *const *) a, *(const char *const *) b);
}
