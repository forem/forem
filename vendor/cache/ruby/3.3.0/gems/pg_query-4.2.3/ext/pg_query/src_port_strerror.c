/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_strerror_r
 * - gnuish_strerror_r
 * - get_errno_symbol
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * strerror.c
 *	  Replacements for standard strerror() and strerror_r() functions
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/port/strerror.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

/*
 * Within this file, "strerror" means the platform's function not pg_strerror,
 * and likewise for "strerror_r"
 */
#undef strerror
#undef strerror_r

static char *gnuish_strerror_r(int errnum, char *buf, size_t buflen);
static char *get_errno_symbol(int errnum);
#ifdef WIN32
static char *win32_socket_strerror(int errnum, char *buf, size_t buflen);
#endif


/*
 * A slightly cleaned-up version of strerror()
 */


/*
 * A slightly cleaned-up version of strerror_r()
 */
char *
pg_strerror_r(int errnum, char *buf, size_t buflen)
{
	char	   *str;

	/* If it's a Windows Winsock error, that needs special handling */
#ifdef WIN32
	/* Winsock error code range, per WinError.h */
	if (errnum >= 10000 && errnum <= 11999)
		return win32_socket_strerror(errnum, buf, buflen);
#endif

	/* Try the platform's strerror_r(), or maybe just strerror() */
	str = gnuish_strerror_r(errnum, buf, buflen);

	/*
	 * Some strerror()s return an empty string for out-of-range errno.  This
	 * is ANSI C spec compliant, but not exactly useful.  Also, we may get
	 * back strings of question marks if libc cannot transcode the message to
	 * the codeset specified by LC_CTYPE.  If we get nothing useful, first try
	 * get_errno_symbol(), and if that fails, print the numeric errno.
	 */
	if (str == NULL || *str == '\0' || *str == '?')
		str = get_errno_symbol(errnum);

	if (str == NULL)
	{
		snprintf(buf, buflen, _("operating system error %d"), errnum);
		str = buf;
	}

	return str;
}

/*
 * Simple wrapper to emulate GNU strerror_r if what the platform provides is
 * POSIX.  Also, if platform lacks strerror_r altogether, fall back to plain
 * strerror; it might not be very thread-safe, but tough luck.
 */
static char *
gnuish_strerror_r(int errnum, char *buf, size_t buflen)
{
#ifdef HAVE_STRERROR_R
#ifdef STRERROR_R_INT
	/* POSIX API */
	if (strerror_r(errnum, buf, buflen) == 0)
		return buf;
	return NULL;				/* let caller deal with failure */
#else
	/* GNU API */
	return strerror_r(errnum, buf, buflen);
#endif
#else							/* !HAVE_STRERROR_R */
	char	   *sbuf = strerror(errnum);

	if (sbuf == NULL)			/* can this still happen anywhere? */
		return NULL;
	/* To minimize thread-unsafety hazard, copy into caller's buffer */
	strlcpy(buf, sbuf, buflen);
	return buf;
#endif
}

/*
 * Returns a symbol (e.g. "ENOENT") for an errno code.
 * Returns NULL if the code is unrecognized.
 */
static char *
get_errno_symbol(int errnum)
{
	switch (errnum)
	{
		case E2BIG:
			return "E2BIG";
		case EACCES:
			return "EACCES";
		case EADDRINUSE:
			return "EADDRINUSE";
		case EADDRNOTAVAIL:
			return "EADDRNOTAVAIL";
		case EAFNOSUPPORT:
			return "EAFNOSUPPORT";
#ifdef EAGAIN
		case EAGAIN:
			return "EAGAIN";
#endif
#ifdef EALREADY
		case EALREADY:
			return "EALREADY";
#endif
		case EBADF:
			return "EBADF";
#ifdef EBADMSG
		case EBADMSG:
			return "EBADMSG";
#endif
		case EBUSY:
			return "EBUSY";
		case ECHILD:
			return "ECHILD";
		case ECONNABORTED:
			return "ECONNABORTED";
		case ECONNREFUSED:
			return "ECONNREFUSED";
		case ECONNRESET:
			return "ECONNRESET";
		case EDEADLK:
			return "EDEADLK";
		case EDOM:
			return "EDOM";
		case EEXIST:
			return "EEXIST";
		case EFAULT:
			return "EFAULT";
		case EFBIG:
			return "EFBIG";
		case EHOSTDOWN:
			return "EHOSTDOWN";
		case EHOSTUNREACH:
			return "EHOSTUNREACH";
		case EIDRM:
			return "EIDRM";
		case EINPROGRESS:
			return "EINPROGRESS";
		case EINTR:
			return "EINTR";
		case EINVAL:
			return "EINVAL";
		case EIO:
			return "EIO";
		case EISCONN:
			return "EISCONN";
		case EISDIR:
			return "EISDIR";
#ifdef ELOOP
		case ELOOP:
			return "ELOOP";
#endif
		case EMFILE:
			return "EMFILE";
		case EMLINK:
			return "EMLINK";
		case EMSGSIZE:
			return "EMSGSIZE";
		case ENAMETOOLONG:
			return "ENAMETOOLONG";
		case ENETDOWN:
			return "ENETDOWN";
		case ENETRESET:
			return "ENETRESET";
		case ENETUNREACH:
			return "ENETUNREACH";
		case ENFILE:
			return "ENFILE";
		case ENOBUFS:
			return "ENOBUFS";
		case ENODEV:
			return "ENODEV";
		case ENOENT:
			return "ENOENT";
		case ENOEXEC:
			return "ENOEXEC";
		case ENOMEM:
			return "ENOMEM";
		case ENOSPC:
			return "ENOSPC";
		case ENOSYS:
			return "ENOSYS";
		case ENOTCONN:
			return "ENOTCONN";
		case ENOTDIR:
			return "ENOTDIR";
#if defined(ENOTEMPTY) && (ENOTEMPTY != EEXIST) /* same code on AIX */
		case ENOTEMPTY:
			return "ENOTEMPTY";
#endif
		case ENOTSOCK:
			return "ENOTSOCK";
#ifdef ENOTSUP
		case ENOTSUP:
			return "ENOTSUP";
#endif
		case ENOTTY:
			return "ENOTTY";
		case ENXIO:
			return "ENXIO";
#if defined(EOPNOTSUPP) && (!defined(ENOTSUP) || (EOPNOTSUPP != ENOTSUP))
		case EOPNOTSUPP:
			return "EOPNOTSUPP";
#endif
#ifdef EOVERFLOW
		case EOVERFLOW:
			return "EOVERFLOW";
#endif
		case EPERM:
			return "EPERM";
		case EPIPE:
			return "EPIPE";
		case EPROTONOSUPPORT:
			return "EPROTONOSUPPORT";
		case ERANGE:
			return "ERANGE";
#ifdef EROFS
		case EROFS:
			return "EROFS";
#endif
		case ESRCH:
			return "ESRCH";
		case ETIMEDOUT:
			return "ETIMEDOUT";
#ifdef ETXTBSY
		case ETXTBSY:
			return "ETXTBSY";
#endif
#if defined(EWOULDBLOCK) && (!defined(EAGAIN) || (EWOULDBLOCK != EAGAIN))
		case EWOULDBLOCK:
			return "EWOULDBLOCK";
#endif
		case EXDEV:
			return "EXDEV";
	}

	return NULL;
}


#ifdef WIN32

/*
 * Windows' strerror() doesn't know the Winsock codes, so handle them this way
 */
static char *
win32_socket_strerror(int errnum, char *buf, size_t buflen)
{
	static HANDLE handleDLL = INVALID_HANDLE_VALUE;

	if (handleDLL == INVALID_HANDLE_VALUE)
	{
		handleDLL = LoadLibraryEx("netmsg.dll", NULL,
								  DONT_RESOLVE_DLL_REFERENCES | LOAD_LIBRARY_AS_DATAFILE);
		if (handleDLL == NULL)
		{
			snprintf(buf, buflen,
					 "winsock error %d (could not load netmsg.dll to translate: error code %lu)",
					 errnum, GetLastError());
			return buf;
		}
	}

	ZeroMemory(buf, buflen);
	if (FormatMessage(FORMAT_MESSAGE_IGNORE_INSERTS |
					  FORMAT_MESSAGE_FROM_SYSTEM |
					  FORMAT_MESSAGE_FROM_HMODULE,
					  handleDLL,
					  errnum,
					  MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT),
					  buf,
					  buflen - 1,
					  NULL) == 0)
	{
		/* Failed to get id */
		snprintf(buf, buflen, "unrecognized winsock error %d", errnum);
	}

	return buf;
}

#endif							/* WIN32 */
