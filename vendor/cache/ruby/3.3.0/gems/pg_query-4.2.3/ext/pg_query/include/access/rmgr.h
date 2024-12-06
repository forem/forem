/*
 * rmgr.h
 *
 * Resource managers definition
 *
 * src/include/access/rmgr.h
 */
#ifndef RMGR_H
#define RMGR_H

typedef uint8 RmgrId;

/*
 * Built-in resource managers
 *
 * The actual numerical values for each rmgr ID are defined by the order
 * of entries in rmgrlist.h.
 *
 * Note: RM_MAX_ID must fit in RmgrId; widening that type will affect the XLOG
 * file format.
 */
#define PG_RMGR(symname,name,redo,desc,identify,startup,cleanup,mask,decode) \
	symname,

typedef enum RmgrIds
{
#include "access/rmgrlist.h"
	RM_NEXT_ID
}			RmgrIds;

#undef PG_RMGR

#define RM_MAX_ID			UINT8_MAX
#define RM_MAX_BUILTIN_ID	(RM_NEXT_ID - 1)
#define RM_MIN_CUSTOM_ID	128
#define RM_MAX_CUSTOM_ID	UINT8_MAX
#define RM_N_IDS			(UINT8_MAX + 1)
#define RM_N_BUILTIN_IDS	(RM_MAX_BUILTIN_ID + 1)
#define RM_N_CUSTOM_IDS		(RM_MAX_CUSTOM_ID - RM_MIN_CUSTOM_ID + 1)

static inline bool
RmgrIdIsBuiltin(int rmid)
{
	return rmid <= RM_MAX_BUILTIN_ID;
}

static inline bool
RmgrIdIsCustom(int rmid)
{
	return rmid >= RM_MIN_CUSTOM_ID && rmid <= RM_MAX_CUSTOM_ID;
}

#define RmgrIdIsValid(rmid) (RmgrIdIsBuiltin((rmid)) || RmgrIdIsCustom((rmid)))

/*
 * RmgrId to use for extensions that require an RmgrId, but are still in
 * development and have not reserved their own unique RmgrId yet. See:
 * https://wiki.postgresql.org/wiki/CustomWALResourceManagers
 */
#define RM_EXPERIMENTAL_ID		128

#endif							/* RMGR_H */
