/*-------------------------------------------------------------------------
 *
 * datum.h
 *	  POSTGRES Datum (abstract data type) manipulation routines.
 *
 * These routines are driven by the 'typbyval' and 'typlen' information,
 * which must previously have been obtained by the caller for the datatype
 * of the Datum.  (We do it this way because in most situations the caller
 * can look up the info just once and use it for many per-datum operations.)
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/datum.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef DATUM_H
#define DATUM_H

/*
 * datumGetSize - find the "real" length of a datum
 */
extern Size datumGetSize(Datum value, bool typByVal, int typLen);

/*
 * datumCopy - make a copy of a non-NULL datum.
 *
 * If the datatype is pass-by-reference, memory is obtained with palloc().
 */
extern Datum datumCopy(Datum value, bool typByVal, int typLen);

/*
 * datumTransfer - transfer a non-NULL datum into the current memory context.
 *
 * Differs from datumCopy() in its handling of read-write expanded objects.
 */
extern Datum datumTransfer(Datum value, bool typByVal, int typLen);

/*
 * datumIsEqual
 * return true if two datums of the same type are equal, false otherwise.
 *
 * XXX : See comments in the code for restrictions!
 */
extern bool datumIsEqual(Datum value1, Datum value2,
						 bool typByVal, int typLen);

/*
 * datum_image_eq
 *
 * Compares two datums for identical contents, based on byte images.  Return
 * true if the two datums are equal, false otherwise.
 */
extern bool datum_image_eq(Datum value1, Datum value2,
						   bool typByVal, int typLen);

/*
 * datum_image_hash
 *
 * Generates hash value for 'value' based on its bits rather than logical
 * value.
 */
extern uint32 datum_image_hash(Datum value, bool typByVal, int typLen);

/*
 * Serialize and restore datums so that we can transfer them to parallel
 * workers.
 */
extern Size datumEstimateSpace(Datum value, bool isnull, bool typByVal,
							   int typLen);
extern void datumSerialize(Datum value, bool isnull, bool typByVal,
						   int typLen, char **start_address);
extern Datum datumRestore(char **start_address, bool *isnull);

#endif							/* DATUM_H */
