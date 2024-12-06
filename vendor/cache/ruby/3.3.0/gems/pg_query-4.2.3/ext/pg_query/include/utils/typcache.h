/*-------------------------------------------------------------------------
 *
 * typcache.h
 *	  Type cache definitions.
 *
 * The type cache exists to speed lookup of certain information about data
 * types that is not directly available from a type's pg_type row.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/typcache.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TYPCACHE_H
#define TYPCACHE_H

#include "access/tupdesc.h"
#include "fmgr.h"
#include "storage/dsm.h"
#include "utils/dsa.h"


/* DomainConstraintCache is an opaque struct known only within typcache.c */
typedef struct DomainConstraintCache DomainConstraintCache;

/* TypeCacheEnumData is an opaque struct known only within typcache.c */
struct TypeCacheEnumData;

typedef struct TypeCacheEntry
{
	/* typeId is the hash lookup key and MUST BE FIRST */
	Oid			type_id;		/* OID of the data type */

	uint32		type_id_hash;	/* hashed value of the OID */

	/* some subsidiary information copied from the pg_type row */
	int16		typlen;
	bool		typbyval;
	char		typalign;
	char		typstorage;
	char		typtype;
	Oid			typrelid;
	Oid			typsubscript;
	Oid			typelem;
	Oid			typcollation;

	/*
	 * Information obtained from opfamily entries
	 *
	 * These will be InvalidOid if no match could be found, or if the
	 * information hasn't yet been requested.  Also note that for array and
	 * composite types, typcache.c checks that the contained types are
	 * comparable or hashable before allowing eq_opr etc to become set.
	 */
	Oid			btree_opf;		/* the default btree opclass' family */
	Oid			btree_opintype; /* the default btree opclass' opcintype */
	Oid			hash_opf;		/* the default hash opclass' family */
	Oid			hash_opintype;	/* the default hash opclass' opcintype */
	Oid			eq_opr;			/* the equality operator */
	Oid			lt_opr;			/* the less-than operator */
	Oid			gt_opr;			/* the greater-than operator */
	Oid			cmp_proc;		/* the btree comparison function */
	Oid			hash_proc;		/* the hash calculation function */
	Oid			hash_extended_proc; /* the extended hash calculation function */

	/*
	 * Pre-set-up fmgr call info for the equality operator, the btree
	 * comparison function, and the hash calculation function.  These are kept
	 * in the type cache to avoid problems with memory leaks in repeated calls
	 * to functions such as array_eq, array_cmp, hash_array.  There is not
	 * currently a need to maintain call info for the lt_opr or gt_opr.
	 */
	FmgrInfo	eq_opr_finfo;
	FmgrInfo	cmp_proc_finfo;
	FmgrInfo	hash_proc_finfo;
	FmgrInfo	hash_extended_proc_finfo;

	/*
	 * Tuple descriptor if it's a composite type (row type).  NULL if not
	 * composite or information hasn't yet been requested.  (NOTE: this is a
	 * reference-counted tupledesc.)
	 *
	 * To simplify caching dependent info, tupDesc_identifier is an identifier
	 * for this tupledesc that is unique for the life of the process, and
	 * changes anytime the tupledesc does.  Zero if not yet determined.
	 */
	TupleDesc	tupDesc;
	uint64		tupDesc_identifier;

	/*
	 * Fields computed when TYPECACHE_RANGE_INFO is requested.  Zeroes if not
	 * a range type or information hasn't yet been requested.  Note that
	 * rng_cmp_proc_finfo could be different from the element type's default
	 * btree comparison function.
	 */
	struct TypeCacheEntry *rngelemtype; /* range's element type */
	Oid			rng_collation;	/* collation for comparisons, if any */
	FmgrInfo	rng_cmp_proc_finfo; /* comparison function */
	FmgrInfo	rng_canonical_finfo;	/* canonicalization function, if any */
	FmgrInfo	rng_subdiff_finfo;	/* difference function, if any */

	/*
	 * Fields computed when TYPECACHE_MULTIRANGE_INFO is required.
	 */
	struct TypeCacheEntry *rngtype; /* multirange's range underlying type */

	/*
	 * Domain's base type and typmod if it's a domain type.  Zeroes if not
	 * domain, or if information hasn't been requested.
	 */
	Oid			domainBaseType;
	int32		domainBaseTypmod;

	/*
	 * Domain constraint data if it's a domain type.  NULL if not domain, or
	 * if domain has no constraints, or if information hasn't been requested.
	 */
	DomainConstraintCache *domainData;

	/* Private data, for internal use of typcache.c only */
	int			flags;			/* flags about what we've computed */

	/*
	 * Private information about an enum type.  NULL if not enum or
	 * information hasn't been requested.
	 */
	struct TypeCacheEnumData *enumData;

	/* We also maintain a list of all known domain-type cache entries */
	struct TypeCacheEntry *nextDomain;
} TypeCacheEntry;

/* Bit flags to indicate which fields a given caller needs to have set */
#define TYPECACHE_EQ_OPR			0x00001
#define TYPECACHE_LT_OPR			0x00002
#define TYPECACHE_GT_OPR			0x00004
#define TYPECACHE_CMP_PROC			0x00008
#define TYPECACHE_HASH_PROC			0x00010
#define TYPECACHE_EQ_OPR_FINFO		0x00020
#define TYPECACHE_CMP_PROC_FINFO	0x00040
#define TYPECACHE_HASH_PROC_FINFO	0x00080
#define TYPECACHE_TUPDESC			0x00100
#define TYPECACHE_BTREE_OPFAMILY	0x00200
#define TYPECACHE_HASH_OPFAMILY		0x00400
#define TYPECACHE_RANGE_INFO		0x00800
#define TYPECACHE_DOMAIN_BASE_INFO			0x01000
#define TYPECACHE_DOMAIN_CONSTR_INFO		0x02000
#define TYPECACHE_HASH_EXTENDED_PROC		0x04000
#define TYPECACHE_HASH_EXTENDED_PROC_FINFO	0x08000
#define TYPECACHE_MULTIRANGE_INFO			0x10000

/* This value will not equal any valid tupledesc identifier, nor 0 */
#define INVALID_TUPLEDESC_IDENTIFIER ((uint64) 1)

/*
 * Callers wishing to maintain a long-lived reference to a domain's constraint
 * set must store it in one of these.  Use InitDomainConstraintRef() and
 * UpdateDomainConstraintRef() to manage it.  Note: DomainConstraintState is
 * considered an executable expression type, so it's defined in execnodes.h.
 */
typedef struct DomainConstraintRef
{
	List	   *constraints;	/* list of DomainConstraintState nodes */
	MemoryContext refctx;		/* context holding DomainConstraintRef */
	TypeCacheEntry *tcache;		/* typcache entry for domain type */
	bool		need_exprstate; /* does caller need check_exprstate? */

	/* Management data --- treat these fields as private to typcache.c */
	DomainConstraintCache *dcc; /* current constraints, or NULL if none */
	MemoryContextCallback callback; /* used to release refcount when done */
} DomainConstraintRef;

typedef struct SharedRecordTypmodRegistry SharedRecordTypmodRegistry;

extern TypeCacheEntry *lookup_type_cache(Oid type_id, int flags);

extern void InitDomainConstraintRef(Oid type_id, DomainConstraintRef *ref,
									MemoryContext refctx, bool need_exprstate);

extern void UpdateDomainConstraintRef(DomainConstraintRef *ref);

extern bool DomainHasConstraints(Oid type_id);

extern TupleDesc lookup_rowtype_tupdesc(Oid type_id, int32 typmod);

extern TupleDesc lookup_rowtype_tupdesc_noerror(Oid type_id, int32 typmod,
												bool noError);

extern TupleDesc lookup_rowtype_tupdesc_copy(Oid type_id, int32 typmod);

extern TupleDesc lookup_rowtype_tupdesc_domain(Oid type_id, int32 typmod,
											   bool noError);

extern void assign_record_type_typmod(TupleDesc tupDesc);

extern uint64 assign_record_type_identifier(Oid type_id, int32 typmod);

extern int	compare_values_of_enum(TypeCacheEntry *tcache, Oid arg1, Oid arg2);

extern size_t SharedRecordTypmodRegistryEstimate(void);

extern void SharedRecordTypmodRegistryInit(SharedRecordTypmodRegistry *,
										   dsm_segment *segment, dsa_area *area);

extern void SharedRecordTypmodRegistryAttach(SharedRecordTypmodRegistry *);

#endif							/* TYPCACHE_H */
