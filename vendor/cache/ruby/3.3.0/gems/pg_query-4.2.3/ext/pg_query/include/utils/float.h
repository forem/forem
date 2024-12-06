/*-------------------------------------------------------------------------
 *
 * float.h
 *	  Definitions for the built-in floating-point types
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/include/utils/float.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef FLOAT_H
#define FLOAT_H

#include <math.h>

#ifndef M_PI
/* From my RH5.2 gcc math.h file - thomas 2000-04-03 */
#define M_PI 3.14159265358979323846
#endif

/* Radians per degree, a.k.a. PI / 180 */
#define RADIANS_PER_DEGREE 0.0174532925199432957692

/* Visual C++ etc lacks NAN, and won't accept 0.0/0.0. */
#if defined(WIN32) && !defined(NAN)
static const uint32 nan[2] = {0xffffffff, 0x7fffffff};

#define NAN (*(const float8 *) nan)
#endif

extern PGDLLIMPORT int extra_float_digits;

/*
 * Utility functions in float.c
 */
extern void float_overflow_error(void) pg_attribute_noreturn();
extern void float_underflow_error(void) pg_attribute_noreturn();
extern void float_zero_divide_error(void) pg_attribute_noreturn();
extern int	is_infinite(float8 val);
extern float8 float8in_internal(char *num, char **endptr_p,
								const char *type_name, const char *orig_string);
extern float8 float8in_internal_opt_error(char *num, char **endptr_p,
										  const char *type_name, const char *orig_string,
										  bool *have_error);
extern char *float8out_internal(float8 num);
extern int	float4_cmp_internal(float4 a, float4 b);
extern int	float8_cmp_internal(float8 a, float8 b);

/*
 * Routines to provide reasonably platform-independent handling of
 * infinity and NaN
 *
 * We assume that isinf() and isnan() are available and work per spec.
 * (On some platforms, we have to supply our own; see src/port.)  However,
 * generating an Infinity or NaN in the first place is less well standardized;
 * pre-C99 systems tend not to have C99's INFINITY and NaN macros.  We
 * centralize our workarounds for this here.
 */

/*
 * The funny placements of the two #pragmas is necessary because of a
 * long lived bug in the Microsoft compilers.
 * See http://support.microsoft.com/kb/120968/en-us for details
 */
#ifdef _MSC_VER
#pragma warning(disable:4756)
#endif
static inline float4
get_float4_infinity(void)
{
#ifdef INFINITY
	/* C99 standard way */
	return (float4) INFINITY;
#else
#ifdef _MSC_VER
#pragma warning(default:4756)
#endif

	/*
	 * On some platforms, HUGE_VAL is an infinity, elsewhere it's just the
	 * largest normal float8.  We assume forcing an overflow will get us a
	 * true infinity.
	 */
	return (float4) (HUGE_VAL * HUGE_VAL);
#endif
}

static inline float8
get_float8_infinity(void)
{
#ifdef INFINITY
	/* C99 standard way */
	return (float8) INFINITY;
#else

	/*
	 * On some platforms, HUGE_VAL is an infinity, elsewhere it's just the
	 * largest normal float8.  We assume forcing an overflow will get us a
	 * true infinity.
	 */
	return (float8) (HUGE_VAL * HUGE_VAL);
#endif
}

static inline float4
get_float4_nan(void)
{
#ifdef NAN
	/* C99 standard way */
	return (float4) NAN;
#else
	/* Assume we can get a NAN via zero divide */
	return (float4) (0.0 / 0.0);
#endif
}

static inline float8
get_float8_nan(void)
{
	/* (float8) NAN doesn't work on some NetBSD/MIPS releases */
#if defined(NAN) && !(defined(__NetBSD__) && defined(__mips__))
	/* C99 standard way */
	return (float8) NAN;
#else
	/* Assume we can get a NaN via zero divide */
	return (float8) (0.0 / 0.0);
#endif
}

/*
 * Floating-point arithmetic with overflow/underflow reported as errors
 *
 * There isn't any way to check for underflow of addition/subtraction
 * because numbers near the underflow value have already been rounded to
 * the point where we can't detect that the two values were originally
 * different, e.g. on x86, '1e-45'::float4 == '2e-45'::float4 ==
 * 1.4013e-45.
 */

static inline float4
float4_pl(const float4 val1, const float4 val2)
{
	float4		result;

	result = val1 + val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();

	return result;
}

static inline float8
float8_pl(const float8 val1, const float8 val2)
{
	float8		result;

	result = val1 + val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();

	return result;
}

static inline float4
float4_mi(const float4 val1, const float4 val2)
{
	float4		result;

	result = val1 - val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();

	return result;
}

static inline float8
float8_mi(const float8 val1, const float8 val2)
{
	float8		result;

	result = val1 - val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();

	return result;
}

static inline float4
float4_mul(const float4 val1, const float4 val2)
{
	float4		result;

	result = val1 * val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();
	if (unlikely(result == 0.0f) && val1 != 0.0f && val2 != 0.0f)
		float_underflow_error();

	return result;
}

static inline float8
float8_mul(const float8 val1, const float8 val2)
{
	float8		result;

	result = val1 * val2;
	if (unlikely(isinf(result)) && !isinf(val1) && !isinf(val2))
		float_overflow_error();
	if (unlikely(result == 0.0) && val1 != 0.0 && val2 != 0.0)
		float_underflow_error();

	return result;
}

static inline float4
float4_div(const float4 val1, const float4 val2)
{
	float4		result;

	if (unlikely(val2 == 0.0f) && !isnan(val1))
		float_zero_divide_error();
	result = val1 / val2;
	if (unlikely(isinf(result)) && !isinf(val1))
		float_overflow_error();
	if (unlikely(result == 0.0f) && val1 != 0.0f && !isinf(val2))
		float_underflow_error();

	return result;
}

static inline float8
float8_div(const float8 val1, const float8 val2)
{
	float8		result;

	if (unlikely(val2 == 0.0) && !isnan(val1))
		float_zero_divide_error();
	result = val1 / val2;
	if (unlikely(isinf(result)) && !isinf(val1))
		float_overflow_error();
	if (unlikely(result == 0.0) && val1 != 0.0 && !isinf(val2))
		float_underflow_error();

	return result;
}

/*
 * Routines for NaN-aware comparisons
 *
 * We consider all NaNs to be equal and larger than any non-NaN. This is
 * somewhat arbitrary; the important thing is to have a consistent sort
 * order.
 */

static inline bool
float4_eq(const float4 val1, const float4 val2)
{
	return isnan(val1) ? isnan(val2) : !isnan(val2) && val1 == val2;
}

static inline bool
float8_eq(const float8 val1, const float8 val2)
{
	return isnan(val1) ? isnan(val2) : !isnan(val2) && val1 == val2;
}

static inline bool
float4_ne(const float4 val1, const float4 val2)
{
	return isnan(val1) ? !isnan(val2) : isnan(val2) || val1 != val2;
}

static inline bool
float8_ne(const float8 val1, const float8 val2)
{
	return isnan(val1) ? !isnan(val2) : isnan(val2) || val1 != val2;
}

static inline bool
float4_lt(const float4 val1, const float4 val2)
{
	return !isnan(val1) && (isnan(val2) || val1 < val2);
}

static inline bool
float8_lt(const float8 val1, const float8 val2)
{
	return !isnan(val1) && (isnan(val2) || val1 < val2);
}

static inline bool
float4_le(const float4 val1, const float4 val2)
{
	return isnan(val2) || (!isnan(val1) && val1 <= val2);
}

static inline bool
float8_le(const float8 val1, const float8 val2)
{
	return isnan(val2) || (!isnan(val1) && val1 <= val2);
}

static inline bool
float4_gt(const float4 val1, const float4 val2)
{
	return !isnan(val2) && (isnan(val1) || val1 > val2);
}

static inline bool
float8_gt(const float8 val1, const float8 val2)
{
	return !isnan(val2) && (isnan(val1) || val1 > val2);
}

static inline bool
float4_ge(const float4 val1, const float4 val2)
{
	return isnan(val1) || (!isnan(val2) && val1 >= val2);
}

static inline bool
float8_ge(const float8 val1, const float8 val2)
{
	return isnan(val1) || (!isnan(val2) && val1 >= val2);
}

static inline float4
float4_min(const float4 val1, const float4 val2)
{
	return float4_lt(val1, val2) ? val1 : val2;
}

static inline float8
float8_min(const float8 val1, const float8 val2)
{
	return float8_lt(val1, val2) ? val1 : val2;
}

static inline float4
float4_max(const float4 val1, const float4 val2)
{
	return float4_gt(val1, val2) ? val1 : val2;
}

static inline float8
float8_max(const float8 val1, const float8 val2)
{
	return float8_gt(val1, val2) ? val1 : val2;
}

#endif							/* FLOAT_H */
