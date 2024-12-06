/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_popcount64
 * - pg_popcount64_slow
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * pg_bitutils.c
 *	  Miscellaneous functions for bit-wise operations.
 *
 * Copyright (c) 2019-2022, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/port/pg_bitutils.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#ifdef HAVE__GET_CPUID
#include <cpuid.h>
#endif
#ifdef HAVE__CPUID
#include <intrin.h>
#endif

#include "port/pg_bitutils.h"


/*
 * Array giving the position of the left-most set bit for each possible
 * byte value.  We count the right-most position as the 0th bit, and the
 * left-most the 7th bit.  The 0th entry of the array should not be used.
 *
 * Note: this is not used by the functions in pg_bitutils.h when
 * HAVE__BUILTIN_CLZ is defined, but we provide it anyway, so that
 * extensions possibly compiled with a different compiler can use it.
 */


/*
 * Array giving the position of the right-most set bit for each possible
 * byte value.  We count the right-most position as the 0th bit, and the
 * left-most the 7th bit.  The 0th entry of the array should not be used.
 *
 * Note: this is not used by the functions in pg_bitutils.h when
 * HAVE__BUILTIN_CTZ is defined, but we provide it anyway, so that
 * extensions possibly compiled with a different compiler can use it.
 */


/*
 * Array giving the number of 1-bits in each possible byte value.
 *
 * Note: we export this for use by functions in which explicit use
 * of the popcount functions seems unlikely to be a win.
 */


static int	pg_popcount32_slow(uint32 word);
static int	pg_popcount64_slow(uint64 word);

#ifdef TRY_POPCNT_FAST
static bool pg_popcount_available(void);
static int	pg_popcount32_choose(uint32 word);
static int	pg_popcount64_choose(uint64 word);
static int	pg_popcount32_fast(uint32 word);
static int	pg_popcount64_fast(uint64 word);

int			(*pg_popcount32) (uint32 word) = pg_popcount32_choose;
int			(*pg_popcount64) (uint64 word) = pg_popcount64_choose;
#endif							/* TRY_POPCNT_FAST */

#ifdef TRY_POPCNT_FAST

/*
 * Return true if CPUID indicates that the POPCNT instruction is available.
 */
static bool
pg_popcount_available(void)
{
	unsigned int exx[4] = {0, 0, 0, 0};

#if defined(HAVE__GET_CPUID)
	__get_cpuid(1, &exx[0], &exx[1], &exx[2], &exx[3]);
#elif defined(HAVE__CPUID)
	__cpuid(exx, 1);
#else
#error cpuid instruction not available
#endif

	return (exx[2] & (1 << 23)) != 0;	/* POPCNT */
}

/*
 * These functions get called on the first call to pg_popcount32 etc.
 * They detect whether we can use the asm implementations, and replace
 * the function pointers so that subsequent calls are routed directly to
 * the chosen implementation.
 */
static int
pg_popcount32_choose(uint32 word)
{
	if (pg_popcount_available())
	{
		pg_popcount32 = pg_popcount32_fast;
		pg_popcount64 = pg_popcount64_fast;
	}
	else
	{
		pg_popcount32 = pg_popcount32_slow;
		pg_popcount64 = pg_popcount64_slow;
	}

	return pg_popcount32(word);
}

static int
pg_popcount64_choose(uint64 word)
{
	if (pg_popcount_available())
	{
		pg_popcount32 = pg_popcount32_fast;
		pg_popcount64 = pg_popcount64_fast;
	}
	else
	{
		pg_popcount32 = pg_popcount32_slow;
		pg_popcount64 = pg_popcount64_slow;
	}

	return pg_popcount64(word);
}

/*
 * pg_popcount32_fast
 *		Return the number of 1 bits set in word
 */
static int
pg_popcount32_fast(uint32 word)
{
#ifdef _MSC_VER
	return __popcnt(word);
#else
	uint32		res;

__asm__ __volatile__(" popcntl %1,%0\n":"=q"(res):"rm"(word):"cc");
	return (int) res;
#endif
}

/*
 * pg_popcount64_fast
 *		Return the number of 1 bits set in word
 */
static int
pg_popcount64_fast(uint64 word)
{
#ifdef _MSC_VER
	return __popcnt64(word);
#else
	uint64		res;

__asm__ __volatile__(" popcntq %1,%0\n":"=q"(res):"rm"(word):"cc");
	return (int) res;
#endif
}

#endif							/* TRY_POPCNT_FAST */


/*
 * pg_popcount32_slow
 *		Return the number of 1 bits set in word
 */
#ifdef HAVE__BUILTIN_POPCOUNT
#else							/* !HAVE__BUILTIN_POPCOUNT */
#endif							/* HAVE__BUILTIN_POPCOUNT */

/*
 * pg_popcount64_slow
 *		Return the number of 1 bits set in word
 */
static int
pg_popcount64_slow(uint64 word)
{
#ifdef HAVE__BUILTIN_POPCOUNT
#if defined(HAVE_LONG_INT_64)
	return __builtin_popcountl(word);
#elif defined(HAVE_LONG_LONG_INT_64)
	return __builtin_popcountll(word);
#else
#error must have a working 64-bit integer datatype
#endif
#else							/* !HAVE__BUILTIN_POPCOUNT */
	int			result = 0;

	while (word != 0)
	{
		result += pg_number_of_ones[word & 255];
		word >>= 8;
	}

	return result;
#endif							/* HAVE__BUILTIN_POPCOUNT */
}

#ifndef TRY_POPCNT_FAST

/*
 * When the POPCNT instruction is not available, there's no point in using
 * function pointers to vary the implementation between the fast and slow
 * method.  We instead just make these actual external functions when
 * TRY_POPCNT_FAST is not defined.  The compiler should be able to inline
 * the slow versions here.
 */


int
pg_popcount64(uint64 word)
{
	return pg_popcount64_slow(word);
}

#endif							/* !TRY_POPCNT_FAST */

/*
 * pg_popcount
 *		Returns the number of 1-bits in buf
 */
#if SIZEOF_VOID_P >= 8
#else
#endif
