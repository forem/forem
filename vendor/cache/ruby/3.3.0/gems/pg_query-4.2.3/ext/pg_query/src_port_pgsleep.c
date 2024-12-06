/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_usleep
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * pgsleep.c
 *	   Portable delay handling.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * src/port/pgsleep.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#include <unistd.h>
#include <sys/time.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

/*
 * In a Windows backend, we don't use this implementation, but rather
 * the signal-aware version in src/backend/port/win32/signal.c.
 */
#if defined(FRONTEND) || !defined(WIN32)

/*
 * pg_usleep --- delay the specified number of microseconds.
 *
 * NOTE: although the delay is specified in microseconds, the effective
 * resolution is only 1/HZ, or 10 milliseconds, on most Unixen.  Expect
 * the requested delay to be rounded up to the next resolution boundary.
 *
 * On machines where "long" is 32 bits, the maximum delay is ~2000 seconds.
 *
 * CAUTION: the behavior when a signal arrives during the sleep is platform
 * dependent.  On most Unix-ish platforms, a signal does not terminate the
 * sleep; but on some, it will (the Windows implementation also allows signals
 * to terminate pg_usleep).  And there are platforms where not only does a
 * signal not terminate the sleep, but it actually resets the timeout counter
 * so that the sleep effectively starts over!  It is therefore rather hazardous
 * to use this for long sleeps; a continuing stream of signal events could
 * prevent the sleep from ever terminating.  Better practice for long sleeps
 * is to use WaitLatch() with a timeout.
 */
void
pg_usleep(long microsec)
{
	if (microsec > 0)
	{
#ifndef WIN32
		struct timeval delay;

		delay.tv_sec = microsec / 1000000L;
		delay.tv_usec = microsec % 1000000L;
		(void) select(0, NULL, NULL, NULL, &delay);
#else
		SleepEx((microsec < 500 ? 1 : (microsec + 500) / 1000), FALSE);
#endif
	}
}

#endif							/* defined(FRONTEND) || !defined(WIN32) */
