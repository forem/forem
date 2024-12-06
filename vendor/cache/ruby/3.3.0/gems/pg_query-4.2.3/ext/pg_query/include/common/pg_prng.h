/*-------------------------------------------------------------------------
 *
 * Pseudo-Random Number Generator
 *
 * Copyright (c) 2021-2022, PostgreSQL Global Development Group
 *
 * src/include/common/pg_prng.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_PRNG_H
#define PG_PRNG_H

/*
 * State vector for PRNG generation.  Callers should treat this as an
 * opaque typedef, but we expose its definition to allow it to be
 * embedded in other structs.
 */
typedef struct pg_prng_state
{
	uint64		s0,
				s1;
} pg_prng_state;

/*
 * Callers not needing local PRNG series may use this global state vector,
 * after initializing it with one of the pg_prng_...seed functions.
 */
extern PGDLLIMPORT __thread  pg_prng_state pg_global_prng_state;

extern void pg_prng_seed(pg_prng_state *state, uint64 seed);
extern void pg_prng_fseed(pg_prng_state *state, double fseed);
extern bool pg_prng_seed_check(pg_prng_state *state);

/*
 * Initialize the PRNG state from the pg_strong_random source,
 * taking care that we don't produce all-zeroes.  If this returns false,
 * caller should initialize the PRNG state from some other random seed,
 * using pg_prng_[f]seed.
 *
 * We implement this as a macro, so that the pg_strong_random() call is
 * in the caller.  If it were in pg_prng.c, programs using pg_prng.c
 * but not needing strong seeding would nonetheless be forced to pull in
 * pg_strong_random.c and thence OpenSSL.
 */
#define pg_prng_strong_seed(state) \
	(pg_strong_random((void *) (state), sizeof(pg_prng_state)) ? \
	 pg_prng_seed_check(state) : false)

extern uint64 pg_prng_uint64(pg_prng_state *state);
extern uint64 pg_prng_uint64_range(pg_prng_state *state, uint64 rmin, uint64 rmax);
extern int64 pg_prng_int64(pg_prng_state *state);
extern int64 pg_prng_int64p(pg_prng_state *state);
extern uint32 pg_prng_uint32(pg_prng_state *state);
extern int32 pg_prng_int32(pg_prng_state *state);
extern int32 pg_prng_int32p(pg_prng_state *state);
extern double pg_prng_double(pg_prng_state *state);
extern bool pg_prng_bool(pg_prng_state *state);

#endif							/* PG_PRNG_H */
