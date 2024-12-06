/*-------------------------------------------------------------------------
 *
 * pg_parameter_acl.h
 *	  definition of the "configuration parameter ACL" system catalog
 *	  (pg_parameter_acl).
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_parameter_acl.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_PARAMETER_ACL_H
#define PG_PARAMETER_ACL_H

#include "catalog/genbki.h"
#include "catalog/pg_parameter_acl_d.h"

/* ----------------
 *		pg_parameter_acl definition.  cpp turns this into
 *		typedef struct FormData_pg_parameter_acl
 * ----------------
 */
CATALOG(pg_parameter_acl,6243,ParameterAclRelationId) BKI_SHARED_RELATION
{
	Oid			oid;			/* oid */

#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	/* name of parameter */
	text		parname BKI_FORCE_NOT_NULL;

	/* access permissions */
	aclitem		paracl[1] BKI_DEFAULT(_null_);
#endif
} FormData_pg_parameter_acl;


/* ----------------
 *		Form_pg_parameter_acl corresponds to a pointer to a tuple with
 *		the format of pg_parameter_acl relation.
 * ----------------
 */
typedef FormData_pg_parameter_acl * Form_pg_parameter_acl;

DECLARE_TOAST_WITH_MACRO(pg_parameter_acl, 6244, 6245, PgParameterAclToastTable, PgParameterAclToastIndex);

DECLARE_UNIQUE_INDEX(pg_parameter_acl_parname_index, 6246, ParameterAclParnameIndexId, on pg_parameter_acl using btree(parname text_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_parameter_acl_oid_index, 6247, ParameterAclOidIndexId, on pg_parameter_acl using btree(oid oid_ops));


extern Oid	ParameterAclLookup(const char *parameter, bool missing_ok);
extern Oid	ParameterAclCreate(const char *parameter);

#endif							/* PG_PARAMETER_ACL_H */
