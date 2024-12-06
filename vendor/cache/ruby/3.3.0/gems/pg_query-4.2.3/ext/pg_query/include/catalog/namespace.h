/*-------------------------------------------------------------------------
 *
 * namespace.h
 *	  prototypes for functions in backend/catalog/namespace.c
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/catalog/namespace.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef NAMESPACE_H
#define NAMESPACE_H

#include "nodes/primnodes.h"
#include "storage/lock.h"


/*
 *	This structure holds a list of possible functions or operators
 *	found by namespace lookup.  Each function/operator is identified
 *	by OID and by argument types; the list must be pruned by type
 *	resolution rules that are embodied in the parser, not here.
 *	See FuncnameGetCandidates's comments for more info.
 */
typedef struct _FuncCandidateList
{
	struct _FuncCandidateList *next;
	int			pathpos;		/* for internal use of namespace lookup */
	Oid			oid;			/* the function or operator's OID */
	int			nominalnargs;	/* either pronargs or length(proallargtypes) */
	int			nargs;			/* number of arg types returned */
	int			nvargs;			/* number of args to become variadic array */
	int			ndargs;			/* number of defaulted args */
	int		   *argnumbers;		/* args' positional indexes, if named call */
	Oid			args[FLEXIBLE_ARRAY_MEMBER];	/* arg types */
}		   *FuncCandidateList;

/*
 * Result of checkTempNamespaceStatus
 */
typedef enum TempNamespaceStatus
{
	TEMP_NAMESPACE_NOT_TEMP,	/* nonexistent, or non-temp namespace */
	TEMP_NAMESPACE_IDLE,		/* exists, belongs to no active session */
	TEMP_NAMESPACE_IN_USE		/* belongs to some active session */
} TempNamespaceStatus;

/*
 *	Structure for xxxOverrideSearchPath functions
 *
 * The generation counter is private to namespace.c and shouldn't be touched
 * by other code.  It can be initialized to zero if necessary (that means
 * "not known equal to the current active path").
 */
typedef struct OverrideSearchPath
{
	List	   *schemas;		/* OIDs of explicitly named schemas */
	bool		addCatalog;		/* implicitly prepend pg_catalog? */
	bool		addTemp;		/* implicitly prepend temp schema? */
	uint64		generation;		/* for quick detection of equality to active */
} OverrideSearchPath;

/*
 * Option flag bits for RangeVarGetRelidExtended().
 */
typedef enum RVROption
{
	RVR_MISSING_OK = 1 << 0,	/* don't error if relation doesn't exist */
	RVR_NOWAIT = 1 << 1,		/* error if relation cannot be locked */
	RVR_SKIP_LOCKED = 1 << 2	/* skip if relation cannot be locked */
} RVROption;

typedef void (*RangeVarGetRelidCallback) (const RangeVar *relation, Oid relId,
										  Oid oldRelId, void *callback_arg);

#define RangeVarGetRelid(relation, lockmode, missing_ok) \
	RangeVarGetRelidExtended(relation, lockmode, \
							 (missing_ok) ? RVR_MISSING_OK : 0, NULL, NULL)

extern Oid	RangeVarGetRelidExtended(const RangeVar *relation,
									 LOCKMODE lockmode, uint32 flags,
									 RangeVarGetRelidCallback callback,
									 void *callback_arg);
extern Oid	RangeVarGetCreationNamespace(const RangeVar *newRelation);
extern Oid	RangeVarGetAndCheckCreationNamespace(RangeVar *newRelation,
												 LOCKMODE lockmode,
												 Oid *existing_relation_id);
extern void RangeVarAdjustRelationPersistence(RangeVar *newRelation, Oid nspid);
extern Oid	RelnameGetRelid(const char *relname);
extern bool RelationIsVisible(Oid relid);

extern Oid	TypenameGetTypid(const char *typname);
extern Oid	TypenameGetTypidExtended(const char *typname, bool temp_ok);
extern bool TypeIsVisible(Oid typid);

extern FuncCandidateList FuncnameGetCandidates(List *names,
											   int nargs, List *argnames,
											   bool expand_variadic,
											   bool expand_defaults,
											   bool include_out_arguments,
											   bool missing_ok);
extern bool FunctionIsVisible(Oid funcid);

extern Oid	OpernameGetOprid(List *names, Oid oprleft, Oid oprright);
extern FuncCandidateList OpernameGetCandidates(List *names, char oprkind,
											   bool missing_schema_ok);
extern bool OperatorIsVisible(Oid oprid);

extern Oid	OpclassnameGetOpcid(Oid amid, const char *opcname);
extern bool OpclassIsVisible(Oid opcid);

extern Oid	OpfamilynameGetOpfid(Oid amid, const char *opfname);
extern bool OpfamilyIsVisible(Oid opfid);

extern Oid	CollationGetCollid(const char *collname);
extern bool CollationIsVisible(Oid collid);

extern Oid	ConversionGetConid(const char *conname);
extern bool ConversionIsVisible(Oid conid);

extern Oid	get_statistics_object_oid(List *names, bool missing_ok);
extern bool StatisticsObjIsVisible(Oid relid);

extern Oid	get_ts_parser_oid(List *names, bool missing_ok);
extern bool TSParserIsVisible(Oid prsId);

extern Oid	get_ts_dict_oid(List *names, bool missing_ok);
extern bool TSDictionaryIsVisible(Oid dictId);

extern Oid	get_ts_template_oid(List *names, bool missing_ok);
extern bool TSTemplateIsVisible(Oid tmplId);

extern Oid	get_ts_config_oid(List *names, bool missing_ok);
extern bool TSConfigIsVisible(Oid cfgid);

extern void DeconstructQualifiedName(List *names,
									 char **nspname_p,
									 char **objname_p);
extern Oid	LookupNamespaceNoError(const char *nspname);
extern Oid	LookupExplicitNamespace(const char *nspname, bool missing_ok);
extern Oid	get_namespace_oid(const char *nspname, bool missing_ok);

extern Oid	LookupCreationNamespace(const char *nspname);
extern void CheckSetNamespace(Oid oldNspOid, Oid nspOid);
extern Oid	QualifiedNameGetCreationNamespace(List *names, char **objname_p);
extern RangeVar *makeRangeVarFromNameList(List *names);
extern char *NameListToString(List *names);
extern char *NameListToQuotedString(List *names);

extern bool isTempNamespace(Oid namespaceId);
extern bool isTempToastNamespace(Oid namespaceId);
extern bool isTempOrTempToastNamespace(Oid namespaceId);
extern bool isAnyTempNamespace(Oid namespaceId);
extern bool isOtherTempNamespace(Oid namespaceId);
extern TempNamespaceStatus checkTempNamespaceStatus(Oid namespaceId);
extern int	GetTempNamespaceBackendId(Oid namespaceId);
extern Oid	GetTempToastNamespace(void);
extern void GetTempNamespaceState(Oid *tempNamespaceId,
								  Oid *tempToastNamespaceId);
extern void SetTempNamespaceState(Oid tempNamespaceId,
								  Oid tempToastNamespaceId);
extern void ResetTempTableNamespace(void);

extern OverrideSearchPath *GetOverrideSearchPath(MemoryContext context);
extern OverrideSearchPath *CopyOverrideSearchPath(OverrideSearchPath *path);
extern bool OverrideSearchPathMatchesCurrent(OverrideSearchPath *path);
extern void PushOverrideSearchPath(OverrideSearchPath *newpath);
extern void PopOverrideSearchPath(void);

extern Oid	get_collation_oid(List *collname, bool missing_ok);
extern Oid	get_conversion_oid(List *conname, bool missing_ok);
extern Oid	FindDefaultConversionProc(int32 for_encoding, int32 to_encoding);


/* initialization & transaction cleanup code */
extern void InitializeSearchPath(void);
extern void AtEOXact_Namespace(bool isCommit, bool parallel);
extern void AtEOSubXact_Namespace(bool isCommit, SubTransactionId mySubid,
								  SubTransactionId parentSubid);

/* stuff for search_path GUC variable */
extern PGDLLIMPORT char *namespace_search_path;

extern List *fetch_search_path(bool includeImplicit);
extern int	fetch_search_path_array(Oid *sarray, int sarray_len);

#endif							/* NAMESPACE_H */
