/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_vfprintf
 * - dopr
 * - pg_snprintf
 * - pg_vsnprintf
 * - strchrnul
 * - dostr
 * - find_arguments
 * - fmtint
 * - adjust_sign
 * - compute_padlen
 * - leading_pad
 * - dopr_outchmulti
 * - trailing_pad
 * - fmtchar
 * - fmtstr
 * - fmtptr
 * - fmtfloat
 * - dopr_outch
 * - flushbuffer
 * - pg_fprintf
 * - pg_sprintf
 * - pg_vsprintf
 * - pg_printf
 *--------------------------------------------------------------------
 */

/*
 * Copyright (c) 1983, 1995, 1996 Eric P. Allman
 * Copyright (c) 1988, 1993
 *	The Regents of the University of California.  All rights reserved.
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *	  notice, this list of conditions and the following disclaimer in the
 *	  documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *	  may be used to endorse or promote products derived from this software
 *	  without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * src/port/snprintf.c
 */

#include "c.h"

#include <math.h>

/*
 * We used to use the platform's NL_ARGMAX here, but that's a bad idea,
 * first because the point of this module is to remove platform dependencies
 * not perpetuate them, and second because some platforms use ridiculously
 * large values, leading to excessive stack consumption in dopr().
 */
#define PG_NL_ARGMAX 31


/*
 *	SNPRINTF, VSNPRINTF and friends
 *
 * These versions have been grabbed off the net.  They have been
 * cleaned up to compile properly and support for most of the C99
 * specification has been added.  Remaining unimplemented features are:
 *
 * 1. No locale support: the radix character is always '.' and the '
 * (single quote) format flag is ignored.
 *
 * 2. No support for the "%n" format specification.
 *
 * 3. No support for wide characters ("lc" and "ls" formats).
 *
 * 4. No support for "long double" ("Lf" and related formats).
 *
 * 5. Space and '#' flags are not implemented.
 *
 * In addition, we support some extensions over C99:
 *
 * 1. Argument order control through "%n$" and "*n$", as required by POSIX.
 *
 * 2. "%m" expands to the value of strerror(errno), where errno is the
 * value that variable had at the start of the call.  This is a glibc
 * extension, but a very useful one.
 *
 *
 * Historically the result values of sprintf/snprintf varied across platforms.
 * This implementation now follows the C99 standard:
 *
 * 1. -1 is returned if an error is detected in the format string, or if
 * a write to the target stream fails (as reported by fwrite).  Note that
 * overrunning snprintf's target buffer is *not* an error.
 *
 * 2. For successful writes to streams, the actual number of bytes written
 * to the stream is returned.
 *
 * 3. For successful sprintf/snprintf, the number of bytes that would have
 * been written to an infinite-size buffer (excluding the trailing '\0')
 * is returned.  snprintf will truncate its output to fit in the buffer
 * (ensuring a trailing '\0' unless count == 0), but this is not reflected
 * in the function result.
 *
 * snprintf buffer overrun can be detected by checking for function result
 * greater than or equal to the supplied count.
 */

/**************************************************************
 * Original:
 * Patrick Powell Tue Apr 11 09:48:21 PDT 1995
 * A bombproof version of doprnt (dopr) included.
 * Sigh.  This sort of thing is always nasty do deal with.  Note that
 * the version here does not include floating point. (now it does ... tgl)
 **************************************************************/

/* Prevent recursion */
#undef	vsnprintf
#undef	snprintf
#undef	vsprintf
#undef	sprintf
#undef	vfprintf
#undef	fprintf
#undef	vprintf
#undef	printf

/*
 * Info about where the formatted output is going.
 *
 * dopr and subroutines will not write at/past bufend, but snprintf
 * reserves one byte, ensuring it may place the trailing '\0' there.
 *
 * In snprintf, we use nchars to count the number of bytes dropped on the
 * floor due to buffer overrun.  The correct result of snprintf is thus
 * (bufptr - bufstart) + nchars.  (This isn't as inconsistent as it might
 * seem: nchars is the number of emitted bytes that are not in the buffer now,
 * either because we sent them to the stream or because we couldn't fit them
 * into the buffer to begin with.)
 */
typedef struct
{
	char	   *bufptr;			/* next buffer output position */
	char	   *bufstart;		/* first buffer element */
	char	   *bufend;			/* last+1 buffer element, or NULL */
	/* bufend == NULL is for sprintf, where we assume buf is big enough */
	FILE	   *stream;			/* eventual output destination, or NULL */
	int			nchars;			/* # chars sent to stream, or dropped */
	bool		failed;			/* call is a failure; errno is set */
} PrintfTarget;

/*
 * Info about the type and value of a formatting parameter.  Note that we
 * don't currently support "long double", "wint_t", or "wchar_t *" data,
 * nor the '%n' formatting code; else we'd need more types.  Also, at this
 * level we need not worry about signed vs unsigned values.
 */
typedef enum
{
	ATYPE_NONE = 0,
	ATYPE_INT,
	ATYPE_LONG,
	ATYPE_LONGLONG,
	ATYPE_DOUBLE,
	ATYPE_CHARPTR
} PrintfArgType;

typedef union
{
	int			i;
	long		l;
	long long	ll;
	double		d;
	char	   *cptr;
} PrintfArgValue;


static void flushbuffer(PrintfTarget *target);
static void dopr(PrintfTarget *target, const char *format, va_list args);


/*
 * Externally visible entry points.
 *
 * All of these are just wrappers around dopr().  Note it's essential that
 * they not change the value of "errno" before reaching dopr().
 */

int
pg_vsnprintf(char *str, size_t count, const char *fmt, va_list args)
{
	PrintfTarget target;
	char		onebyte[1];

	/*
	 * C99 allows the case str == NULL when count == 0.  Rather than
	 * special-casing this situation further down, we substitute a one-byte
	 * local buffer.  Callers cannot tell, since the function result doesn't
	 * depend on count.
	 */
	if (count == 0)
	{
		str = onebyte;
		count = 1;
	}
	target.bufstart = target.bufptr = str;
	target.bufend = str + count - 1;
	target.stream = NULL;
	target.nchars = 0;
	target.failed = false;
	dopr(&target, fmt, args);
	*(target.bufptr) = '\0';
	return target.failed ? -1 : (target.bufptr - target.bufstart
								 + target.nchars);
}

int
pg_snprintf(char *str, size_t count, const char *fmt,...)
{
	int			len;
	va_list		args;

	va_start(args, fmt);
	len = pg_vsnprintf(str, count, fmt, args);
	va_end(args);
	return len;
}

int
pg_vsprintf(char *str, const char *fmt, va_list args)
{
	PrintfTarget target;

	target.bufstart = target.bufptr = str;
	target.bufend = NULL;
	target.stream = NULL;
	target.nchars = 0;			/* not really used in this case */
	target.failed = false;
	dopr(&target, fmt, args);
	*(target.bufptr) = '\0';
	return target.failed ? -1 : (target.bufptr - target.bufstart
								 + target.nchars);
}

int
pg_sprintf(char *str, const char *fmt,...)
{
	int			len;
	va_list		args;

	va_start(args, fmt);
	len = pg_vsprintf(str, fmt, args);
	va_end(args);
	return len;
}

int
pg_vfprintf(FILE *stream, const char *fmt, va_list args)
{
	PrintfTarget target;
	char		buffer[1024];	/* size is arbitrary */

	if (stream == NULL)
	{
		errno = EINVAL;
		return -1;
	}
	target.bufstart = target.bufptr = buffer;
	target.bufend = buffer + sizeof(buffer);	/* use the whole buffer */
	target.stream = stream;
	target.nchars = 0;
	target.failed = false;
	dopr(&target, fmt, args);
	/* dump any remaining buffer contents */
	flushbuffer(&target);
	return target.failed ? -1 : target.nchars;
}

int
pg_fprintf(FILE *stream, const char *fmt,...)
{
	int			len;
	va_list		args;

	va_start(args, fmt);
	len = pg_vfprintf(stream, fmt, args);
	va_end(args);
	return len;
}



int
pg_printf(const char *fmt,...)
{
	int			len;
	va_list		args;

	va_start(args, fmt);
	len = pg_vfprintf(stdout, fmt, args);
	va_end(args);
	return len;
}

/*
 * Attempt to write the entire buffer to target->stream; discard the entire
 * buffer in any case.  Call this only when target->stream is defined.
 */
static void
flushbuffer(PrintfTarget *target)
{
	size_t		nc = target->bufptr - target->bufstart;

	/*
	 * Don't write anything if we already failed; this is to ensure we
	 * preserve the original failure's errno.
	 */
	if (!target->failed && nc > 0)
	{
		size_t		written;

		written = fwrite(target->bufstart, 1, nc, target->stream);
		target->nchars += written;
		if (written != nc)
			target->failed = true;
	}
	target->bufptr = target->bufstart;
}


static bool find_arguments(const char *format, va_list args,
						   PrintfArgValue *argvalues);
static void fmtstr(const char *value, int leftjust, int minlen, int maxwidth,
				   int pointflag, PrintfTarget *target);
static void fmtptr(const void *value, PrintfTarget *target);
static void fmtint(long long value, char type, int forcesign,
				   int leftjust, int minlen, int zpad, int precision, int pointflag,
				   PrintfTarget *target);
static void fmtchar(int value, int leftjust, int minlen, PrintfTarget *target);
static void fmtfloat(double value, char type, int forcesign,
					 int leftjust, int minlen, int zpad, int precision, int pointflag,
					 PrintfTarget *target);
static void dostr(const char *str, int slen, PrintfTarget *target);
static void dopr_outch(int c, PrintfTarget *target);
static void dopr_outchmulti(int c, int slen, PrintfTarget *target);
static int	adjust_sign(int is_negative, int forcesign, int *signvalue);
static int	compute_padlen(int minlen, int vallen, int leftjust);
static void leading_pad(int zpad, int signvalue, int *padlen,
						PrintfTarget *target);
static void trailing_pad(int padlen, PrintfTarget *target);

/*
 * If strchrnul exists (it's a glibc-ism), it's a good bit faster than the
 * equivalent manual loop.  If it doesn't exist, provide a replacement.
 *
 * Note: glibc declares this as returning "char *", but that would require
 * casting away const internally, so we don't follow that detail.
 */
#ifndef HAVE_STRCHRNUL

static inline const char *
strchrnul(const char *s, int c)
{
	while (*s != '\0' && *s != c)
		s++;
	return s;
}

#else

/*
 * glibc's <string.h> declares strchrnul only if _GNU_SOURCE is defined.
 * While we typically use that on glibc platforms, configure will set
 * HAVE_STRCHRNUL whether it's used or not.  Fill in the missing declaration
 * so that this file will compile cleanly with or without _GNU_SOURCE.
 */
#ifndef _GNU_SOURCE
extern char *strchrnul(const char *s, int c);
#endif

#endif							/* HAVE_STRCHRNUL */


/*
 * dopr(): the guts of *printf for all cases.
 */
static void
dopr(PrintfTarget *target, const char *format, va_list args)
{
	int			save_errno = errno;
	const char *first_pct = NULL;
	int			ch;
	bool		have_dollar;
	bool		have_star;
	bool		afterstar;
	int			accum;
	int			longlongflag;
	int			longflag;
	int			pointflag;
	int			leftjust;
	int			fieldwidth;
	int			precision;
	int			zpad;
	int			forcesign;
	int			fmtpos;
	int			cvalue;
	long long	numvalue;
	double		fvalue;
	const char *strvalue;
	PrintfArgValue argvalues[PG_NL_ARGMAX + 1];

	/*
	 * Initially, we suppose the format string does not use %n$.  The first
	 * time we come to a conversion spec that has that, we'll call
	 * find_arguments() to check for consistent use of %n$ and fill the
	 * argvalues array with the argument values in the correct order.
	 */
	have_dollar = false;

	while (*format != '\0')
	{
		/* Locate next conversion specifier */
		if (*format != '%')
		{
			/* Scan to next '%' or end of string */
			const char *next_pct = strchrnul(format + 1, '%');

			/* Dump literal data we just scanned over */
			dostr(format, next_pct - format, target);
			if (target->failed)
				break;

			if (*next_pct == '\0')
				break;
			format = next_pct;
		}

		/*
		 * Remember start of first conversion spec; if we find %n$, then it's
		 * sufficient for find_arguments() to start here, without rescanning
		 * earlier literal text.
		 */
		if (first_pct == NULL)
			first_pct = format;

		/* Process conversion spec starting at *format */
		format++;

		/* Fast path for conversion spec that is exactly %s */
		if (*format == 's')
		{
			format++;
			strvalue = va_arg(args, char *);
			if (strvalue == NULL)
				strvalue = "(null)";
			dostr(strvalue, strlen(strvalue), target);
			if (target->failed)
				break;
			continue;
		}

		fieldwidth = precision = zpad = leftjust = forcesign = 0;
		longflag = longlongflag = pointflag = 0;
		fmtpos = accum = 0;
		have_star = afterstar = false;
nextch2:
		ch = *format++;
		switch (ch)
		{
			case '-':
				leftjust = 1;
				goto nextch2;
			case '+':
				forcesign = 1;
				goto nextch2;
			case '0':
				/* set zero padding if no nonzero digits yet */
				if (accum == 0 && !pointflag)
					zpad = '0';
				/* FALL THRU */
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				accum = accum * 10 + (ch - '0');
				goto nextch2;
			case '.':
				if (have_star)
					have_star = false;
				else
					fieldwidth = accum;
				pointflag = 1;
				accum = 0;
				goto nextch2;
			case '*':
				if (have_dollar)
				{
					/*
					 * We'll process value after reading n$.  Note it's OK to
					 * assume have_dollar is set correctly, because in a valid
					 * format string the initial % must have had n$ if * does.
					 */
					afterstar = true;
				}
				else
				{
					/* fetch and process value now */
					int			starval = va_arg(args, int);

					if (pointflag)
					{
						precision = starval;
						if (precision < 0)
						{
							precision = 0;
							pointflag = 0;
						}
					}
					else
					{
						fieldwidth = starval;
						if (fieldwidth < 0)
						{
							leftjust = 1;
							fieldwidth = -fieldwidth;
						}
					}
				}
				have_star = true;
				accum = 0;
				goto nextch2;
			case '$':
				/* First dollar sign? */
				if (!have_dollar)
				{
					/* Yup, so examine all conversion specs in format */
					if (!find_arguments(first_pct, args, argvalues))
						goto bad_format;
					have_dollar = true;
				}
				if (afterstar)
				{
					/* fetch and process star value */
					int			starval = argvalues[accum].i;

					if (pointflag)
					{
						precision = starval;
						if (precision < 0)
						{
							precision = 0;
							pointflag = 0;
						}
					}
					else
					{
						fieldwidth = starval;
						if (fieldwidth < 0)
						{
							leftjust = 1;
							fieldwidth = -fieldwidth;
						}
					}
					afterstar = false;
				}
				else
					fmtpos = accum;
				accum = 0;
				goto nextch2;
			case 'l':
				if (longflag)
					longlongflag = 1;
				else
					longflag = 1;
				goto nextch2;
			case 'z':
#if SIZEOF_SIZE_T == 8
#ifdef HAVE_LONG_INT_64
				longflag = 1;
#elif defined(HAVE_LONG_LONG_INT_64)
				longlongflag = 1;
#else
#error "Don't know how to print 64bit integers"
#endif
#else
				/* assume size_t is same size as int */
#endif
				goto nextch2;
			case 'h':
			case '\'':
				/* ignore these */
				goto nextch2;
			case 'd':
			case 'i':
				if (!have_star)
				{
					if (pointflag)
						precision = accum;
					else
						fieldwidth = accum;
				}
				if (have_dollar)
				{
					if (longlongflag)
						numvalue = argvalues[fmtpos].ll;
					else if (longflag)
						numvalue = argvalues[fmtpos].l;
					else
						numvalue = argvalues[fmtpos].i;
				}
				else
				{
					if (longlongflag)
						numvalue = va_arg(args, long long);
					else if (longflag)
						numvalue = va_arg(args, long);
					else
						numvalue = va_arg(args, int);
				}
				fmtint(numvalue, ch, forcesign, leftjust, fieldwidth, zpad,
					   precision, pointflag, target);
				break;
			case 'o':
			case 'u':
			case 'x':
			case 'X':
				if (!have_star)
				{
					if (pointflag)
						precision = accum;
					else
						fieldwidth = accum;
				}
				if (have_dollar)
				{
					if (longlongflag)
						numvalue = (unsigned long long) argvalues[fmtpos].ll;
					else if (longflag)
						numvalue = (unsigned long) argvalues[fmtpos].l;
					else
						numvalue = (unsigned int) argvalues[fmtpos].i;
				}
				else
				{
					if (longlongflag)
						numvalue = (unsigned long long) va_arg(args, long long);
					else if (longflag)
						numvalue = (unsigned long) va_arg(args, long);
					else
						numvalue = (unsigned int) va_arg(args, int);
				}
				fmtint(numvalue, ch, forcesign, leftjust, fieldwidth, zpad,
					   precision, pointflag, target);
				break;
			case 'c':
				if (!have_star)
				{
					if (pointflag)
						precision = accum;
					else
						fieldwidth = accum;
				}
				if (have_dollar)
					cvalue = (unsigned char) argvalues[fmtpos].i;
				else
					cvalue = (unsigned char) va_arg(args, int);
				fmtchar(cvalue, leftjust, fieldwidth, target);
				break;
			case 's':
				if (!have_star)
				{
					if (pointflag)
						precision = accum;
					else
						fieldwidth = accum;
				}
				if (have_dollar)
					strvalue = argvalues[fmtpos].cptr;
				else
					strvalue = va_arg(args, char *);
				/* If string is NULL, silently substitute "(null)" */
				if (strvalue == NULL)
					strvalue = "(null)";
				fmtstr(strvalue, leftjust, fieldwidth, precision, pointflag,
					   target);
				break;
			case 'p':
				/* fieldwidth/leftjust are ignored ... */
				if (have_dollar)
					strvalue = argvalues[fmtpos].cptr;
				else
					strvalue = va_arg(args, char *);
				fmtptr((const void *) strvalue, target);
				break;
			case 'e':
			case 'E':
			case 'f':
			case 'g':
			case 'G':
				if (!have_star)
				{
					if (pointflag)
						precision = accum;
					else
						fieldwidth = accum;
				}
				if (have_dollar)
					fvalue = argvalues[fmtpos].d;
				else
					fvalue = va_arg(args, double);
				fmtfloat(fvalue, ch, forcesign, leftjust,
						 fieldwidth, zpad,
						 precision, pointflag,
						 target);
				break;
			case 'm':
				{
					char		errbuf[PG_STRERROR_R_BUFLEN];
					const char *errm = strerror_r(save_errno,
												  errbuf, sizeof(errbuf));

					dostr(errm, strlen(errm), target);
				}
				break;
			case '%':
				dopr_outch('%', target);
				break;
			default:

				/*
				 * Anything else --- in particular, '\0' indicating end of
				 * format string --- is bogus.
				 */
				goto bad_format;
		}

		/* Check for failure after each conversion spec */
		if (target->failed)
			break;
	}

	return;

bad_format:
	errno = EINVAL;
	target->failed = true;
}

/*
 * find_arguments(): sort out the arguments for a format spec with %n$
 *
 * If format is valid, return true and fill argvalues[i] with the value
 * for the conversion spec that has %i$ or *i$.  Else return false.
 */
static bool
find_arguments(const char *format, va_list args,
			   PrintfArgValue *argvalues)
{
	int			ch;
	bool		afterstar;
	int			accum;
	int			longlongflag;
	int			longflag;
	int			fmtpos;
	int			i;
	int			last_dollar;
	PrintfArgType argtypes[PG_NL_ARGMAX + 1];

	/* Initialize to "no dollar arguments known" */
	last_dollar = 0;
	MemSet(argtypes, 0, sizeof(argtypes));

	/*
	 * This loop must accept the same format strings as the one in dopr().
	 * However, we don't need to analyze them to the same level of detail.
	 *
	 * Since we're only called if there's a dollar-type spec somewhere, we can
	 * fail immediately if we find a non-dollar spec.  Per the C99 standard,
	 * all argument references in the format string must be one or the other.
	 */
	while (*format != '\0')
	{
		/* Locate next conversion specifier */
		if (*format != '%')
		{
			/* Unlike dopr, we can just quit if there's no more specifiers */
			format = strchr(format + 1, '%');
			if (format == NULL)
				break;
		}

		/* Process conversion spec starting at *format */
		format++;
		longflag = longlongflag = 0;
		fmtpos = accum = 0;
		afterstar = false;
nextch1:
		ch = *format++;
		switch (ch)
		{
			case '-':
			case '+':
				goto nextch1;
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				accum = accum * 10 + (ch - '0');
				goto nextch1;
			case '.':
				accum = 0;
				goto nextch1;
			case '*':
				if (afterstar)
					return false;	/* previous star missing dollar */
				afterstar = true;
				accum = 0;
				goto nextch1;
			case '$':
				if (accum <= 0 || accum > PG_NL_ARGMAX)
					return false;
				if (afterstar)
				{
					if (argtypes[accum] &&
						argtypes[accum] != ATYPE_INT)
						return false;
					argtypes[accum] = ATYPE_INT;
					last_dollar = Max(last_dollar, accum);
					afterstar = false;
				}
				else
					fmtpos = accum;
				accum = 0;
				goto nextch1;
			case 'l':
				if (longflag)
					longlongflag = 1;
				else
					longflag = 1;
				goto nextch1;
			case 'z':
#if SIZEOF_SIZE_T == 8
#ifdef HAVE_LONG_INT_64
				longflag = 1;
#elif defined(HAVE_LONG_LONG_INT_64)
				longlongflag = 1;
#else
#error "Don't know how to print 64bit integers"
#endif
#else
				/* assume size_t is same size as int */
#endif
				goto nextch1;
			case 'h':
			case '\'':
				/* ignore these */
				goto nextch1;
			case 'd':
			case 'i':
			case 'o':
			case 'u':
			case 'x':
			case 'X':
				if (fmtpos)
				{
					PrintfArgType atype;

					if (longlongflag)
						atype = ATYPE_LONGLONG;
					else if (longflag)
						atype = ATYPE_LONG;
					else
						atype = ATYPE_INT;
					if (argtypes[fmtpos] &&
						argtypes[fmtpos] != atype)
						return false;
					argtypes[fmtpos] = atype;
					last_dollar = Max(last_dollar, fmtpos);
				}
				else
					return false;	/* non-dollar conversion spec */
				break;
			case 'c':
				if (fmtpos)
				{
					if (argtypes[fmtpos] &&
						argtypes[fmtpos] != ATYPE_INT)
						return false;
					argtypes[fmtpos] = ATYPE_INT;
					last_dollar = Max(last_dollar, fmtpos);
				}
				else
					return false;	/* non-dollar conversion spec */
				break;
			case 's':
			case 'p':
				if (fmtpos)
				{
					if (argtypes[fmtpos] &&
						argtypes[fmtpos] != ATYPE_CHARPTR)
						return false;
					argtypes[fmtpos] = ATYPE_CHARPTR;
					last_dollar = Max(last_dollar, fmtpos);
				}
				else
					return false;	/* non-dollar conversion spec */
				break;
			case 'e':
			case 'E':
			case 'f':
			case 'g':
			case 'G':
				if (fmtpos)
				{
					if (argtypes[fmtpos] &&
						argtypes[fmtpos] != ATYPE_DOUBLE)
						return false;
					argtypes[fmtpos] = ATYPE_DOUBLE;
					last_dollar = Max(last_dollar, fmtpos);
				}
				else
					return false;	/* non-dollar conversion spec */
				break;
			case 'm':
			case '%':
				break;
			default:
				return false;	/* bogus format string */
		}

		/*
		 * If we finish the spec with afterstar still set, there's a
		 * non-dollar star in there.
		 */
		if (afterstar)
			return false;		/* non-dollar conversion spec */
	}

	/*
	 * Format appears valid so far, so collect the arguments in physical
	 * order.  (Since we rejected any non-dollar specs that would have
	 * collected arguments, we know that dopr() hasn't collected any yet.)
	 */
	for (i = 1; i <= last_dollar; i++)
	{
		switch (argtypes[i])
		{
			case ATYPE_NONE:
				return false;
			case ATYPE_INT:
				argvalues[i].i = va_arg(args, int);
				break;
			case ATYPE_LONG:
				argvalues[i].l = va_arg(args, long);
				break;
			case ATYPE_LONGLONG:
				argvalues[i].ll = va_arg(args, long long);
				break;
			case ATYPE_DOUBLE:
				argvalues[i].d = va_arg(args, double);
				break;
			case ATYPE_CHARPTR:
				argvalues[i].cptr = va_arg(args, char *);
				break;
		}
	}

	return true;
}

static void
fmtstr(const char *value, int leftjust, int minlen, int maxwidth,
	   int pointflag, PrintfTarget *target)
{
	int			padlen,
				vallen;			/* amount to pad */

	/*
	 * If a maxwidth (precision) is specified, we must not fetch more bytes
	 * than that.
	 */
	if (pointflag)
		vallen = strnlen(value, maxwidth);
	else
		vallen = strlen(value);

	padlen = compute_padlen(minlen, vallen, leftjust);

	if (padlen > 0)
	{
		dopr_outchmulti(' ', padlen, target);
		padlen = 0;
	}

	dostr(value, vallen, target);

	trailing_pad(padlen, target);
}

static void
fmtptr(const void *value, PrintfTarget *target)
{
	int			vallen;
	char		convert[64];

	/* we rely on regular C library's snprintf to do the basic conversion */
	vallen = snprintf(convert, sizeof(convert), "%p", value);
	if (vallen < 0)
		target->failed = true;
	else
		dostr(convert, vallen, target);
}

static void
fmtint(long long value, char type, int forcesign, int leftjust,
	   int minlen, int zpad, int precision, int pointflag,
	   PrintfTarget *target)
{
	unsigned long long uvalue;
	int			base;
	int			dosign;
	const char *cvt = "0123456789abcdef";
	int			signvalue = 0;
	char		convert[64];
	int			vallen = 0;
	int			padlen;			/* amount to pad */
	int			zeropad;		/* extra leading zeroes */

	switch (type)
	{
		case 'd':
		case 'i':
			base = 10;
			dosign = 1;
			break;
		case 'o':
			base = 8;
			dosign = 0;
			break;
		case 'u':
			base = 10;
			dosign = 0;
			break;
		case 'x':
			base = 16;
			dosign = 0;
			break;
		case 'X':
			cvt = "0123456789ABCDEF";
			base = 16;
			dosign = 0;
			break;
		default:
			return;				/* keep compiler quiet */
	}

	/* disable MSVC warning about applying unary minus to an unsigned value */
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable: 4146)
#endif
	/* Handle +/- */
	if (dosign && adjust_sign((value < 0), forcesign, &signvalue))
		uvalue = -(unsigned long long) value;
	else
		uvalue = (unsigned long long) value;
#ifdef _MSC_VER
#pragma warning(pop)
#endif

	/*
	 * SUS: the result of converting 0 with an explicit precision of 0 is no
	 * characters
	 */
	if (value == 0 && pointflag && precision == 0)
		vallen = 0;
	else
	{
		/*
		 * Convert integer to string.  We special-case each of the possible
		 * base values so as to avoid general-purpose divisions.  On most
		 * machines, division by a fixed constant can be done much more
		 * cheaply than a general divide.
		 */
		if (base == 10)
		{
			do
			{
				convert[sizeof(convert) - (++vallen)] = cvt[uvalue % 10];
				uvalue = uvalue / 10;
			} while (uvalue);
		}
		else if (base == 16)
		{
			do
			{
				convert[sizeof(convert) - (++vallen)] = cvt[uvalue % 16];
				uvalue = uvalue / 16;
			} while (uvalue);
		}
		else					/* base == 8 */
		{
			do
			{
				convert[sizeof(convert) - (++vallen)] = cvt[uvalue % 8];
				uvalue = uvalue / 8;
			} while (uvalue);
		}
	}

	zeropad = Max(0, precision - vallen);

	padlen = compute_padlen(minlen, vallen + zeropad, leftjust);

	leading_pad(zpad, signvalue, &padlen, target);

	if (zeropad > 0)
		dopr_outchmulti('0', zeropad, target);

	dostr(convert + sizeof(convert) - vallen, vallen, target);

	trailing_pad(padlen, target);
}

static void
fmtchar(int value, int leftjust, int minlen, PrintfTarget *target)
{
	int			padlen;			/* amount to pad */

	padlen = compute_padlen(minlen, 1, leftjust);

	if (padlen > 0)
	{
		dopr_outchmulti(' ', padlen, target);
		padlen = 0;
	}

	dopr_outch(value, target);

	trailing_pad(padlen, target);
}

static void
fmtfloat(double value, char type, int forcesign, int leftjust,
		 int minlen, int zpad, int precision, int pointflag,
		 PrintfTarget *target)
{
	int			signvalue = 0;
	int			prec;
	int			vallen;
	char		fmt[8];
	char		convert[1024];
	int			zeropadlen = 0; /* amount to pad with zeroes */
	int			padlen;			/* amount to pad with spaces */

	/*
	 * We rely on the regular C library's snprintf to do the basic conversion,
	 * then handle padding considerations here.
	 *
	 * The dynamic range of "double" is about 1E+-308 for IEEE math, and not
	 * too wildly more than that with other hardware.  In "f" format, snprintf
	 * could therefore generate at most 308 characters to the left of the
	 * decimal point; while we need to allow the precision to get as high as
	 * 308+17 to ensure that we don't truncate significant digits from very
	 * small values.  To handle both these extremes, we use a buffer of 1024
	 * bytes and limit requested precision to 350 digits; this should prevent
	 * buffer overrun even with non-IEEE math.  If the original precision
	 * request was more than 350, separately pad with zeroes.
	 *
	 * We handle infinities and NaNs specially to ensure platform-independent
	 * output.
	 */
	if (precision < 0)			/* cover possible overflow of "accum" */
		precision = 0;
	prec = Min(precision, 350);

	if (isnan(value))
	{
		strcpy(convert, "NaN");
		vallen = 3;
		/* no zero padding, regardless of precision spec */
	}
	else
	{
		/*
		 * Handle sign (NaNs have no sign, so we don't do this in the case
		 * above).  "value < 0.0" will not be true for IEEE minus zero, so we
		 * detect that by looking for the case where value equals 0.0
		 * according to == but not according to memcmp.
		 */
		static const double dzero = 0.0;

		if (adjust_sign((value < 0.0 ||
						 (value == 0.0 &&
						  memcmp(&value, &dzero, sizeof(double)) != 0)),
						forcesign, &signvalue))
			value = -value;

		if (isinf(value))
		{
			strcpy(convert, "Infinity");
			vallen = 8;
			/* no zero padding, regardless of precision spec */
		}
		else if (pointflag)
		{
			zeropadlen = precision - prec;
			fmt[0] = '%';
			fmt[1] = '.';
			fmt[2] = '*';
			fmt[3] = type;
			fmt[4] = '\0';
			vallen = snprintf(convert, sizeof(convert), fmt, prec, value);
		}
		else
		{
			fmt[0] = '%';
			fmt[1] = type;
			fmt[2] = '\0';
			vallen = snprintf(convert, sizeof(convert), fmt, value);
		}
		if (vallen < 0)
			goto fail;

		/*
		 * Windows, alone among our supported platforms, likes to emit
		 * three-digit exponent fields even when two digits would do.  Hack
		 * such results to look like the way everyone else does it.
		 */
#ifdef WIN32
		if (vallen >= 6 &&
			convert[vallen - 5] == 'e' &&
			convert[vallen - 3] == '0')
		{
			convert[vallen - 3] = convert[vallen - 2];
			convert[vallen - 2] = convert[vallen - 1];
			vallen--;
		}
#endif
	}

	padlen = compute_padlen(minlen, vallen + zeropadlen, leftjust);

	leading_pad(zpad, signvalue, &padlen, target);

	if (zeropadlen > 0)
	{
		/* If 'e' or 'E' format, inject zeroes before the exponent */
		char	   *epos = strrchr(convert, 'e');

		if (!epos)
			epos = strrchr(convert, 'E');
		if (epos)
		{
			/* pad before exponent */
			dostr(convert, epos - convert, target);
			dopr_outchmulti('0', zeropadlen, target);
			dostr(epos, vallen - (epos - convert), target);
		}
		else
		{
			/* no exponent, pad after the digits */
			dostr(convert, vallen, target);
			dopr_outchmulti('0', zeropadlen, target);
		}
	}
	else
	{
		/* no zero padding, just emit the number as-is */
		dostr(convert, vallen, target);
	}

	trailing_pad(padlen, target);
	return;

fail:
	target->failed = true;
}

/*
 * Nonstandard entry point to print a double value efficiently.
 *
 * This is approximately equivalent to strfromd(), but has an API more
 * adapted to what float8out() wants.  The behavior is like snprintf()
 * with a format of "%.ng", where n is the specified precision.
 * However, the target buffer must be nonempty (i.e. count > 0), and
 * the precision is silently bounded to a sane range.
 */
#ifdef WIN32
#endif


static void
dostr(const char *str, int slen, PrintfTarget *target)
{
	/* fast path for common case of slen == 1 */
	if (slen == 1)
	{
		dopr_outch(*str, target);
		return;
	}

	while (slen > 0)
	{
		int			avail;

		if (target->bufend != NULL)
			avail = target->bufend - target->bufptr;
		else
			avail = slen;
		if (avail <= 0)
		{
			/* buffer full, can we dump to stream? */
			if (target->stream == NULL)
			{
				target->nchars += slen; /* no, lose the data */
				return;
			}
			flushbuffer(target);
			continue;
		}
		avail = Min(avail, slen);
		memmove(target->bufptr, str, avail);
		target->bufptr += avail;
		str += avail;
		slen -= avail;
	}
}

static void
dopr_outch(int c, PrintfTarget *target)
{
	if (target->bufend != NULL && target->bufptr >= target->bufend)
	{
		/* buffer full, can we dump to stream? */
		if (target->stream == NULL)
		{
			target->nchars++;	/* no, lose the data */
			return;
		}
		flushbuffer(target);
	}
	*(target->bufptr++) = c;
}

static void
dopr_outchmulti(int c, int slen, PrintfTarget *target)
{
	/* fast path for common case of slen == 1 */
	if (slen == 1)
	{
		dopr_outch(c, target);
		return;
	}

	while (slen > 0)
	{
		int			avail;

		if (target->bufend != NULL)
			avail = target->bufend - target->bufptr;
		else
			avail = slen;
		if (avail <= 0)
		{
			/* buffer full, can we dump to stream? */
			if (target->stream == NULL)
			{
				target->nchars += slen; /* no, lose the data */
				return;
			}
			flushbuffer(target);
			continue;
		}
		avail = Min(avail, slen);
		memset(target->bufptr, c, avail);
		target->bufptr += avail;
		slen -= avail;
	}
}


static int
adjust_sign(int is_negative, int forcesign, int *signvalue)
{
	if (is_negative)
	{
		*signvalue = '-';
		return true;
	}
	else if (forcesign)
		*signvalue = '+';
	return false;
}


static int
compute_padlen(int minlen, int vallen, int leftjust)
{
	int			padlen;

	padlen = minlen - vallen;
	if (padlen < 0)
		padlen = 0;
	if (leftjust)
		padlen = -padlen;
	return padlen;
}


static void
leading_pad(int zpad, int signvalue, int *padlen, PrintfTarget *target)
{
	int			maxpad;

	if (*padlen > 0 && zpad)
	{
		if (signvalue)
		{
			dopr_outch(signvalue, target);
			--(*padlen);
			signvalue = 0;
		}
		if (*padlen > 0)
		{
			dopr_outchmulti(zpad, *padlen, target);
			*padlen = 0;
		}
	}
	maxpad = (signvalue != 0);
	if (*padlen > maxpad)
	{
		dopr_outchmulti(' ', *padlen - maxpad, target);
		*padlen = maxpad;
	}
	if (signvalue)
	{
		dopr_outch(signvalue, target);
		if (*padlen > 0)
			--(*padlen);
		else if (*padlen < 0)
			++(*padlen);
	}
}


static void
trailing_pad(int padlen, PrintfTarget *target)
{
	if (padlen < 0)
		dopr_outchmulti(' ', -padlen, target);
}
