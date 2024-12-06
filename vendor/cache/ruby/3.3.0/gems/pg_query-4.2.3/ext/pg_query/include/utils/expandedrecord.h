/*-------------------------------------------------------------------------
 *
 * expandedrecord.h
 *	  Declarations for composite expanded objects.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/utils/expandedrecord.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef EXPANDEDRECORD_H
#define EXPANDEDRECORD_H

#include "access/htup.h"
#include "access/tupdesc.h"
#include "fmgr.h"
#include "utils/expandeddatum.h"


/*
 * An expanded record is contained within a private memory context (as
 * all expanded objects must be) and has a control structure as below.
 *
 * The expanded record might contain a regular "flat" tuple if that was the
 * original input and we've not modified it.  Otherwise, the contents are
 * represented by Datum/isnull arrays plus type information.  We could also
 * have both forms, if we've deconstructed the original tuple for access
 * purposes but not yet changed it.  For pass-by-reference field types, the
 * Datums would point into the flat tuple in this situation.  Once we start
 * modifying tuple fields, new pass-by-ref fields are separately palloc'd
 * within the memory context.
 *
 * It's possible to build an expanded record that references a "flat" tuple
 * stored externally, if the caller can guarantee that that tuple will not
 * change for the lifetime of the expanded record.  (This frammish is mainly
 * meant to avoid unnecessary data copying in trigger functions.)
 */
#define ER_MAGIC 1384727874		/* ID for debugging crosschecks */

typedef struct ExpandedRecordHeader
{
	/* Standard header for expanded objects */
	ExpandedObjectHeader hdr;

	/* Magic value identifying an expanded record (for debugging only) */
	int			er_magic;

	/* Assorted flag bits */
	int			flags;
#define ER_FLAG_FVALUE_VALID	0x0001	/* fvalue is up to date? */
#define ER_FLAG_FVALUE_ALLOCED	0x0002	/* fvalue is local storage? */
#define ER_FLAG_DVALUES_VALID	0x0004	/* dvalues/dnulls are up to date? */
#define ER_FLAG_DVALUES_ALLOCED	0x0008	/* any field values local storage? */
#define ER_FLAG_HAVE_EXTERNAL	0x0010	/* any field values are external? */
#define ER_FLAG_TUPDESC_ALLOCED	0x0020	/* tupdesc is local storage? */
#define ER_FLAG_IS_DOMAIN		0x0040	/* er_decltypeid is domain? */
#define ER_FLAG_IS_DUMMY		0x0080	/* this header is dummy (see below) */
/* flag bits that are not to be cleared when replacing tuple data: */
#define ER_FLAGS_NON_DATA \
	(ER_FLAG_TUPDESC_ALLOCED | ER_FLAG_IS_DOMAIN | ER_FLAG_IS_DUMMY)

	/* Declared type of the record variable (could be a domain type) */
	Oid			er_decltypeid;

	/*
	 * Actual composite type/typmod; never a domain (if ER_FLAG_IS_DOMAIN,
	 * these identify the composite base type).  These will match
	 * er_tupdesc->tdtypeid/tdtypmod, as well as the header fields of
	 * composite datums made from or stored in this expanded record.
	 */
	Oid			er_typeid;		/* type OID of the composite type */
	int32		er_typmod;		/* typmod of the composite type */

	/*
	 * Tuple descriptor, if we have one, else NULL.  This may point to a
	 * reference-counted tupdesc originally belonging to the typcache, in
	 * which case we use a memory context reset callback to release the
	 * refcount.  It can also be locally allocated in this object's private
	 * context (in which case ER_FLAG_TUPDESC_ALLOCED is set).
	 */
	TupleDesc	er_tupdesc;

	/*
	 * Unique-within-process identifier for the tupdesc (see typcache.h). This
	 * field will never be equal to INVALID_TUPLEDESC_IDENTIFIER.
	 */
	uint64		er_tupdesc_id;

	/*
	 * If we have a Datum-array representation of the record, it's kept here;
	 * else ER_FLAG_DVALUES_VALID is not set, and dvalues/dnulls may be NULL
	 * if they've not yet been allocated.  If allocated, the dvalues and
	 * dnulls arrays are palloc'd within the object private context, and are
	 * of length matching er_tupdesc->natts.  For pass-by-ref field types,
	 * dvalues entries might point either into the fstartptr..fendptr area, or
	 * to separately palloc'd chunks.
	 */
	Datum	   *dvalues;		/* array of Datums */
	bool	   *dnulls;			/* array of is-null flags for Datums */
	int			nfields;		/* length of above arrays */

	/*
	 * flat_size is the current space requirement for the flat equivalent of
	 * the expanded record, if known; otherwise it's 0.  We store this to make
	 * consecutive calls of get_flat_size cheap.  If flat_size is not 0, the
	 * component values data_len, hoff, and hasnull must be valid too.
	 */
	Size		flat_size;

	Size		data_len;		/* data len within flat_size */
	int			hoff;			/* header offset */
	bool		hasnull;		/* null bitmap needed? */

	/*
	 * fvalue points to the flat representation if we have one, else it is
	 * NULL.  If the flat representation is valid (up to date) then
	 * ER_FLAG_FVALUE_VALID is set.  Even if we've outdated the flat
	 * representation due to changes of user fields, it can still be used to
	 * fetch system column values.  If we have a flat representation then
	 * fstartptr/fendptr point to the start and end+1 of its data area; this
	 * is so that we can tell which Datum pointers point into the flat
	 * representation rather than being pointers to separately palloc'd data.
	 */
	HeapTuple	fvalue;			/* might or might not be private storage */
	char	   *fstartptr;		/* start of its data area */
	char	   *fendptr;		/* end+1 of its data area */

	/* Some operations on the expanded record need a short-lived context */
	MemoryContext er_short_term_cxt;	/* short-term memory context */

	/* Working state for domain checking, used if ER_FLAG_IS_DOMAIN is set */
	struct ExpandedRecordHeader *er_dummy_header;	/* dummy record header */
	void	   *er_domaininfo;	/* cache space for domain_check() */

	/* Callback info (it's active if er_mcb.arg is not NULL) */
	MemoryContextCallback er_mcb;
} ExpandedRecordHeader;

/* fmgr macros for expanded record objects */
#define PG_GETARG_EXPANDED_RECORD(n)  DatumGetExpandedRecord(PG_GETARG_DATUM(n))
#define ExpandedRecordGetDatum(erh)   EOHPGetRWDatum(&(erh)->hdr)
#define ExpandedRecordGetRODatum(erh) EOHPGetRODatum(&(erh)->hdr)
#define PG_RETURN_EXPANDED_RECORD(x)  PG_RETURN_DATUM(ExpandedRecordGetDatum(x))

/* assorted other macros */
#define ExpandedRecordIsEmpty(erh) \
	(((erh)->flags & (ER_FLAG_DVALUES_VALID | ER_FLAG_FVALUE_VALID)) == 0)
#define ExpandedRecordIsDomain(erh) \
	(((erh)->flags & ER_FLAG_IS_DOMAIN) != 0)

/* this can substitute for TransferExpandedObject() when we already have erh */
#define TransferExpandedRecord(erh, cxt) \
	MemoryContextSetParent((erh)->hdr.eoh_context, cxt)

/* information returned by expanded_record_lookup_field() */
typedef struct ExpandedRecordFieldInfo
{
	int			fnumber;		/* field's attr number in record */
	Oid			ftypeid;		/* field's type/typmod info */
	int32		ftypmod;
	Oid			fcollation;		/* field's collation if any */
} ExpandedRecordFieldInfo;

/*
 * prototypes for functions defined in expandedrecord.c
 */
extern ExpandedRecordHeader *make_expanded_record_from_typeid(Oid type_id, int32 typmod,
															  MemoryContext parentcontext);
extern ExpandedRecordHeader *make_expanded_record_from_tupdesc(TupleDesc tupdesc,
															   MemoryContext parentcontext);
extern ExpandedRecordHeader *make_expanded_record_from_exprecord(ExpandedRecordHeader *olderh,
																 MemoryContext parentcontext);
extern void expanded_record_set_tuple(ExpandedRecordHeader *erh,
									  HeapTuple tuple, bool copy, bool expand_external);
extern Datum make_expanded_record_from_datum(Datum recorddatum,
											 MemoryContext parentcontext);
extern TupleDesc expanded_record_fetch_tupdesc(ExpandedRecordHeader *erh);
extern HeapTuple expanded_record_get_tuple(ExpandedRecordHeader *erh);
extern ExpandedRecordHeader *DatumGetExpandedRecord(Datum d);
extern void deconstruct_expanded_record(ExpandedRecordHeader *erh);
extern bool expanded_record_lookup_field(ExpandedRecordHeader *erh,
										 const char *fieldname,
										 ExpandedRecordFieldInfo *finfo);
extern Datum expanded_record_fetch_field(ExpandedRecordHeader *erh, int fnumber,
										 bool *isnull);
extern void expanded_record_set_field_internal(ExpandedRecordHeader *erh,
											   int fnumber,
											   Datum newValue, bool isnull,
											   bool expand_external,
											   bool check_constraints);
extern void expanded_record_set_fields(ExpandedRecordHeader *erh,
									   const Datum *newValues, const bool *isnulls,
									   bool expand_external);

/* outside code should never call expanded_record_set_field_internal as such */
#define expanded_record_set_field(erh, fnumber, newValue, isnull, expand_external) \
	expanded_record_set_field_internal(erh, fnumber, newValue, isnull, expand_external, true)

/*
 * Inline-able fast cases.  The expanded_record_fetch_xxx functions above
 * handle the general cases.
 */

/* Get the tupdesc for the expanded record's actual type */
static inline TupleDesc
expanded_record_get_tupdesc(ExpandedRecordHeader *erh)
{
	if (likely(erh->er_tupdesc != NULL))
		return erh->er_tupdesc;
	else
		return expanded_record_fetch_tupdesc(erh);
}

/* Get value of record field */
static inline Datum
expanded_record_get_field(ExpandedRecordHeader *erh, int fnumber,
						  bool *isnull)
{
	if ((erh->flags & ER_FLAG_DVALUES_VALID) &&
		likely(fnumber > 0 && fnumber <= erh->nfields))
	{
		*isnull = erh->dnulls[fnumber - 1];
		return erh->dvalues[fnumber - 1];
	}
	else
		return expanded_record_fetch_field(erh, fnumber, isnull);
}

#endif							/* EXPANDEDRECORD_H */
