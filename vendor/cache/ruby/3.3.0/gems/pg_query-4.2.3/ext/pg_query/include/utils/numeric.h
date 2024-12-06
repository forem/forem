/*-------------------------------------------------------------------------
 *
 * numeric.h
 *	  Definitions for the exact numeric data type of Postgres
 *
 * Original coding 1998, Jan Wieck.  Heavily revised 2003, Tom Lane.
 *
 * Copyright (c) 1998-2022, PostgreSQL Global Development Group
 *
 * src/include/utils/numeric.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _PG_NUMERIC_H_
#define _PG_NUMERIC_H_

#include "fmgr.h"

/*
 * Limits on the precision and scale specifiable in a NUMERIC typmod.  The
 * precision is strictly positive, but the scale may be positive or negative.
 * A negative scale implies rounding before the decimal point.
 *
 * Note that the minimum display scale defined below is zero --- we always
 * display all digits before the decimal point, even when the scale is
 * negative.
 *
 * Note that the implementation limits on the precision and display scale of a
 * numeric value are much larger --- beware of what you use these for!
 */
#define NUMERIC_MAX_PRECISION		1000

#define NUMERIC_MIN_SCALE			(-1000)
#define NUMERIC_MAX_SCALE			1000

/*
 * Internal limits on the scales chosen for calculation results
 */
#define NUMERIC_MAX_DISPLAY_SCALE	NUMERIC_MAX_PRECISION
#define NUMERIC_MIN_DISPLAY_SCALE	0

#define NUMERIC_MAX_RESULT_SCALE	(NUMERIC_MAX_PRECISION * 2)

/*
 * For inherently inexact calculations such as division and square root,
 * we try to get at least this many significant digits; the idea is to
 * deliver a result no worse than float8 would.
 */
#define NUMERIC_MIN_SIG_DIGITS		16

/* The actual contents of Numeric are private to numeric.c */
struct NumericData;
typedef struct NumericData *Numeric;

/*
 * fmgr interface macros
 */

#define DatumGetNumeric(X)		  ((Numeric) PG_DETOAST_DATUM(X))
#define DatumGetNumericCopy(X)	  ((Numeric) PG_DETOAST_DATUM_COPY(X))
#define NumericGetDatum(X)		  PointerGetDatum(X)
#define PG_GETARG_NUMERIC(n)	  DatumGetNumeric(PG_GETARG_DATUM(n))
#define PG_GETARG_NUMERIC_COPY(n) DatumGetNumericCopy(PG_GETARG_DATUM(n))
#define PG_RETURN_NUMERIC(x)	  return NumericGetDatum(x)

/*
 * Utility functions in numeric.c
 */
extern bool numeric_is_nan(Numeric num);
extern bool numeric_is_inf(Numeric num);
extern int32 numeric_maximum_size(int32 typmod);
extern char *numeric_out_sci(Numeric num, int scale);
extern char *numeric_normalize(Numeric num);

extern Numeric int64_to_numeric(int64 val);
extern Numeric int64_div_fast_to_numeric(int64 val1, int log10val2);

extern Numeric numeric_add_opt_error(Numeric num1, Numeric num2,
									 bool *have_error);
extern Numeric numeric_sub_opt_error(Numeric num1, Numeric num2,
									 bool *have_error);
extern Numeric numeric_mul_opt_error(Numeric num1, Numeric num2,
									 bool *have_error);
extern Numeric numeric_div_opt_error(Numeric num1, Numeric num2,
									 bool *have_error);
extern Numeric numeric_mod_opt_error(Numeric num1, Numeric num2,
									 bool *have_error);
extern int32 numeric_int4_opt_error(Numeric num, bool *error);

#endif							/* _PG_NUMERIC_H_ */
