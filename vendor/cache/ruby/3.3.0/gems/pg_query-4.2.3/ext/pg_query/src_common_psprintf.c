/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pvsnprintf
 * - psprintf
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * psprintf.c
 *		sprintf into an allocated-on-demand buffer
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/common/psprintf.c
 *
 *-------------------------------------------------------------------------
 */

#ifndef FRONTEND

#include "postgres.h"

#include "utils/memutils.h"

#else

#include "postgres_fe.h"

/* It's possible we could use a different value for this in frontend code */
#define MaxAllocSize	((Size) 0x3fffffff) /* 1 gigabyte - 1 */

#endif


/*
 * psprintf
 *
 * Format text data under the control of fmt (an sprintf-style format string)
 * and return it in an allocated-on-demand buffer.  The buffer is allocated
 * with palloc in the backend, or malloc in frontend builds.  Caller is
 * responsible to free the buffer when no longer needed, if appropriate.
 *
 * Errors are not returned to the caller, but are reported via elog(ERROR)
 * in the backend, or printf-to-stderr-and-exit() in frontend builds.
 * One should therefore think twice about using this in libpq.
 */
char *
psprintf(const char *fmt,...)
{
	int			save_errno = errno;
	size_t		len = 128;		/* initial assumption about buffer size */

	for (;;)
	{
		char	   *result;
		va_list		args;
		size_t		newlen;

		/*
		 * Allocate result buffer.  Note that in frontend this maps to malloc
		 * with exit-on-error.
		 */
		result = (char *) palloc(len);

		/* Try to format the data. */
		errno = save_errno;
		va_start(args, fmt);
		newlen = pvsnprintf(result, len, fmt, args);
		va_end(args);

		if (newlen < len)
			return result;		/* success */

		/* Release buffer and loop around to try again with larger len. */
		pfree(result);
		len = newlen;
	}
}

/*
 * pvsnprintf
 *
 * Attempt to format text data under the control of fmt (an sprintf-style
 * format string) and insert it into buf (which has length len).
 *
 * If successful, return the number of bytes emitted, not counting the
 * trailing zero byte.  This will always be strictly less than len.
 *
 * If there's not enough space in buf, return an estimate of the buffer size
 * needed to succeed (this *must* be more than the given len, else callers
 * might loop infinitely).
 *
 * Other error cases do not return, but exit via elog(ERROR) or exit().
 * Hence, this shouldn't be used inside libpq.
 *
 * Caution: callers must be sure to preserve their entry-time errno
 * when looping, in case the fmt contains "%m".
 *
 * Note that the semantics of the return value are not exactly C99's.
 * First, we don't promise that the estimated buffer size is exactly right;
 * callers must be prepared to loop multiple times to get the right size.
 * (Given a C99-compliant vsnprintf, that won't happen, but it is rumored
 * that some implementations don't always return the same value ...)
 * Second, we return the recommended buffer size, not one less than that;
 * this lets overflow concerns be handled here rather than in the callers.
 */
size_t
pvsnprintf(char *buf, size_t len, const char *fmt, va_list args)
{
	int			nprinted;

	nprinted = vsnprintf(buf, len, fmt, args);

	/* We assume failure means the fmt is bogus, hence hard failure is OK */
	if (unlikely(nprinted < 0))
	{
#ifndef FRONTEND
		elog(ERROR, "vsnprintf failed: %m with format string \"%s\"", fmt);
#else
		fprintf(stderr, "vsnprintf failed: %s with format string \"%s\"\n",
				strerror(errno), fmt);
		exit(EXIT_FAILURE);
#endif
	}

	if ((size_t) nprinted < len)
	{
		/* Success.  Note nprinted does not include trailing null. */
		return (size_t) nprinted;
	}

	/*
	 * We assume a C99-compliant vsnprintf, so believe its estimate of the
	 * required space, and add one for the trailing null.  (If it's wrong, the
	 * logic will still work, but we may loop multiple times.)
	 *
	 * Choke if the required space would exceed MaxAllocSize.  Note we use
	 * this palloc-oriented overflow limit even when in frontend.
	 */
	if (unlikely((size_t) nprinted > MaxAllocSize - 1))
	{
#ifndef FRONTEND
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("out of memory")));
#else
		fprintf(stderr, _("out of memory\n"));
		exit(EXIT_FAILURE);
#endif
	}

	return nprinted + 1;
}
