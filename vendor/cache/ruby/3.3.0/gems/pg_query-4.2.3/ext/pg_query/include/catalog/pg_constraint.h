/*-------------------------------------------------------------------------
 *
 * pg_constraint.h
 *	  definition of the "constraint" system catalog (pg_constraint)
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/pg_constraint.h
 *
 * NOTES
 *	  The Catalog.pm module reads this file and derives schema
 *	  information.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_CONSTRAINT_H
#define PG_CONSTRAINT_H

#include "catalog/dependency.h"
#include "catalog/genbki.h"
#include "catalog/pg_constraint_d.h"
#include "nodes/pg_list.h"

/* ----------------
 *		pg_constraint definition.  cpp turns this into
 *		typedef struct FormData_pg_constraint
 * ----------------
 */
CATALOG(pg_constraint,2606,ConstraintRelationId)
{
	Oid			oid;			/* oid */

	/*
	 * conname + connamespace is deliberately not unique; we allow, for
	 * example, the same name to be used for constraints of different
	 * relations.  This is partly for backwards compatibility with past
	 * Postgres practice, and partly because we don't want to have to obtain a
	 * global lock to generate a globally unique name for a nameless
	 * constraint.  We associate a namespace with constraint names only for
	 * SQL-spec compatibility.
	 *
	 * However, we do require conname to be unique among the constraints of a
	 * single relation or domain.  This is enforced by a unique index on
	 * conrelid + contypid + conname.
	 */
	NameData	conname;		/* name of this constraint */
	Oid			connamespace BKI_LOOKUP(pg_namespace);	/* OID of namespace
														 * containing constraint */
	char		contype;		/* constraint type; see codes below */
	bool		condeferrable;	/* deferrable constraint? */
	bool		condeferred;	/* deferred by default? */
	bool		convalidated;	/* constraint has been validated? */

	/*
	 * conrelid and conkey are only meaningful if the constraint applies to a
	 * specific relation (this excludes domain constraints and assertions).
	 * Otherwise conrelid is 0 and conkey is NULL.
	 */
	Oid			conrelid BKI_LOOKUP_OPT(pg_class);	/* relation this
													 * constraint constrains */

	/*
	 * contypid links to the pg_type row for a domain if this is a domain
	 * constraint.  Otherwise it's 0.
	 *
	 * For SQL-style global ASSERTIONs, both conrelid and contypid would be
	 * zero. This is not presently supported, however.
	 */
	Oid			contypid BKI_LOOKUP_OPT(pg_type);	/* domain this constraint
													 * constrains */

	/*
	 * conindid links to the index supporting the constraint, if any;
	 * otherwise it's 0.  This is used for unique, primary-key, and exclusion
	 * constraints, and less obviously for foreign-key constraints (where the
	 * index is a unique index on the referenced relation's referenced
	 * columns).  Notice that the index is on conrelid in the first case but
	 * confrelid in the second.
	 */
	Oid			conindid BKI_LOOKUP_OPT(pg_class);	/* index supporting this
													 * constraint */

	/*
	 * If this constraint is on a partition inherited from a partitioned
	 * table, this is the OID of the corresponding constraint in the parent.
	 */
	Oid			conparentid BKI_LOOKUP_OPT(pg_constraint);

	/*
	 * These fields, plus confkey, are only meaningful for a foreign-key
	 * constraint.  Otherwise confrelid is 0 and the char fields are spaces.
	 */
	Oid			confrelid BKI_LOOKUP_OPT(pg_class); /* relation referenced by
													 * foreign key */
	char		confupdtype;	/* foreign key's ON UPDATE action */
	char		confdeltype;	/* foreign key's ON DELETE action */
	char		confmatchtype;	/* foreign key's match type */

	/* Has a local definition (hence, do not drop when coninhcount is 0) */
	bool		conislocal;

	/* Number of times inherited from direct parent relation(s) */
	int32		coninhcount;

	/* Has a local definition and cannot be inherited */
	bool		connoinherit;

#ifdef CATALOG_VARLEN			/* variable-length fields start here */

	/*
	 * Columns of conrelid that the constraint applies to, if known (this is
	 * NULL for trigger constraints)
	 */
	int16		conkey[1];

	/*
	 * If a foreign key, the referenced columns of confrelid
	 */
	int16		confkey[1];

	/*
	 * If a foreign key, the OIDs of the PK = FK equality operators for each
	 * column of the constraint
	 */
	Oid			conpfeqop[1] BKI_LOOKUP(pg_operator);

	/*
	 * If a foreign key, the OIDs of the PK = PK equality operators for each
	 * column of the constraint (i.e., equality for the referenced columns)
	 */
	Oid			conppeqop[1] BKI_LOOKUP(pg_operator);

	/*
	 * If a foreign key, the OIDs of the FK = FK equality operators for each
	 * column of the constraint (i.e., equality for the referencing columns)
	 */
	Oid			conffeqop[1] BKI_LOOKUP(pg_operator);

	/*
	 * If a foreign key with an ON DELETE SET NULL/DEFAULT action, the subset
	 * of conkey to updated.  If null, all columns are updated.
	 */
	int16		confdelsetcols[1];

	/*
	 * If an exclusion constraint, the OIDs of the exclusion operators for
	 * each column of the constraint
	 */
	Oid			conexclop[1] BKI_LOOKUP(pg_operator);

	/*
	 * If a check constraint, nodeToString representation of expression
	 */
	pg_node_tree conbin;
#endif
} FormData_pg_constraint;

/* ----------------
 *		Form_pg_constraint corresponds to a pointer to a tuple with
 *		the format of pg_constraint relation.
 * ----------------
 */
typedef FormData_pg_constraint *Form_pg_constraint;

DECLARE_TOAST(pg_constraint, 2832, 2833);

DECLARE_INDEX(pg_constraint_conname_nsp_index, 2664, ConstraintNameNspIndexId, on pg_constraint using btree(conname name_ops, connamespace oid_ops));
DECLARE_UNIQUE_INDEX(pg_constraint_conrelid_contypid_conname_index, 2665, ConstraintRelidTypidNameIndexId, on pg_constraint using btree(conrelid oid_ops, contypid oid_ops, conname name_ops));
DECLARE_INDEX(pg_constraint_contypid_index, 2666, ConstraintTypidIndexId, on pg_constraint using btree(contypid oid_ops));
DECLARE_UNIQUE_INDEX_PKEY(pg_constraint_oid_index, 2667, ConstraintOidIndexId, on pg_constraint using btree(oid oid_ops));
DECLARE_INDEX(pg_constraint_conparentid_index, 2579, ConstraintParentIndexId, on pg_constraint using btree(conparentid oid_ops));

/* conkey can contain zero (InvalidAttrNumber) if a whole-row Var is used */
DECLARE_ARRAY_FOREIGN_KEY_OPT((conrelid, conkey), pg_attribute, (attrelid, attnum));
DECLARE_ARRAY_FOREIGN_KEY((confrelid, confkey), pg_attribute, (attrelid, attnum));

#ifdef EXPOSE_TO_CLIENT_CODE

/* Valid values for contype */
#define CONSTRAINT_CHECK			'c'
#define CONSTRAINT_FOREIGN			'f'
#define CONSTRAINT_PRIMARY			'p'
#define CONSTRAINT_UNIQUE			'u'
#define CONSTRAINT_TRIGGER			't'
#define CONSTRAINT_EXCLUSION		'x'

/*
 * Valid values for confupdtype and confdeltype are the FKCONSTR_ACTION_xxx
 * constants defined in parsenodes.h.  Valid values for confmatchtype are
 * the FKCONSTR_MATCH_xxx constants defined in parsenodes.h.
 */

#endif							/* EXPOSE_TO_CLIENT_CODE */

/*
 * Identify constraint type for lookup purposes
 */
typedef enum ConstraintCategory
{
	CONSTRAINT_RELATION,
	CONSTRAINT_DOMAIN,
	CONSTRAINT_ASSERTION		/* for future expansion */
} ConstraintCategory;


extern Oid	CreateConstraintEntry(const char *constraintName,
								  Oid constraintNamespace,
								  char constraintType,
								  bool isDeferrable,
								  bool isDeferred,
								  bool isValidated,
								  Oid parentConstrId,
								  Oid relId,
								  const int16 *constraintKey,
								  int constraintNKeys,
								  int constraintNTotalKeys,
								  Oid domainId,
								  Oid indexRelId,
								  Oid foreignRelId,
								  const int16 *foreignKey,
								  const Oid *pfEqOp,
								  const Oid *ppEqOp,
								  const Oid *ffEqOp,
								  int foreignNKeys,
								  char foreignUpdateType,
								  char foreignDeleteType,
								  const int16 *fkDeleteSetCols,
								  int numFkDeleteSetCols,
								  char foreignMatchType,
								  const Oid *exclOp,
								  Node *conExpr,
								  const char *conBin,
								  bool conIsLocal,
								  int conInhCount,
								  bool conNoInherit,
								  bool is_internal);

extern void RemoveConstraintById(Oid conId);
extern void RenameConstraintById(Oid conId, const char *newname);

extern bool ConstraintNameIsUsed(ConstraintCategory conCat, Oid objId,
								 const char *conname);
extern bool ConstraintNameExists(const char *conname, Oid namespaceid);
extern char *ChooseConstraintName(const char *name1, const char *name2,
								  const char *label, Oid namespaceid,
								  List *others);

extern void AlterConstraintNamespaces(Oid ownerId, Oid oldNspId,
									  Oid newNspId, bool isType, ObjectAddresses *objsMoved);
extern void ConstraintSetParentConstraint(Oid childConstrId,
										  Oid parentConstrId,
										  Oid childTableId);
extern Oid	get_relation_constraint_oid(Oid relid, const char *conname, bool missing_ok);
extern Bitmapset *get_relation_constraint_attnos(Oid relid, const char *conname,
												 bool missing_ok, Oid *constraintOid);
extern Oid	get_domain_constraint_oid(Oid typid, const char *conname, bool missing_ok);
extern Oid	get_relation_idx_constraint_oid(Oid relationId, Oid indexId);

extern Bitmapset *get_primary_key_attnos(Oid relid, bool deferrableOk,
										 Oid *constraintOid);
extern void DeconstructFkConstraintRow(HeapTuple tuple, int *numfks,
									   AttrNumber *conkey, AttrNumber *confkey,
									   Oid *pf_eq_oprs, Oid *pp_eq_oprs, Oid *ff_eq_oprs,
									   int *num_fk_del_set_cols, AttrNumber *fk_del_set_cols);

extern bool check_functional_grouping(Oid relid,
									  Index varno, Index varlevelsup,
									  List *grouping_columns,
									  List **constraintDeps);

#endif							/* PG_CONSTRAINT_H */
