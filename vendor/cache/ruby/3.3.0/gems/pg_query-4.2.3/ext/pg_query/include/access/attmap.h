/*-------------------------------------------------------------------------
 *
 * attmap.h
 *	  Definitions for PostgreSQL attribute mappings
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/access/attmap.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef ATTMAP_H
#define ATTMAP_H

#include "access/attnum.h"
#include "access/tupdesc.h"

/*
 * Attribute mapping structure
 *
 * This maps attribute numbers between a pair of relations, designated
 * 'input' and 'output' (most typically inheritance parent and child
 * relations), whose common columns may have different attribute numbers.
 * Such difference may arise due to the columns being ordered differently
 * in the two relations or the two relations having dropped columns at
 * different positions.
 *
 * 'maplen' is set to the number of attributes of the 'output' relation,
 * taking into account any of its dropped attributes, with the corresponding
 * elements of the 'attnums' array set to 0.
 */
typedef struct AttrMap
{
	AttrNumber *attnums;
	int			maplen;
} AttrMap;

extern AttrMap *make_attrmap(int maplen);
extern void free_attrmap(AttrMap *map);

/* Conversion routines to build mappings */
extern AttrMap *build_attrmap_by_name(TupleDesc indesc,
									  TupleDesc outdesc);
extern AttrMap *build_attrmap_by_name_if_req(TupleDesc indesc,
											 TupleDesc outdesc);
extern AttrMap *build_attrmap_by_position(TupleDesc indesc,
										  TupleDesc outdesc,
										  const char *msg);

#endif							/* ATTMAP_H */
