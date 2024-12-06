/*-------------------------------------------------------------------------
 *
 * pg_statistic.h
 *	  definition of the "statistics" system catalog (pg_statistic)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_statistic.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_STATISTIC_H
#define PG_STATISTIC_H

#include "catalog/genbki.h"
#include "catalog/pg_statistic_d.h"

/* ----------------
 *		pg_statistic definition.  cpp turns this into
 *		typedef struct FormData_pg_statistic
 * ----------------
 */
CATALOG(pg_statistic,2619,StatisticRelationId)
{
	/* These fields form the unique key for the entry: */
	Oid			starelid BKI_LOOKUP(pg_class);	/* relation containing
												 * attribute */
	int16		staattnum;		/* attribute (column) stats are for */
	bool		stainherit;		/* true if inheritance children are included */

	/* the fraction of the column's entries that are NULL: */
	float4		stanullfrac;

	/*
	 * stawidth is the average width in bytes of non-null entries.  For
	 * fixed-width datatypes this is of course the same as the typlen, but for
	 * var-width types it is more useful.  Note that this is the average width
	 * of the data as actually stored, post-TOASTing (eg, for a
	 * moved-out-of-line value, only the size of the pointer object is
	 * counted).  This is the appropriate definition for the primary use of
	 * the statistic, which is to estimate sizes of in-memory hash tables of
	 * tuples.
	 */
	int32		stawidth;

	/* ----------------
	 * stadistinct indicates the (approximate) number of distinct non-null
	 * data values in the column.  The interpretation is:
	 *		0		unknown or not computed
	 *		> 0		actual number of distinct values
	 *		< 0		negative of multiplier for number of rows
	 * The special negative case allows us to cope with columns that are
	 * unique (stadistinct = -1) or nearly so (for example, a column in which
	 * non-null values appear about twice on the average could be represented
	 * by stadistinct = -0.5 if there are no nulls, or -0.4 if 20% of the
	 * column is nulls).  Because the number-of-rows statistic in pg_class may
	 * be updated more frequently than pg_statistic is, it's important to be
	 * able to describe such situations as a multiple of the number of rows,
	 * rather than a fixed number of distinct values.  But in other cases a
	 * fixed number is correct (eg, a boolean column).
	 * ----------------
	 */
	float4		stadistinct;

	/* ----------------
	 * To allow keeping statistics on different kinds of datatypes,
	 * we do not hard-wire any particular meaning for the remaining
	 * statistical fields.  Instead, we provide several "slots" in which
	 * statistical data can be placed.  Each slot includes:
	 *		kind			integer code identifying kind of data (see below)
	 *		op				OID of associated operator, if needed
	 *		coll			OID of relevant collation, or 0 if none
	 *		numbers			float4 array (for statistical values)
	 *		values			anyarray (for representations of data values)
	 * The ID, operator, and collation fields are never NULL; they are zeroes
	 * in an unused slot.  The numbers and values fields are NULL in an
	 * unused slot, and might also be NULL in a used slot if the slot kind
	 * has no need for one or the other.
	 * ----------------
	 */

	int16		stakind1;
	int16		stakind2;
	int16		stakind3;
	int16		stakind4;
	int16		stakind5;

	Oid			staop1 BKI_LOOKUP_OPT(pg_operator);
	Oid			staop2 BKI_LOOKUP_OPT(pg_operator);
	Oid			staop3 BKI_LOOKUP_OPT(pg_operator);
	Oid			staop4 BKI_LOOKUP_OPT(pg_operator);
	Oid			staop5 BKI_LOOKUP_OPT(pg_operator);

	Oid			stacoll1 BKI_LOOKUP_OPT(pg_collation);
	Oid			stacoll2 BKI_LOOKUP_OPT(pg_collation);
	Oid			stacoll3 BKI_LOOKUP_OPT(pg_collation);
	Oid			stacoll4 BKI_LOOKUP_OPT(pg_collation);
	Oid			stacoll5 BKI_LOOKUP_OPT(pg_collation);

#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	float4		stanumbers1[1];
	float4		stanumbers2[1];
	float4		stanumbers3[1];
	float4		stanumbers4[1];
	float4		stanumbers5[1];

	/*
	 * Values in these arrays are values of the column's data type, or of some
	 * related type such as an array element type.  We presently have to cheat
	 * quite a bit to allow polymorphic arrays of this kind, but perhaps
	 * someday it'll be a less bogus facility.
	 */
	anyarray	stavalues1;
	anyarray	stavalues2;
	anyarray	stavalues3;
	anyarray	stavalues4;
	anyarray	stavalues5;
#endif
} FormData_pg_statistic;

#define STATISTIC_NUM_SLOTS  5


/* ----------------
 *		Form_pg_statistic corresponds to a pointer to a tuple with
 *		the format of pg_statistic relation.
 * ----------------
 */
typedef FormData_pg_statistic *Form_pg_statistic;

DECLARE_TOAST(pg_statistic, 2840, 2841);

DECLARE_UNIQUE_INDEX_PKEY(pg_statistic_relid_att_inh_index, 2696, StatisticRelidAttnumInhIndexId, on pg_statistic using btree(starelid oid_ops, staattnum int2_ops, stainherit bool_ops));

DECLARE_FOREIGN_KEY((starelid, staattnum), pg_attribute, (attrelid, attnum));

#ifdef EXPOSE_TO_CLIENT_CODE

/*
 * Several statistical slot "kinds" are defined by core PostgreSQL, as
 * documented below.  Also, custom data types can define their own "kind"
 * codes by mutual agreement between a custom typanalyze routine and the
 * selectivity estimation functions of the type's operators.
 *
 * Code reading the pg_statistic relation should not assume that a particular
 * data "kind" will appear in any particular slot.  Instead, search the
 * stakind fields to see if the desired data is available.  (The standard
 * function get_attstatsslot() may be used for this.)
 */

/*
 * The present allocation of "kind" codes is:
 *
 *	1-99:		reserved for assignment by the core PostgreSQL project
 *				(values in this range will be documented in this file)
 *	100-199:	reserved for assignment by the PostGIS project
 *				(values to be documented in PostGIS documentation)
 *	200-299:	reserved for assignment by the ESRI ST_Geometry project
 *				(values to be documented in ESRI ST_Geometry documentation)
 *	300-9999:	reserved for future public assignments
 *
 * For private use you may choose a "kind" code at random in the range
 * 10000-30000.  However, for code that is to be widely disseminated it is
 * better to obtain a publicly defined "kind" code by request from the
 * PostgreSQL Global Development Group.
 */

/*
 * In a "most common values" slot, staop is the OID of the "=" operator
 * used to decide whether values are the same or not, and stacoll is the
 * collation used (same as column's collation).  stavalues contains
 * the K most common non-null values appearing in the column, and stanumbers
 * contains their frequencies (fractions of total row count).  The values
 * shall be ordered in decreasing frequency.  Note that since the arrays are
 * variable-size, K may be chosen by the statistics collector.  Values should
 * not appear in MCV unless they have been observed to occur more than once;
 * a unique column will have no MCV slot.
 */
#define STATISTIC_KIND_MCV	1

/*
 * A "histogram" slot describes the distribution of scalar data.  staop is
 * the OID of the "<" operator that describes the sort ordering, and stacoll
 * is the relevant collation.  (In theory more than one histogram could appear,
 * if a datatype has more than one useful sort operator or we care about more
 * than one collation.  Currently the collation will always be that of the
 * underlying column.)  stavalues contains M (>=2) non-null values that
 * divide the non-null column data values into M-1 bins of approximately equal
 * population.  The first stavalues item is the MIN and the last is the MAX.
 * stanumbers is not used and should be NULL.  IMPORTANT POINT: if an MCV
 * slot is also provided, then the histogram describes the data distribution
 * *after removing the values listed in MCV* (thus, it's a "compressed
 * histogram" in the technical parlance).  This allows a more accurate
 * representation of the distribution of a column with some very-common
 * values.  In a column with only a few distinct values, it's possible that
 * the MCV list describes the entire data population; in this case the
 * histogram reduces to empty and should be omitted.
 */
#define STATISTIC_KIND_HISTOGRAM  2

/*
 * A "correlation" slot describes the correlation between the physical order
 * of table tuples and the ordering of data values of this column, as seen
 * by the "<" operator identified by staop with the collation identified by
 * stacoll.  (As with the histogram, more than one entry could theoretically
 * appear.)  stavalues is not used and should be NULL.  stanumbers contains
 * a single entry, the correlation coefficient between the sequence of data
 * values and the sequence of their actual tuple positions.  The coefficient
 * ranges from +1 to -1.
 */
#define STATISTIC_KIND_CORRELATION	3

/*
 * A "most common elements" slot is similar to a "most common values" slot,
 * except that it stores the most common non-null *elements* of the column
 * values.  This is useful when the column datatype is an array or some other
 * type with identifiable elements (for instance, tsvector).  staop contains
 * the equality operator appropriate to the element type, and stacoll
 * contains the collation to use with it.  stavalues contains
 * the most common element values, and stanumbers their frequencies.  Unlike
 * MCV slots, frequencies are measured as the fraction of non-null rows the
 * element value appears in, not the frequency of all rows.  Also unlike
 * MCV slots, the values are sorted into the element type's default order
 * (to support binary search for a particular value).  Since this puts the
 * minimum and maximum frequencies at unpredictable spots in stanumbers,
 * there are two extra members of stanumbers, holding copies of the minimum
 * and maximum frequencies.  Optionally, there can be a third extra member,
 * which holds the frequency of null elements (expressed in the same terms:
 * the fraction of non-null rows that contain at least one null element).  If
 * this member is omitted, the column is presumed to contain no null elements.
 *
 * Note: in current usage for tsvector columns, the stavalues elements are of
 * type text, even though their representation within tsvector is not
 * exactly text.
 */
#define STATISTIC_KIND_MCELEM  4

/*
 * A "distinct elements count histogram" slot describes the distribution of
 * the number of distinct element values present in each row of an array-type
 * column.  Only non-null rows are considered, and only non-null elements.
 * staop contains the equality operator appropriate to the element type,
 * and stacoll contains the collation to use with it.
 * stavalues is not used and should be NULL.  The last member of stanumbers is
 * the average count of distinct element values over all non-null rows.  The
 * preceding M (>=2) members form a histogram that divides the population of
 * distinct-elements counts into M-1 bins of approximately equal population.
 * The first of these is the minimum observed count, and the last the maximum.
 */
#define STATISTIC_KIND_DECHIST	5

/*
 * A "length histogram" slot describes the distribution of range lengths in
 * rows of a range-type column. stanumbers contains a single entry, the
 * fraction of empty ranges. stavalues is a histogram of non-empty lengths, in
 * a format similar to STATISTIC_KIND_HISTOGRAM: it contains M (>=2) range
 * values that divide the column data values into M-1 bins of approximately
 * equal population. The lengths are stored as float8s, as measured by the
 * range type's subdiff function. Only non-null rows are considered.
 */
#define STATISTIC_KIND_RANGE_LENGTH_HISTOGRAM  6

/*
 * A "bounds histogram" slot is similar to STATISTIC_KIND_HISTOGRAM, but for
 * a range-type column.  stavalues contains M (>=2) range values that divide
 * the column data values into M-1 bins of approximately equal population.
 * Unlike a regular scalar histogram, this is actually two histograms combined
 * into a single array, with the lower bounds of each value forming a
 * histogram of lower bounds, and the upper bounds a histogram of upper
 * bounds.  Only non-NULL, non-empty ranges are included.
 */
#define STATISTIC_KIND_BOUNDS_HISTOGRAM  7

#endif							/* EXPOSE_TO_CLIENT_CODE */

#endif							/* PG_STATISTIC_H */
