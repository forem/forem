/*-------------------------------------------------------------------------
 *
 * genbki.h
 *	  Required include file for all POSTGRES catalog header files
 *
 * genbki.h defines CATALOG(), BKI_BOOTSTRAP and related macros
 * so that the catalog header files can be read by the C compiler.
 * (These same words are recognized by genbki.pl to build the BKI
 * bootstrap file from these header files.)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/genbki.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef GENBKI_H
#define GENBKI_H

/* Introduces a catalog's structure definition */
#define CATALOG(name,oid,oidmacro)	typedef struct CppConcat(FormData_,name)

/* Options that may appear after CATALOG (on the same line) */
#define BKI_BOOTSTRAP
#define BKI_SHARED_RELATION
#define BKI_ROWTYPE_OID(oid,oidmacro)
#define BKI_SCHEMA_MACRO

/* Options that may appear after an attribute (on the same line) */
#define BKI_FORCE_NULL
#define BKI_FORCE_NOT_NULL
/* Specifies a default value for a catalog field */
#define BKI_DEFAULT(value)
/* Specifies a default value for auto-generated array types */
#define BKI_ARRAY_DEFAULT(value)
/*
 * Indicates that the attribute contains OIDs referencing the named catalog;
 * can be applied to columns of oid, regproc, oid[], or oidvector type.
 * genbki.pl uses this to know how to perform name lookups in the initial
 * data (if any), and it also feeds into regression-test validity checks.
 * The _OPT suffix indicates that values can be zero instead of
 * a valid OID reference.
 */
#define BKI_LOOKUP(catalog)
#define BKI_LOOKUP_OPT(catalog)

/*
 * These lines are processed by genbki.pl to create the statements
 * the bootstrap parser will turn into BootstrapToastTable commands.
 * Each line specifies the system catalog that needs a toast table,
 * the OID to assign to the toast table, and the OID to assign to the
 * toast table's index.  The reason we hard-wire these OIDs is that we
 * need stable OIDs for shared relations, and that includes toast tables
 * of shared relations.
 *
 * The DECLARE_TOAST_WITH_MACRO variant is used when C macros are needed
 * for the toast table/index OIDs (usually only for shared catalogs).
 *
 * The macro definitions are just to keep the C compiler from spitting up.
 */
#define DECLARE_TOAST(name,toastoid,indexoid) extern int no_such_variable
#define DECLARE_TOAST_WITH_MACRO(name,toastoid,indexoid,toastoidmacro,indexoidmacro) extern int no_such_variable

/*
 * These lines are processed by genbki.pl to create the statements
 * the bootstrap parser will turn into DefineIndex calls.
 *
 * The keyword is DECLARE_INDEX or DECLARE_UNIQUE_INDEX or
 * DECLARE_UNIQUE_INDEX_PKEY.  ("PKEY" marks the index as being the catalog's
 * primary key; currently this is only cosmetically different from a regular
 * unique index.  By convention, we usually make a catalog's OID column its
 * pkey, if it has one.)  The first two arguments are the index's name and
 * OID, the rest is much like a standard 'create index' SQL command.
 *
 * For each index, we also provide a #define for its OID.  References to
 * the index in the C code should always use these #defines, not the actual
 * index name (much less the numeric OID).
 *
 * The macro definitions are just to keep the C compiler from spitting up.
 */
#define DECLARE_INDEX(name,oid,oidmacro,decl) extern int no_such_variable
#define DECLARE_UNIQUE_INDEX(name,oid,oidmacro,decl) extern int no_such_variable
#define DECLARE_UNIQUE_INDEX_PKEY(name,oid,oidmacro,decl) extern int no_such_variable

/*
 * These lines inform genbki.pl about manually-assigned OIDs that do not
 * correspond to any entry in the catalog *.dat files, but should be subject
 * to uniqueness verification and renumber_oids.pl renumbering.  A C macro
 * to #define the given name is emitted into the corresponding *_d.h file.
 */
#define DECLARE_OID_DEFINING_MACRO(name,oid) extern int no_such_variable

/*
 * These lines are processed by genbki.pl to create a table for use
 * by the pg_get_catalog_foreign_keys() function.  We do not have any
 * mechanism that actually enforces foreign-key relationships in the
 * system catalogs, but it is still useful to record the intended
 * relationships in a machine-readable form.
 *
 * The keyword is DECLARE_FOREIGN_KEY[_OPT] or DECLARE_ARRAY_FOREIGN_KEY[_OPT].
 * The first argument is a parenthesized list of the referencing columns;
 * the second, the name of the referenced table; the third, a parenthesized
 * list of the referenced columns.  Use of the ARRAY macros means that the
 * last referencing column is an array, each of whose elements is supposed
 * to match some entry in the last referenced column.  Use of the OPT suffix
 * indicates that the referencing column(s) can be zero instead of a valid
 * reference.
 *
 * Columns that are marked with a BKI_LOOKUP rule do not need an explicit
 * DECLARE_FOREIGN_KEY macro, as genbki.pl can infer the FK relationship
 * from that.  Thus, these macros are only needed in special cases.
 *
 * The macro definitions are just to keep the C compiler from spitting up.
 */
#define DECLARE_FOREIGN_KEY(cols,reftbl,refcols) extern int no_such_variable
#define DECLARE_FOREIGN_KEY_OPT(cols,reftbl,refcols) extern int no_such_variable
#define DECLARE_ARRAY_FOREIGN_KEY(cols,reftbl,refcols) extern int no_such_variable
#define DECLARE_ARRAY_FOREIGN_KEY_OPT(cols,reftbl,refcols) extern int no_such_variable

/* The following are never defined; they are here only for documentation. */

/*
 * Variable-length catalog fields (except possibly the first not nullable one)
 * should not be visible in C structures, so they are made invisible by #ifdefs
 * of an undefined symbol.  See also the BOOTCOL_NULL_AUTO code in bootstrap.c
 * for how this is handled.
 */
#undef CATALOG_VARLEN

/*
 * There is code in some catalog headers that needs to be visible to clients,
 * but we don't want clients to include the full header because of safety
 * issues with other code in the header.  To handle that, surround code that
 * should be visible to clients with "#ifdef EXPOSE_TO_CLIENT_CODE".  That
 * instructs genbki.pl to copy the section when generating the corresponding
 * "_d" header, which can be included by both client and backend code.
 */
#undef EXPOSE_TO_CLIENT_CODE

#endif							/* GENBKI_H */
