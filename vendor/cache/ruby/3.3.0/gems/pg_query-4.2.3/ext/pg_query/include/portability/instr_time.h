/*-------------------------------------------------------------------------
 *
 * instr_time.h
 *	  portable high-precision interval timing
 *
 * This file provides an abstraction layer to hide portability issues in
 * interval timing.  On Unix we use clock_gettime() if available, else
 * gettimeofday().  On Windows, gettimeofday() gives a low-precision result
 * so we must use QueryPerformanceCounter() instead.  These macros also give
 * some breathing room to use other high-precision-timing APIs.
 *
 * The basic data type is instr_time, which all callers should treat as an
 * opaque typedef.  instr_time can store either an absolute time (of
 * unspecified reference time) or an interval.  The operations provided
 * for it are:
 *
 * INSTR_TIME_IS_ZERO(t)			is t equal to zero?
 *
 * INSTR_TIME_SET_ZERO(t)			set t to zero (memset is acceptable too)
 *
 * INSTR_TIME_SET_CURRENT(t)		set t to current time
 *
 * INSTR_TIME_SET_CURRENT_LAZY(t)	set t to current time if t is zero,
 *									evaluates to whether t changed
 *
 * INSTR_TIME_ADD(x, y)				x += y
 *
 * INSTR_TIME_SUBTRACT(x, y)		x -= y
 *
 * INSTR_TIME_ACCUM_DIFF(x, y, z)	x += (y - z)
 *
 * INSTR_TIME_GET_DOUBLE(t)			convert t to double (in seconds)
 *
 * INSTR_TIME_GET_MILLISEC(t)		convert t to double (in milliseconds)
 *
 * INSTR_TIME_GET_MICROSEC(t)		convert t to uint64 (in microseconds)
 *
 * Note that INSTR_TIME_SUBTRACT and INSTR_TIME_ACCUM_DIFF convert
 * absolute times to intervals.  The INSTR_TIME_GET_xxx operations are
 * only useful on intervals.
 *
 * When summing multiple measurements, it's recommended to leave the
 * running sum in instr_time form (ie, use INSTR_TIME_ADD or
 * INSTR_TIME_ACCUM_DIFF) and convert to a result format only at the end.
 *
 * Beware of multiple evaluations of the macro arguments.
 *
 *
 * Copyright (c) 2001-2022, PostgreSQL Global Development Group
 *
 * src/include/portability/instr_time.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef INSTR_TIME_H
#define INSTR_TIME_H

#ifndef WIN32

#ifdef HAVE_CLOCK_GETTIME

/* Use clock_gettime() */

#include <time.h>

/*
 * The best clockid to use according to the POSIX spec is CLOCK_MONOTONIC,
 * since that will give reliable interval timing even in the face of changes
 * to the system clock.  However, POSIX doesn't require implementations to
 * provide anything except CLOCK_REALTIME, so fall back to that if we don't
 * find CLOCK_MONOTONIC.
 *
 * Also, some implementations have nonstandard clockids with better properties
 * than CLOCK_MONOTONIC.  In particular, as of macOS 10.12, Apple provides
 * CLOCK_MONOTONIC_RAW which is both faster to read and higher resolution than
 * their version of CLOCK_MONOTONIC.
 */
#if defined(__darwin__) && defined(CLOCK_MONOTONIC_RAW)
#define PG_INSTR_CLOCK	CLOCK_MONOTONIC_RAW
#elif defined(CLOCK_MONOTONIC)
#define PG_INSTR_CLOCK	CLOCK_MONOTONIC
#else
#define PG_INSTR_CLOCK	CLOCK_REALTIME
#endif

typedef struct timespec instr_time;

#define INSTR_TIME_IS_ZERO(t)	((t).tv_nsec == 0 && (t).tv_sec == 0)

#define INSTR_TIME_SET_ZERO(t)	((t).tv_sec = 0, (t).tv_nsec = 0)

#define INSTR_TIME_SET_CURRENT(t)	((void) clock_gettime(PG_INSTR_CLOCK, &(t)))

#define INSTR_TIME_ADD(x,y) \
	do { \
		(x).tv_sec += (y).tv_sec; \
		(x).tv_nsec += (y).tv_nsec; \
		/* Normalize */ \
		while ((x).tv_nsec >= 1000000000) \
		{ \
			(x).tv_nsec -= 1000000000; \
			(x).tv_sec++; \
		} \
	} while (0)

#define INSTR_TIME_SUBTRACT(x,y) \
	do { \
		(x).tv_sec -= (y).tv_sec; \
		(x).tv_nsec -= (y).tv_nsec; \
		/* Normalize */ \
		while ((x).tv_nsec < 0) \
		{ \
			(x).tv_nsec += 1000000000; \
			(x).tv_sec--; \
		} \
	} while (0)

#define INSTR_TIME_ACCUM_DIFF(x,y,z) \
	do { \
		(x).tv_sec += (y).tv_sec - (z).tv_sec; \
		(x).tv_nsec += (y).tv_nsec - (z).tv_nsec; \
		/* Normalize after each add to avoid overflow/underflow of tv_nsec */ \
		while ((x).tv_nsec < 0) \
		{ \
			(x).tv_nsec += 1000000000; \
			(x).tv_sec--; \
		} \
		while ((x).tv_nsec >= 1000000000) \
		{ \
			(x).tv_nsec -= 1000000000; \
			(x).tv_sec++; \
		} \
	} while (0)

#define INSTR_TIME_GET_DOUBLE(t) \
	(((double) (t).tv_sec) + ((double) (t).tv_nsec) / 1000000000.0)

#define INSTR_TIME_GET_MILLISEC(t) \
	(((double) (t).tv_sec * 1000.0) + ((double) (t).tv_nsec) / 1000000.0)

#define INSTR_TIME_GET_MICROSEC(t) \
	(((uint64) (t).tv_sec * (uint64) 1000000) + (uint64) ((t).tv_nsec / 1000))

#else							/* !HAVE_CLOCK_GETTIME */

/* Use gettimeofday() */

#include <sys/time.h>

typedef struct timeval instr_time;

#define INSTR_TIME_IS_ZERO(t)	((t).tv_usec == 0 && (t).tv_sec == 0)

#define INSTR_TIME_SET_ZERO(t)	((t).tv_sec = 0, (t).tv_usec = 0)

#define INSTR_TIME_SET_CURRENT(t)	gettimeofday(&(t), NULL)

#define INSTR_TIME_ADD(x,y) \
	do { \
		(x).tv_sec += (y).tv_sec; \
		(x).tv_usec += (y).tv_usec; \
		/* Normalize */ \
		while ((x).tv_usec >= 1000000) \
		{ \
			(x).tv_usec -= 1000000; \
			(x).tv_sec++; \
		} \
	} while (0)

#define INSTR_TIME_SUBTRACT(x,y) \
	do { \
		(x).tv_sec -= (y).tv_sec; \
		(x).tv_usec -= (y).tv_usec; \
		/* Normalize */ \
		while ((x).tv_usec < 0) \
		{ \
			(x).tv_usec += 1000000; \
			(x).tv_sec--; \
		} \
	} while (0)

#define INSTR_TIME_ACCUM_DIFF(x,y,z) \
	do { \
		(x).tv_sec += (y).tv_sec - (z).tv_sec; \
		(x).tv_usec += (y).tv_usec - (z).tv_usec; \
		/* Normalize after each add to avoid overflow/underflow of tv_usec */ \
		while ((x).tv_usec < 0) \
		{ \
			(x).tv_usec += 1000000; \
			(x).tv_sec--; \
		} \
		while ((x).tv_usec >= 1000000) \
		{ \
			(x).tv_usec -= 1000000; \
			(x).tv_sec++; \
		} \
	} while (0)

#define INSTR_TIME_GET_DOUBLE(t) \
	(((double) (t).tv_sec) + ((double) (t).tv_usec) / 1000000.0)

#define INSTR_TIME_GET_MILLISEC(t) \
	(((double) (t).tv_sec * 1000.0) + ((double) (t).tv_usec) / 1000.0)

#define INSTR_TIME_GET_MICROSEC(t) \
	(((uint64) (t).tv_sec * (uint64) 1000000) + (uint64) (t).tv_usec)

#endif							/* HAVE_CLOCK_GETTIME */

#else							/* WIN32 */

/* Use QueryPerformanceCounter() */

typedef LARGE_INTEGER instr_time;

#define INSTR_TIME_IS_ZERO(t)	((t).QuadPart == 0)

#define INSTR_TIME_SET_ZERO(t)	((t).QuadPart = 0)

#define INSTR_TIME_SET_CURRENT(t)	QueryPerformanceCounter(&(t))

#define INSTR_TIME_ADD(x,y) \
	((x).QuadPart += (y).QuadPart)

#define INSTR_TIME_SUBTRACT(x,y) \
	((x).QuadPart -= (y).QuadPart)

#define INSTR_TIME_ACCUM_DIFF(x,y,z) \
	((x).QuadPart += (y).QuadPart - (z).QuadPart)

#define INSTR_TIME_GET_DOUBLE(t) \
	(((double) (t).QuadPart) / GetTimerFrequency())

#define INSTR_TIME_GET_MILLISEC(t) \
	(((double) (t).QuadPart * 1000.0) / GetTimerFrequency())

#define INSTR_TIME_GET_MICROSEC(t) \
	((uint64) (((double) (t).QuadPart * 1000000.0) / GetTimerFrequency()))

static inline double
GetTimerFrequency(void)
{
	LARGE_INTEGER f;

	QueryPerformanceFrequency(&f);
	return (double) f.QuadPart;
}

#endif							/* WIN32 */

/* same macro on all platforms */

#define INSTR_TIME_SET_CURRENT_LAZY(t) \
	(INSTR_TIME_IS_ZERO(t) ? INSTR_TIME_SET_CURRENT(t), true : false)

#endif							/* INSTR_TIME_H */
