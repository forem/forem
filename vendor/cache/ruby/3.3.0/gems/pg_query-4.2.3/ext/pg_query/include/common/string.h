/*
 *	string.h
 *		string handling helpers
 *
 *	Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *	Portions Copyright (c) 1994, Regents of the University of California
 *
 *	src/include/common/string.h
 */
#ifndef COMMON_STRING_H
#define COMMON_STRING_H

struct StringInfoData;			/* avoid including stringinfo.h here */

typedef struct PromptInterruptContext
{
	/* To avoid including <setjmp.h> here, jmpbuf is declared "void *" */
	void	   *jmpbuf;			/* existing longjmp buffer */
	volatile bool *enabled;		/* flag that enables longjmp-on-interrupt */
	bool		canceled;		/* indicates whether cancellation occurred */
} PromptInterruptContext;

/* functions in src/common/string.c */
extern bool pg_str_endswith(const char *str, const char *end);
extern int	strtoint(const char *pg_restrict str, char **pg_restrict endptr,
					 int base);
extern void pg_clean_ascii(char *str);
extern int	pg_strip_crlf(char *str);
extern bool pg_is_ascii(const char *str);

/* functions in src/common/pg_get_line.c */
extern char *pg_get_line(FILE *stream, PromptInterruptContext *prompt_ctx);
extern bool pg_get_line_buf(FILE *stream, struct StringInfoData *buf);
extern bool pg_get_line_append(FILE *stream, struct StringInfoData *buf,
							   PromptInterruptContext *prompt_ctx);

/* functions in src/common/sprompt.c */
extern char *simple_prompt(const char *prompt, bool echo);
extern char *simple_prompt_extended(const char *prompt, bool echo,
									PromptInterruptContext *prompt_ctx);

#endif							/* COMMON_STRING_H */
