/*-------------------------------------------------------------------------
 *
 * pgtime.h
 *	  PostgreSQL internal timezone library
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/include/pgtime.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _PGTIME_H
#define _PGTIME_H


/*
 * The API of this library is generally similar to the corresponding
 * C library functions, except that we use pg_time_t which (we hope) is
 * 64 bits wide, and which is most definitely signed not unsigned.
 */

typedef int64 pg_time_t;

/*
 * Data structure representing a broken-down timestamp.
 *
 * CAUTION: the IANA timezone library (src/timezone/) follows the POSIX
 * convention that tm_mon counts from 0 and tm_year is relative to 1900.
 * However, Postgres' datetime functions generally treat tm_mon as counting
 * from 1 and tm_year as relative to 1 BC.  Be sure to make the appropriate
 * adjustments when moving from one code domain to the other.
 */
struct pg_tm
{
	int			tm_sec;
	int			tm_min;
	int			tm_hour;
	int			tm_mday;
	int			tm_mon;			/* see above */
	int			tm_year;		/* see above */
	int			tm_wday;
	int			tm_yday;
	int			tm_isdst;
	long int	tm_gmtoff;
	const char *tm_zone;
};

/* These structs are opaque outside the timezone library */
typedef struct pg_tz pg_tz;
typedef struct pg_tzenum pg_tzenum;

/* Maximum length of a timezone name (not including trailing null) */
#define TZ_STRLEN_MAX 255

/* these functions are in localtime.c */

extern struct pg_tm *pg_localtime(const pg_time_t *timep, const pg_tz *tz);
extern struct pg_tm *pg_gmtime(const pg_time_t *timep);
extern int	pg_next_dst_boundary(const pg_time_t *timep,
								 long int *before_gmtoff,
								 int *before_isdst,
								 pg_time_t *boundary,
								 long int *after_gmtoff,
								 int *after_isdst,
								 const pg_tz *tz);
extern bool pg_interpret_timezone_abbrev(const char *abbrev,
										 const pg_time_t *timep,
										 long int *gmtoff,
										 int *isdst,
										 const pg_tz *tz);
extern bool pg_get_timezone_offset(const pg_tz *tz, long int *gmtoff);
extern const char *pg_get_timezone_name(pg_tz *tz);
extern bool pg_tz_acceptable(pg_tz *tz);

/* these functions are in strftime.c */

extern size_t pg_strftime(char *s, size_t max, const char *format,
						  const struct pg_tm *tm);

/* these functions and variables are in pgtz.c */

extern PGDLLIMPORT pg_tz *session_timezone;
extern PGDLLIMPORT pg_tz *log_timezone;

extern void pg_timezone_initialize(void);
extern pg_tz *pg_tzset(const char *tzname);
extern pg_tz *pg_tzset_offset(long gmtoffset);

extern pg_tzenum *pg_tzenumerate_start(void);
extern pg_tz *pg_tzenumerate_next(pg_tzenum *dir);
extern void pg_tzenumerate_end(pg_tzenum *dir);

#endif							/* _PGTIME_H */
