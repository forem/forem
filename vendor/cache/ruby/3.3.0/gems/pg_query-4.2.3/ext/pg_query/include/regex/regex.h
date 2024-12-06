#ifndef _REGEX_H_
#define _REGEX_H_				/* never again */
/*
 * regular expressions
 *
 * Copyright (c) 1998, 1999 Henry Spencer.  All rights reserved.
 *
 * Development of this software was funded, in part, by Cray Research Inc.,
 * UUNET Communications Services Inc., Sun Microsystems Inc., and Scriptics
 * Corporation, none of whom are responsible for the results.  The author
 * thanks all of them.
 *
 * Redistribution and use in source and binary forms -- with or without
 * modification -- are permitted for any purpose, provided that
 * redistributions in source form retain this entire copyright notice and
 * indicate the origin and nature of any modifications.
 *
 * I'd appreciate being given credit for this package in the documentation
 * of software which uses it, but that is not a requirement.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * HENRY SPENCER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * src/include/regex/regex.h
 */

/*
 * Add your own defines, if needed, here.
 */
#include "mb/pg_wchar.h"

/*
 * interface types etc.
 */

/*
 * regoff_t has to be large enough to hold either off_t or ssize_t,
 * and must be signed; it's only a guess that long is suitable.
 */
typedef long regoff_t;

/*
 * other interface types
 */

/* the biggie, a compiled RE (or rather, a front end to same) */
typedef struct
{
	int			re_magic;		/* magic number */
	size_t		re_nsub;		/* number of subexpressions */
	long		re_info;		/* bitmask of the following flags: */
#define  REG_UBACKREF		000001	/* has back-reference (\n) */
#define  REG_ULOOKAROUND	000002	/* has lookahead/lookbehind constraint */
#define  REG_UBOUNDS		000004	/* has bounded quantifier ({m,n}) */
#define  REG_UBRACES		000010	/* has { that doesn't begin a quantifier */
#define  REG_UBSALNUM		000020	/* has backslash-alphanumeric in non-ARE */
#define  REG_UPBOTCH		000040	/* has unmatched right paren in ERE (legal
									 * per spec, but that was a mistake) */
#define  REG_UBBS			000100	/* has backslash within bracket expr */
#define  REG_UNONPOSIX		000200	/* has any construct that extends POSIX */
#define  REG_UUNSPEC		000400	/* has any case disallowed by POSIX, e.g.
									 * an empty branch */
#define  REG_UUNPORT		001000	/* has numeric character code dependency */
#define  REG_ULOCALE		002000	/* has locale dependency */
#define  REG_UEMPTYMATCH	004000	/* can match a zero-length string */
#define  REG_UIMPOSSIBLE	010000	/* provably cannot match anything */
#define  REG_USHORTEST		020000	/* has non-greedy quantifier */
	int			re_csize;		/* sizeof(character) */
	char	   *re_endp;		/* backward compatibility kludge */
	Oid			re_collation;	/* Collation that defines LC_CTYPE behavior */
	/* the rest is opaque pointers to hidden innards */
	char	   *re_guts;		/* `char *' is more portable than `void *' */
	char	   *re_fns;
} regex_t;

/* result reporting (may acquire more fields later) */
typedef struct
{
	regoff_t	rm_so;			/* start of substring */
	regoff_t	rm_eo;			/* end of substring */
} regmatch_t;

/* supplementary control and reporting */
typedef struct
{
	regmatch_t	rm_extend;		/* see REG_EXPECT */
} rm_detail_t;



/*
 * regex compilation flags
 */
#define REG_BASIC	000000		/* BREs (convenience) */
#define REG_EXTENDED	000001	/* EREs */
#define REG_ADVF	000002		/* advanced features in EREs */
#define REG_ADVANCED	000003	/* AREs (which are also EREs) */
#define REG_QUOTE	000004		/* no special characters, none */
#define REG_NOSPEC	REG_QUOTE	/* historical synonym */
#define REG_ICASE	000010		/* ignore case */
#define REG_NOSUB	000020		/* caller doesn't need subexpr match data */
#define REG_EXPANDED	000040	/* expanded format, white space & comments */
#define REG_NLSTOP	000100		/* \n doesn't match . or [^ ] */
#define REG_NLANCH	000200		/* ^ matches after \n, $ before */
#define REG_NEWLINE 000300		/* newlines are line terminators */
#define REG_PEND	000400		/* ugh -- backward-compatibility hack */
#define REG_EXPECT	001000		/* report details on partial/limited matches */
#define REG_BOSONLY 002000		/* temporary kludge for BOS-only matches */
#define REG_DUMP	004000		/* none of your business :-) */
#define REG_FAKE	010000		/* none of your business :-) */
#define REG_PROGRESS	020000	/* none of your business :-) */



/*
 * regex execution flags
 */
#define REG_NOTBOL	0001		/* BOS is not BOL */
#define REG_NOTEOL	0002		/* EOS is not EOL */
#define REG_STARTEND	0004	/* backward compatibility kludge */
#define REG_FTRACE	0010		/* none of your business */
#define REG_MTRACE	0020		/* none of your business */
#define REG_SMALL	0040		/* none of your business */


/*
 * error reporting
 * Be careful if modifying the list of error codes -- the table used by
 * regerror() is generated automatically from this file!
 */
#define REG_OKAY	 0			/* no errors detected */
#define REG_NOMATCH  1			/* failed to match */
#define REG_BADPAT	 2			/* invalid regexp */
#define REG_ECOLLATE	 3		/* invalid collating element */
#define REG_ECTYPE	 4			/* invalid character class */
#define REG_EESCAPE  5			/* invalid escape \ sequence */
#define REG_ESUBREG  6			/* invalid backreference number */
#define REG_EBRACK	 7			/* brackets [] not balanced */
#define REG_EPAREN	 8			/* parentheses () not balanced */
#define REG_EBRACE	 9			/* braces {} not balanced */
#define REG_BADBR	10			/* invalid repetition count(s) */
#define REG_ERANGE	11			/* invalid character range */
#define REG_ESPACE	12			/* out of memory */
#define REG_BADRPT	13			/* quantifier operand invalid */
#define REG_ASSERT	15			/* "can't happen" -- you found a bug */
#define REG_INVARG	16			/* invalid argument to regex function */
#define REG_MIXED	17			/* character widths of regex and string differ */
#define REG_BADOPT	18			/* invalid embedded option */
#define REG_ETOOBIG 19			/* regular expression is too complex */
#define REG_ECOLORS 20			/* too many colors */
#define REG_CANCEL	21			/* operation cancelled */
/* two specials for debugging and testing */
#define REG_ATOI	101			/* convert error-code name to number */
#define REG_ITOA	102			/* convert error-code number to name */
/* non-error result codes for pg_regprefix */
#define REG_PREFIX	(-1)		/* identified a common prefix */
#define REG_EXACT	(-2)		/* identified an exact match */



/*
 * the prototypes for exported functions
 */

/* regcomp.c */
extern int	pg_regcomp(regex_t *, const pg_wchar *, size_t, int, Oid);
extern int	pg_regexec(regex_t *, const pg_wchar *, size_t, size_t, rm_detail_t *, size_t, regmatch_t[], int);
extern int	pg_regprefix(regex_t *, pg_wchar **, size_t *);
extern void pg_regfree(regex_t *);
extern size_t pg_regerror(int, const regex_t *, char *, size_t);

/* regexp.c */
extern regex_t *RE_compile_and_cache(text *text_re, int cflags, Oid collation);
extern bool RE_compile_and_execute(text *text_re, char *dat, int dat_len,
								   int cflags, Oid collation,
								   int nmatch, regmatch_t *pmatch);

#endif							/* _REGEX_H_ */
