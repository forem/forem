/*-------------------------------------------------------------------------
 *
 * stringinfo_mb.h
 *	  multibyte support for StringInfo
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/mb/stringinfo_mb.h
 *-------------------------------------------------------------------------
 */
#ifndef STRINGINFO_MB_H
#define STRINGINFO_MB_H


#include "lib/stringinfo.h"

/*
 * Multibyte-aware StringInfo support function.
 */
extern void appendStringInfoStringQuoted(StringInfo str,
										 const char *s, int maxlen);

#endif							/* STRINGINFO_MB_H */
