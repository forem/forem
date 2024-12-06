/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - ScanKeywordLookup
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * kwlookup.c
 *	  Key word lookup for PostgreSQL
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/common/kwlookup.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#include "common/kwlookup.h"


/*
 * ScanKeywordLookup - see if a given word is a keyword
 *
 * The list of keywords to be matched against is passed as a ScanKeywordList.
 *
 * Returns the keyword number (0..N-1) of the keyword, or -1 if no match.
 * Callers typically use the keyword number to index into information
 * arrays, but that is no concern of this code.
 *
 * The match is done case-insensitively.  Note that we deliberately use a
 * dumbed-down case conversion that will only translate 'A'-'Z' into 'a'-'z',
 * even if we are in a locale where tolower() would produce more or different
 * translations.  This is to conform to the SQL99 spec, which says that
 * keywords are to be matched in this way even though non-keyword identifiers
 * receive a different case-normalization mapping.
 */
int
ScanKeywordLookup(const char *str,
				  const ScanKeywordList *keywords)
{
	size_t		len;
	int			h;
	const char *kw;

	/*
	 * Reject immediately if too long to be any keyword.  This saves useless
	 * hashing and downcasing work on long strings.
	 */
	len = strlen(str);
	if (len > keywords->max_kw_len)
		return -1;

	/*
	 * Compute the hash function.  We assume it was generated to produce
	 * case-insensitive results.  Since it's a perfect hash, we need only
	 * match to the specific keyword it identifies.
	 */
	h = keywords->hash(str, len);

	/* An out-of-range result implies no match */
	if (h < 0 || h >= keywords->num_keywords)
		return -1;

	/*
	 * Compare character-by-character to see if we have a match, applying an
	 * ASCII-only downcasing to the input characters.  We must not use
	 * tolower() since it may produce the wrong translation in some locales
	 * (eg, Turkish).
	 */
	kw = GetScanKeyword(h, keywords);
	while (*str != '\0')
	{
		char		ch = *str++;

		if (ch >= 'A' && ch <= 'Z')
			ch += 'a' - 'A';
		if (ch != *kw++)
			return -1;
	}
	if (*kw != '\0')
		return -1;

	/* Success! */
	return h;
}
