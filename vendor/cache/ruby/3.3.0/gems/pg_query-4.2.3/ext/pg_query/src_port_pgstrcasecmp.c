/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_toupper
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * pgstrcasecmp.c
 *	   Portable SQL-like case-independent comparisons and conversions.
 *
 * SQL99 specifies Unicode-aware case normalization, which we don't yet
 * have the infrastructure for.  Instead we use tolower() to provide a
 * locale-aware translation.  However, there are some locales where this
 * is not right either (eg, Turkish may do strange things with 'i' and
 * 'I').  Our current compromise is to use tolower() for characters with
 * the high bit set, and use an ASCII-only downcasing for 7-bit
 * characters.
 *
 * NB: this code should match downcase_truncate_identifier() in scansup.c.
 *
 * We also provide strict ASCII-only case conversion functions, which can
 * be used to implement C/POSIX case folding semantics no matter what the
 * C library thinks the locale is.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * src/port/pgstrcasecmp.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#include <ctype.h>


/*
 * Case-independent comparison of two null-terminated strings.
 */


/*
 * Case-independent comparison of two not-necessarily-null-terminated strings.
 * At most n bytes will be examined from each string.
 */


/*
 * Fold a character to upper case.
 *
 * Unlike some versions of toupper(), this is safe to apply to characters
 * that aren't lower case letters.  Note however that the whole thing is
 * a bit bogus for multibyte character sets.
 */
unsigned char
pg_toupper(unsigned char ch)
{
	if (ch >= 'a' && ch <= 'z')
		ch += 'A' - 'a';
	else if (IS_HIGHBIT_SET(ch) && islower(ch))
		ch = toupper(ch);
	return ch;
}

/*
 * Fold a character to lower case.
 *
 * Unlike some versions of tolower(), this is safe to apply to characters
 * that aren't upper case letters.  Note however that the whole thing is
 * a bit bogus for multibyte character sets.
 */


/*
 * Fold a character to upper case, following C/POSIX locale rules.
 */


/*
 * Fold a character to lower case, following C/POSIX locale rules.
 */

