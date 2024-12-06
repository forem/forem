/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - format_type_be
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * format_type.c
 *	  Display type names "nicely".
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/utils/adt/format_type.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <ctype.h>

#include "access/htup_details.h"
#include "catalog/namespace.h"
#include "catalog/pg_type.h"
#include "mb/pg_wchar.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/numeric.h"
#include "utils/syscache.h"

static char *printTypmod(const char *typname, int32 typmod, Oid typmodout);


/*
 * SQL function: format_type(type_oid, typemod)
 *
 * `type_oid' is from pg_type.oid, `typemod' is from
 * pg_attribute.atttypmod. This function will get the type name and
 * format it and the modifier to canonical SQL format, if the type is
 * a standard type. Otherwise you just get pg_type.typname back,
 * double quoted if it contains funny characters or matches a keyword.
 *
 * If typemod is NULL then we are formatting a type name in a context where
 * no typemod is available, eg a function argument or result type.  This
 * yields a slightly different result from specifying typemod = -1 in some
 * cases.  Given typemod = -1 we feel compelled to produce an output that
 * the parser will interpret as having typemod -1, so that pg_dump will
 * produce CREATE TABLE commands that recreate the original state.  But
 * given NULL typemod, we assume that the parser's interpretation of
 * typemod doesn't matter, and so we are willing to output a slightly
 * "prettier" representation of the same type.  For example, type = bpchar
 * and typemod = NULL gets you "character", whereas typemod = -1 gets you
 * "bpchar" --- the former will be interpreted as character(1) by the
 * parser, which does not yield typemod -1.
 *
 * XXX encoding a meaning in typemod = NULL is ugly; it'd have been
 * cleaner to make two functions of one and two arguments respectively.
 * Not worth changing it now, however.
 */


/*
 * format_type_extended
 *		Generate a possibly-qualified type name.
 *
 * The default behavior is to only qualify if the type is not in the search
 * path, to ignore the given typmod, and to raise an error if a non-existent
 * type_oid is given.
 *
 * The following bits in 'flags' modify the behavior:
 * - FORMAT_TYPE_TYPEMOD_GIVEN
 *			include the typmod in the output (typmod could still be -1 though)
 * - FORMAT_TYPE_ALLOW_INVALID
 *			if the type OID is invalid or unknown, return ??? or such instead
 *			of failing
 * - FORMAT_TYPE_INVALID_AS_NULL
 *			if the type OID is invalid or unknown, return NULL instead of ???
 *			or such
 * - FORMAT_TYPE_FORCE_QUALIFY
 *			always schema-qualify type names, regardless of search_path
 *
 * Note that TYPEMOD_GIVEN is not interchangeable with "typemod == -1";
 * see the comments above for format_type().
 *
 * Returns a palloc'd string, or NULL.
 */


/*
 * This version is for use within the backend in error messages, etc.
 * One difference is that it will fail for an invalid type.
 *
 * The result is always a palloc'd string.
 */
char * format_type_be(Oid type_oid) { return pstrdup("-"); }


/*
 * This version returns a name that is always qualified (unless it's one
 * of the SQL-keyword type names, such as TIMESTAMP WITH TIME ZONE).
 */


/*
 * This version allows a nondefault typemod to be specified.
 */


/*
 * Add typmod decoration to the basic type name
 */



/*
 * type_maximum_size --- determine maximum width of a variable-width column
 *
 * If the max width is indeterminate, return -1.  In particular, we return
 * -1 for any type not known to this routine.  We assume the caller has
 * already determined that the type is a variable-width type, so it's not
 * necessary to look up the type's pg_type tuple here.
 *
 * This may appear unrelated to format_type(), but in fact the two routines
 * share knowledge of the encoding of typmod for different types, so it's
 * convenient to keep them together.  (XXX now that most of this knowledge
 * has been pushed out of format_type into the typmodout functions, it's
 * interesting to wonder if it's worth trying to factor this code too...)
 */



/*
 * oidvectortypes			- converts a vector of type OIDs to "typname" list
 */

