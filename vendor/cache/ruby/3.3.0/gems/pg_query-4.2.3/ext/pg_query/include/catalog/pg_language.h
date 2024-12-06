/*-------------------------------------------------------------------------
 *
 * pg_language.h
 *	  definition of the "language" system catalog (pg_language)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_language.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_LANGUAGE_H
#define PG_LANGUAGE_H

#include "catalog/genbki.h"
#include "catalog/pg_language_d.h"

/* ----------------
 *		pg_language definition.  cpp turns this into
 *		typedef struct FormData_pg_language
 * ----------------
 */
CATALOG(pg_language,2612,LanguageRelationId)
{
	Oid			oid;			/* oid */

	/* Language name */
	NameData	lanname;

	/* Language's owner */
	Oid			lanowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* Is a procedural language */
	bool		lanispl BKI_DEFAULT(f);

	/* PL is trusted */
	bool		lanpltrusted BKI_DEFAULT(f);

	/* Call handler, if it's a PL */
	Oid			lanplcallfoid BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_proc);

	/* Optional anonymous-block handler function */
	Oid			laninline BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_proc);

	/* Optional validation function */
	Oid			lanvalidator BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_proc);

#ifdef CATALOG_VARLEN			/* variable-length fields start here */
	/* Access privileges */
	aclitem		lanacl[1] BKI_DEFAULT(_null_);
#endif
} FormData_pg_language;

/* ----------------
 *		Form_pg_language corresponds to a pointer to a tuple with
 *		the format of pg_language relation.
 * ----------------
 */
typedef FormData_pg_language *Form_pg_language;

DECLARE_TOAST(pg_language, 4157, 4158);

DECLARE_UNIQUE_INDEX(pg_language_name_index, 2681, LanguageNameIndexId, on pg_language using btree(lanname name_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_language_oid_index, 2682, LanguageOidIndexId, on pg_language using btree(oid oid_ops));

#endif							/* PG_LANGUAGE_H */
