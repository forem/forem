/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_prng_double
 * - xoroshiro128ss
 * - rotl
 * - pg_global_prng_state
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * Pseudo-Random Number Generator
 *
 * We use Blackman and Vigna's xoroshiro128** 1.0 algorithm
 * to have a small, fast PRNG suitable for generating reasonably
 * good-quality 64-bit data.  This should not be considered
 * cryptographically strong, however.
 *
 * About these generators: https://prng.di.unimi.it/
 * See also https://en.wikipedia.org/wiki/List_of_random_number_generators
 *
 * Copyright (c) 2021-2022, PostgreSQL Global Development Group
 *
 * src/common/pg_prng.c
 *
 *-------------------------------------------------------------------------
 */

#include "c.h"

#include <math.h>				/* for ldexp() */

#include "common/pg_prng.h"
#include "port/pg_bitutils.h"

/* process-wide state vector */
__thread pg_prng_state pg_global_prng_state;



/*
 * 64-bit rotate left
 */
static inline uint64
rotl(uint64 x, int bits)
{
	return (x << bits) | (x >> (64 - bits));
}

/*
 * The basic xoroshiro128** algorithm.
 * Generates and returns a 64-bit uniformly distributed number,
 * updating the state vector for next time.
 *
 * Note: the state vector must not be all-zeroes, as that is a fixed point.
 */
static uint64
xoroshiro128ss(pg_prng_state *state)
{
	uint64		s0 = state->s0,
				sx = state->s1 ^ s0,
				val = rotl(s0 * 5, 7) * 9;

	/* update state */
	state->s0 = rotl(s0, 24) ^ sx ^ (sx << 16);
	state->s1 = rotl(sx, 37);

	return val;
}

/*
 * We use this generator just to fill the xoroshiro128** state vector
 * from a 64-bit seed.
 */


/*
 * Initialize the PRNG state from a 64-bit integer,
 * taking care that we don't produce all-zeroes.
 */


/*
 * Initialize the PRNG state from a double in the range [-1.0, 1.0],
 * taking care that we don't produce all-zeroes.
 */


/*
 * Validate a PRNG seed value.
 */


/*
 * Select a random uint64 uniformly from the range [0, PG_UINT64_MAX].
 */


/*
 * Select a random uint64 uniformly from the range [rmin, rmax].
 * If the range is empty, rmin is always produced.
 */


/*
 * Select a random int64 uniformly from the range [PG_INT64_MIN, PG_INT64_MAX].
 */


/*
 * Select a random int64 uniformly from the range [0, PG_INT64_MAX].
 */


/*
 * Select a random uint32 uniformly from the range [0, PG_UINT32_MAX].
 */


/*
 * Select a random int32 uniformly from the range [PG_INT32_MIN, PG_INT32_MAX].
 */


/*
 * Select a random int32 uniformly from the range [0, PG_INT32_MAX].
 */


/*
 * Select a random double uniformly from the range [0.0, 1.0).
 *
 * Note: if you want a result in the range (0.0, 1.0], the standard way
 * to get that is "1.0 - pg_prng_double(state)".
 */
double
pg_prng_double(pg_prng_state *state)
{
	uint64		v = xoroshiro128ss(state);

	/*
	 * As above, assume there's 52 mantissa bits in a double.  This result
	 * could round to 1.0 if double's precision is less than that; but we
	 * assume IEEE float arithmetic elsewhere in Postgres, so this seems OK.
	 */
	return ldexp((double) (v >> (64 - 52)), -52);
}

/*
 * Select a random boolean value.
 */

