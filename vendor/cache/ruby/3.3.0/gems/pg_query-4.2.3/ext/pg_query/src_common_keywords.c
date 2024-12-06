/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - ScanKeywordCategories
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * keywords.c
 *	  PostgreSQL's list of SQL keywords
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/common/keywords.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#include "common/keywords.h"


/* ScanKeywordList lookup data for SQL keywords */

#include "kwlist_d.h"

/* Keyword categories for SQL keywords */

#define PG_KEYWORD(kwname, value, category, collabel) category,

const uint8 ScanKeywordCategories[SCANKEYWORDS_NUM_KEYWORDS] = {
#include "parser/kwlist.h"
};

#undef PG_KEYWORD

/* Keyword can-be-bare-label flags for SQL keywords */

#define PG_KEYWORD(kwname, value, category, collabel) collabel,

#define BARE_LABEL true
#define AS_LABEL false



#undef PG_KEYWORD
#undef BARE_LABEL
#undef AS_LABEL
