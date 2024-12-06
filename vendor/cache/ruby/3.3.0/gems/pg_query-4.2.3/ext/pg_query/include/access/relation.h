/*-------------------------------------------------------------------------
 *
 * relation.h
 *	  Generic relation related routines.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/access/relation.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef ACCESS_RELATION_H
#define ACCESS_RELATION_H

#include "nodes/primnodes.h"
#include "storage/lockdefs.h"
#include "utils/relcache.h"

extern Relation relation_open(Oid relationId, LOCKMODE lockmode);
extern Relation try_relation_open(Oid relationId, LOCKMODE lockmode);
extern Relation relation_openrv(const RangeVar *relation, LOCKMODE lockmode);
extern Relation relation_openrv_extended(const RangeVar *relation,
										 LOCKMODE lockmode, bool missing_ok);
extern void relation_close(Relation relation, LOCKMODE lockmode);

#endif							/* ACCESS_RELATION_H */
