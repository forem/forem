/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - GetExtensibleNodeMethods
 * - GetExtensibleNodeEntry
 * - extensible_node_methods
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * extensible.c
 *	  Support for extensible node types
 *
 * Loadable modules can define what are in effect new types of nodes using
 * the routines in this file.  All such nodes are flagged T_ExtensibleNode,
 * with the extnodename field distinguishing the specific type.  Use
 * RegisterExtensibleNodeMethods to register a new type of extensible node,
 * and GetExtensibleNodeMethods to get information about a previously
 * registered type of extensible node.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/nodes/extensible.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "nodes/extensible.h"
#include "utils/hsearch.h"

static __thread HTAB *extensible_node_methods = NULL;



typedef struct
{
	char		extnodename[EXTNODENAME_MAX_LEN];
	const void *extnodemethods;
} ExtensibleNodeEntry;

/*
 * An internal function to register a new callback structure
 */


/*
 * Register a new type of extensible node.
 */


/*
 * Register a new type of custom scan node
 */


/*
 * An internal routine to get an ExtensibleNodeEntry by the given identifier
 */
static const void *
GetExtensibleNodeEntry(HTAB *htable, const char *extnodename, bool missing_ok)
{
	ExtensibleNodeEntry *entry = NULL;

	if (htable != NULL)
		entry = (ExtensibleNodeEntry *) hash_search(htable,
													extnodename,
													HASH_FIND, NULL);
	if (!entry)
	{
		if (missing_ok)
			return NULL;
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_OBJECT),
				 errmsg("ExtensibleNodeMethods \"%s\" was not registered",
						extnodename)));
	}

	return entry->extnodemethods;
}

/*
 * Get the methods for a given type of extensible node.
 */
const ExtensibleNodeMethods *
GetExtensibleNodeMethods(const char *extnodename, bool missing_ok)
{
	return (const ExtensibleNodeMethods *)
		GetExtensibleNodeEntry(extensible_node_methods,
							   extnodename,
							   missing_ok);
}

/*
 * Get the methods for a given name of CustomScanMethods
 */

