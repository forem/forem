/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - strnlen
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * strnlen.c
 *		Fallback implementation of strnlen().
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/port/strnlen.c
 *
 *-------------------------------------------------------------------------
 */

#include "c.h"

/*
 * Implementation of posix' strnlen for systems where it's not available.
 *
 * Returns the number of characters before a null-byte in the string pointed
 * to by str, unless there's no null-byte before maxlen. In the latter case
 * maxlen is returned.
 */
size_t
strnlen(const char *str, size_t maxlen)
{
	const char *p = str;

	while (maxlen-- > 0 && *p)
		p++;
	return p - str;
}
