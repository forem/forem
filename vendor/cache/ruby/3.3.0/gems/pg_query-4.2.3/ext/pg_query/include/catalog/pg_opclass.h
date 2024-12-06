/*-------------------------------------------------------------------------
 *
 * pg_opclass.h
 *	  definition of the "operator class" system catalog (pg_opclass)
 *
 * The primary key for this table is <opcmethod, opcname, opcnamespace> ---
 * that is, there is a row for each valid combination of opclass name and
 * index access method type.  This row specifies the expected input data type
 * for the opclass (the type of the heap column, or the expression output type
 * in the case of an index expression).  Note that types binary-coercible to
 * the specified type will be accepted too.
 *
 * For a given <opcmethod, opcintype> pair, there can be at most one row that
 * has opcdefault = true; this row is the default opclass for such data in
 * such an index.  (This is not currently enforced by an index, because we
 * don't support partial indexes on system catalogs.)
 *
 * Normally opckeytype = InvalidOid (zero), indicating that the data stored
 * in the index is the same as the data in the indexed column.  If opckeytype
 * is nonzero then it indicates that a conversion step is needed to produce
 * the stored index data, which will be of type opckeytype (which might be
 * the same or different from the input datatype).  Performing such a
 * conversion is the responsibility of the index access method --- not all
 * AMs support this.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_opclass.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_OPCLASS_H
#define PG_OPCLASS_H

#include "catalog/genbki.h"
#include "catalog/pg_opclass_d.h"

/* ----------------
 *		pg_opclass definition.  cpp turns this into
 *		typedef struct FormData_pg_opclass
 * ----------------
 */
CATALOG(pg_opclass,2616,OperatorClassRelationId)
{
	Oid			oid;			/* oid */

	/* index access method opclass is for */
	Oid			opcmethod BKI_LOOKUP(pg_am);

	/* name of this opclass */
	NameData	opcname;

	/* namespace of this opclass */
	Oid			opcnamespace BKI_DEFAULT(pg_catalog) BKI_LOOKUP(pg_namespace);

	/* opclass owner */
	Oid			opcowner BKI_DEFAULT(POSTGRES) BKI_LOOKUP(pg_authid);

	/* containing operator family */
	Oid			opcfamily BKI_LOOKUP(pg_opfamily);

	/* type of data indexed by opclass */
	Oid			opcintype BKI_LOOKUP(pg_type);

	/* T if opclass is default for opcintype */
	bool		opcdefault BKI_DEFAULT(t);

	/* type of data in index, or InvalidOid if same as input column type */
	Oid			opckeytype BKI_DEFAULT(0) BKI_LOOKUP_OPT(pg_type);
} FormData_pg_opclass;

/* ----------------
 *		Form_pg_opclass corresponds to a pointer to a tuple with
 *		the format of pg_opclass relation.
 * ----------------
 */
typedef FormData_pg_opclass *Form_pg_opclass;

DECLARE_UNIQUE_INDEX(pg_opclass_am_name_nsp_index, 2686, OpclassAmNameNspIndexId, on pg_opclass using btree(opcmethod oid_ops, opcname name_ops, opcnamespace oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_opclass_oid_index, 2687, OpclassOidIndexId, on pg_opclass using btree(oid oid_ops));

#endif							/* PG_OPCLASS_H */
