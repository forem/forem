/*-------------------------------------------------------------------------
 *
 * defrem.h
 *	  POSTGRES define and remove utility definitions.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/defrem.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef DEFREM_H
#define DEFREM_H

#include "catalog/objectaddress.h"
#include "nodes/params.h"
#include "parser/parse_node.h"
#include "tcop/dest.h"
#include "utils/array.h"

/* commands/dropcmds.c */
extern void RemoveObjects(DropStmt *stmt);

/* commands/indexcmds.c */
extern ObjectAddress DefineIndex(Oid relationId,
								 IndexStmt *stmt,
								 Oid indexRelationId,
								 Oid parentIndexId,
								 Oid parentConstraintId,
								 bool is_alter_table,
								 bool check_rights,
								 bool check_not_in_use,
								 bool skip_build,
								 bool quiet);
extern void ExecReindex(ParseState *pstate, ReindexStmt *stmt, bool isTopLevel);
extern char *makeObjectName(const char *name1, const char *name2,
							const char *label);
extern char *ChooseRelationName(const char *name1, const char *name2,
								const char *label, Oid namespaceid,
								bool isconstraint);
extern bool CheckIndexCompatible(Oid oldId,
								 const char *accessMethodName,
								 List *attributeList,
								 List *exclusionOpNames);
extern Oid	GetDefaultOpClass(Oid type_id, Oid am_id);
extern Oid	ResolveOpClass(List *opclass, Oid attrType,
						   const char *accessMethodName, Oid accessMethodId);

/* commands/functioncmds.c */
extern ObjectAddress CreateFunction(ParseState *pstate, CreateFunctionStmt *stmt);
extern void RemoveFunctionById(Oid funcOid);
extern ObjectAddress AlterFunction(ParseState *pstate, AlterFunctionStmt *stmt);
extern ObjectAddress CreateCast(CreateCastStmt *stmt);
extern ObjectAddress CreateTransform(CreateTransformStmt *stmt);
extern void IsThereFunctionInNamespace(const char *proname, int pronargs,
									   oidvector *proargtypes, Oid nspOid);
extern void ExecuteDoStmt(ParseState *pstate, DoStmt *stmt, bool atomic);
extern void ExecuteCallStmt(CallStmt *stmt, ParamListInfo params, bool atomic, DestReceiver *dest);
extern TupleDesc CallStmtResultDesc(CallStmt *stmt);
extern Oid	get_transform_oid(Oid type_id, Oid lang_id, bool missing_ok);
extern void interpret_function_parameter_list(ParseState *pstate,
											  List *parameters,
											  Oid languageOid,
											  ObjectType objtype,
											  oidvector **parameterTypes,
											  List **parameterTypes_list,
											  ArrayType **allParameterTypes,
											  ArrayType **parameterModes,
											  ArrayType **parameterNames,
											  List **inParameterNames_list,
											  List **parameterDefaults,
											  Oid *variadicArgType,
											  Oid *requiredResultType);

/* commands/operatorcmds.c */
extern ObjectAddress DefineOperator(List *names, List *parameters);
extern void RemoveOperatorById(Oid operOid);
extern ObjectAddress AlterOperator(AlterOperatorStmt *stmt);

/* commands/statscmds.c */
extern ObjectAddress CreateStatistics(CreateStatsStmt *stmt);
extern ObjectAddress AlterStatistics(AlterStatsStmt *stmt);
extern void RemoveStatisticsById(Oid statsOid);
extern void RemoveStatisticsDataById(Oid statsOid, bool inh);
extern Oid	StatisticsGetRelation(Oid statId, bool missing_ok);

/* commands/aggregatecmds.c */
extern ObjectAddress DefineAggregate(ParseState *pstate, List *name, List *args, bool oldstyle,
									 List *parameters, bool replace);

/* commands/opclasscmds.c */
extern ObjectAddress DefineOpClass(CreateOpClassStmt *stmt);
extern ObjectAddress DefineOpFamily(CreateOpFamilyStmt *stmt);
extern Oid	AlterOpFamily(AlterOpFamilyStmt *stmt);
extern void IsThereOpClassInNamespace(const char *opcname, Oid opcmethod,
									  Oid opcnamespace);
extern void IsThereOpFamilyInNamespace(const char *opfname, Oid opfmethod,
									   Oid opfnamespace);
extern Oid	get_opclass_oid(Oid amID, List *opclassname, bool missing_ok);
extern Oid	get_opfamily_oid(Oid amID, List *opfamilyname, bool missing_ok);

/* commands/tsearchcmds.c */
extern ObjectAddress DefineTSParser(List *names, List *parameters);

extern ObjectAddress DefineTSDictionary(List *names, List *parameters);
extern ObjectAddress AlterTSDictionary(AlterTSDictionaryStmt *stmt);

extern ObjectAddress DefineTSTemplate(List *names, List *parameters);

extern ObjectAddress DefineTSConfiguration(List *names, List *parameters,
										   ObjectAddress *copied);
extern void RemoveTSConfigurationById(Oid cfgId);
extern ObjectAddress AlterTSConfiguration(AlterTSConfigurationStmt *stmt);

extern text *serialize_deflist(List *deflist);
extern List *deserialize_deflist(Datum txt);

/* commands/foreigncmds.c */
extern ObjectAddress AlterForeignServerOwner(const char *name, Oid newOwnerId);
extern void AlterForeignServerOwner_oid(Oid, Oid newOwnerId);
extern ObjectAddress AlterForeignDataWrapperOwner(const char *name, Oid newOwnerId);
extern void AlterForeignDataWrapperOwner_oid(Oid fwdId, Oid newOwnerId);
extern ObjectAddress CreateForeignDataWrapper(ParseState *pstate, CreateFdwStmt *stmt);
extern ObjectAddress AlterForeignDataWrapper(ParseState *pstate, AlterFdwStmt *stmt);
extern ObjectAddress CreateForeignServer(CreateForeignServerStmt *stmt);
extern ObjectAddress AlterForeignServer(AlterForeignServerStmt *stmt);
extern ObjectAddress CreateUserMapping(CreateUserMappingStmt *stmt);
extern ObjectAddress AlterUserMapping(AlterUserMappingStmt *stmt);
extern Oid	RemoveUserMapping(DropUserMappingStmt *stmt);
extern void CreateForeignTable(CreateForeignTableStmt *stmt, Oid relid);
extern void ImportForeignSchema(ImportForeignSchemaStmt *stmt);
extern Datum transformGenericOptions(Oid catalogId,
									 Datum oldOptions,
									 List *options,
									 Oid fdwvalidator);

/* commands/amcmds.c */
extern ObjectAddress CreateAccessMethod(CreateAmStmt *stmt);
extern Oid	get_index_am_oid(const char *amname, bool missing_ok);
extern Oid	get_table_am_oid(const char *amname, bool missing_ok);
extern Oid	get_am_oid(const char *amname, bool missing_ok);
extern char *get_am_name(Oid amOid);

/* support routines in commands/define.c */

extern char *defGetString(DefElem *def);
extern double defGetNumeric(DefElem *def);
extern bool defGetBoolean(DefElem *def);
extern int32 defGetInt32(DefElem *def);
extern int64 defGetInt64(DefElem *def);
extern Oid	defGetObjectId(DefElem *def);
extern List *defGetQualifiedName(DefElem *def);
extern TypeName *defGetTypeName(DefElem *def);
extern int	defGetTypeLength(DefElem *def);
extern List *defGetStringList(DefElem *def);
extern void errorConflictingDefElem(DefElem *defel, ParseState *pstate) pg_attribute_noreturn();

#endif							/* DEFREM_H */
