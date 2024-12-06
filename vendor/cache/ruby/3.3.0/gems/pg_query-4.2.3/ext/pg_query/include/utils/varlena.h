/*-------------------------------------------------------------------------
 *
 * varlena.h
 *	  Functions for the variable-length built-in types.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/varlena.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef VARLENA_H
#define VARLENA_H

#include "nodes/pg_list.h"
#include "utils/sortsupport.h"

extern int	varstr_cmp(const char *arg1, int len1, const char *arg2, int len2, Oid collid);
extern void varstr_sortsupport(SortSupport ssup, Oid typid, Oid collid);
extern int	varstr_levenshtein(const char *source, int slen,
							   const char *target, int tlen,
							   int ins_c, int del_c, int sub_c,
							   bool trusted);
extern int	varstr_levenshtein_less_equal(const char *source, int slen,
										  const char *target, int tlen,
										  int ins_c, int del_c, int sub_c,
										  int max_d, bool trusted);
extern List *textToQualifiedNameList(text *textval);
extern bool SplitIdentifierString(char *rawstring, char separator,
								  List **namelist);
extern bool SplitDirectoriesString(char *rawstring, char separator,
								   List **namelist);
extern bool SplitGUCList(char *rawstring, char separator,
						 List **namelist);
extern text *replace_text_regexp(text *src_text, text *pattern_text,
								 text *replace_text,
								 int cflags, Oid collation,
								 int search_start, int n);

#endif
