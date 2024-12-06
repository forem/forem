/*-------------------------------------------------------------------------
 *
 * pg_conversion.h
 *	  definition of the "conversion" system catalog (pg_conversion)
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_conversion.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_CONVERSION_H
#define PG_CONVERSION_H

#include "catalog/genbki.h"
#include "catalog/objectaddress.h"
#include "catalog/pg_conversion_d.h"

/* ----------------
 *		pg_conversion definition.  cpp turns this into
 *		typedef struct FormData_pg_conversion
 * ----------------
 */
CATALOG(pg_conversion,2607,ConversionRelationId)
{
	/* oid */
	Oid			oid;

	/* name of the conversion */
	NameData	conname;

	/* namespace that the conversion belongs to */
	Oid			connamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* owner of the conversion */
	Oid			conowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* FOR encoding id */
	int32		conforencoding BKI_LOOKUP(encoding);

	/* TO encoding id */
	int32		contoencoding BKI_LOOKUP(encoding);

	/* OID of the conversion proc */
	regproc		conproc BKI_LOOKUP(pg_proc);

	/* true if this is a default conversion */
	bool		condefault BKI_DEFAULT(t);
} FormData_pg_conversion;

/* ----------------
 *		Form_pg_conversion corresponds to a pointer to a tuple with
 *		the format of pg_conversion relation.
 * ----------------
 */
typedef FormData_pg_conversion *Form_pg_conversion;

DECLARE_UNIQUE_INDEX(pg_conversion_default_index, 2668, ConversionDefaultIndexId, on pg_conversion using btree(connamespace oid_ops, conforencoding int4_ops, contoencoding int4_ops, oid oid_ops));
DECLARE_UNIQUE_INDEX(pg_conversion_name_nsp_index, 2669, ConversionNameNspIndexId, on pg_conversion using btree(conname name_ops, connamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_conversion_oid_index, 2670, ConversionOidIndexId, on pg_conversion using btree(oid oid_ops));


extern ObjectAddress ConversionCreate(const char *conname, Oid connamespace,
									  Oid conowner,
									  int32 conforencoding, int32 contoencoding,
									  Oid conproc, bool def);
extern Oid	FindDefaultConversion(Oid connamespace, int32 for_encoding,
								  int32 to_encoding);

#endif							/* PG_CONVERSION_H */
