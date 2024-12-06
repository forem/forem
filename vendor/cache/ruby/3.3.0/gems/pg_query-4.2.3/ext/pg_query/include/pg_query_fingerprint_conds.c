case T_Alias:
  // Intentionally ignoring for fingerprinting
  break;
case T_RangeVar:
  _fingerprintString(ctx, "RangeVar");
  _fingerprintRangeVar(ctx, obj, parent, field_name, depth);
  break;
case T_TableFunc:
  _fingerprintString(ctx, "TableFunc");
  _fingerprintTableFunc(ctx, obj, parent, field_name, depth);
  break;
case T_Var:
  _fingerprintString(ctx, "Var");
  _fingerprintVar(ctx, obj, parent, field_name, depth);
  break;
case T_Const:
  _fingerprintString(ctx, "Const");
  _fingerprintConst(ctx, obj, parent, field_name, depth);
  break;
case T_Param:
  _fingerprintString(ctx, "Param");
  _fingerprintParam(ctx, obj, parent, field_name, depth);
  break;
case T_Aggref:
  _fingerprintString(ctx, "Aggref");
  _fingerprintAggref(ctx, obj, parent, field_name, depth);
  break;
case T_GroupingFunc:
  _fingerprintString(ctx, "GroupingFunc");
  _fingerprintGroupingFunc(ctx, obj, parent, field_name, depth);
  break;
case T_WindowFunc:
  _fingerprintString(ctx, "WindowFunc");
  _fingerprintWindowFunc(ctx, obj, parent, field_name, depth);
  break;
case T_SubscriptingRef:
  _fingerprintString(ctx, "SubscriptingRef");
  _fingerprintSubscriptingRef(ctx, obj, parent, field_name, depth);
  break;
case T_FuncExpr:
  _fingerprintString(ctx, "FuncExpr");
  _fingerprintFuncExpr(ctx, obj, parent, field_name, depth);
  break;
case T_NamedArgExpr:
  _fingerprintString(ctx, "NamedArgExpr");
  _fingerprintNamedArgExpr(ctx, obj, parent, field_name, depth);
  break;
case T_OpExpr:
  _fingerprintString(ctx, "OpExpr");
  _fingerprintOpExpr(ctx, obj, parent, field_name, depth);
  break;
case T_ScalarArrayOpExpr:
  _fingerprintString(ctx, "ScalarArrayOpExpr");
  _fingerprintScalarArrayOpExpr(ctx, obj, parent, field_name, depth);
  break;
case T_BoolExpr:
  _fingerprintString(ctx, "BoolExpr");
  _fingerprintBoolExpr(ctx, obj, parent, field_name, depth);
  break;
case T_SubLink:
  _fingerprintString(ctx, "SubLink");
  _fingerprintSubLink(ctx, obj, parent, field_name, depth);
  break;
case T_SubPlan:
  _fingerprintString(ctx, "SubPlan");
  _fingerprintSubPlan(ctx, obj, parent, field_name, depth);
  break;
case T_AlternativeSubPlan:
  _fingerprintString(ctx, "AlternativeSubPlan");
  _fingerprintAlternativeSubPlan(ctx, obj, parent, field_name, depth);
  break;
case T_FieldSelect:
  _fingerprintString(ctx, "FieldSelect");
  _fingerprintFieldSelect(ctx, obj, parent, field_name, depth);
  break;
case T_FieldStore:
  _fingerprintString(ctx, "FieldStore");
  _fingerprintFieldStore(ctx, obj, parent, field_name, depth);
  break;
case T_RelabelType:
  _fingerprintString(ctx, "RelabelType");
  _fingerprintRelabelType(ctx, obj, parent, field_name, depth);
  break;
case T_CoerceViaIO:
  _fingerprintString(ctx, "CoerceViaIO");
  _fingerprintCoerceViaIO(ctx, obj, parent, field_name, depth);
  break;
case T_ArrayCoerceExpr:
  _fingerprintString(ctx, "ArrayCoerceExpr");
  _fingerprintArrayCoerceExpr(ctx, obj, parent, field_name, depth);
  break;
case T_ConvertRowtypeExpr:
  _fingerprintString(ctx, "ConvertRowtypeExpr");
  _fingerprintConvertRowtypeExpr(ctx, obj, parent, field_name, depth);
  break;
case T_CollateExpr:
  _fingerprintString(ctx, "CollateExpr");
  _fingerprintCollateExpr(ctx, obj, parent, field_name, depth);
  break;
case T_CaseExpr:
  _fingerprintString(ctx, "CaseExpr");
  _fingerprintCaseExpr(ctx, obj, parent, field_name, depth);
  break;
case T_CaseWhen:
  _fingerprintString(ctx, "CaseWhen");
  _fingerprintCaseWhen(ctx, obj, parent, field_name, depth);
  break;
case T_CaseTestExpr:
  _fingerprintString(ctx, "CaseTestExpr");
  _fingerprintCaseTestExpr(ctx, obj, parent, field_name, depth);
  break;
case T_ArrayExpr:
  _fingerprintString(ctx, "ArrayExpr");
  _fingerprintArrayExpr(ctx, obj, parent, field_name, depth);
  break;
case T_RowExpr:
  _fingerprintString(ctx, "RowExpr");
  _fingerprintRowExpr(ctx, obj, parent, field_name, depth);
  break;
case T_RowCompareExpr:
  _fingerprintString(ctx, "RowCompareExpr");
  _fingerprintRowCompareExpr(ctx, obj, parent, field_name, depth);
  break;
case T_CoalesceExpr:
  _fingerprintString(ctx, "CoalesceExpr");
  _fingerprintCoalesceExpr(ctx, obj, parent, field_name, depth);
  break;
case T_MinMaxExpr:
  _fingerprintString(ctx, "MinMaxExpr");
  _fingerprintMinMaxExpr(ctx, obj, parent, field_name, depth);
  break;
case T_SQLValueFunction:
  _fingerprintString(ctx, "SQLValueFunction");
  _fingerprintSQLValueFunction(ctx, obj, parent, field_name, depth);
  break;
case T_XmlExpr:
  _fingerprintString(ctx, "XmlExpr");
  _fingerprintXmlExpr(ctx, obj, parent, field_name, depth);
  break;
case T_NullTest:
  _fingerprintString(ctx, "NullTest");
  _fingerprintNullTest(ctx, obj, parent, field_name, depth);
  break;
case T_BooleanTest:
  _fingerprintString(ctx, "BooleanTest");
  _fingerprintBooleanTest(ctx, obj, parent, field_name, depth);
  break;
case T_CoerceToDomain:
  _fingerprintString(ctx, "CoerceToDomain");
  _fingerprintCoerceToDomain(ctx, obj, parent, field_name, depth);
  break;
case T_CoerceToDomainValue:
  _fingerprintString(ctx, "CoerceToDomainValue");
  _fingerprintCoerceToDomainValue(ctx, obj, parent, field_name, depth);
  break;
case T_SetToDefault:
  // Intentionally ignoring for fingerprinting
  break;
case T_CurrentOfExpr:
  _fingerprintString(ctx, "CurrentOfExpr");
  _fingerprintCurrentOfExpr(ctx, obj, parent, field_name, depth);
  break;
case T_NextValueExpr:
  _fingerprintString(ctx, "NextValueExpr");
  _fingerprintNextValueExpr(ctx, obj, parent, field_name, depth);
  break;
case T_InferenceElem:
  _fingerprintString(ctx, "InferenceElem");
  _fingerprintInferenceElem(ctx, obj, parent, field_name, depth);
  break;
case T_TargetEntry:
  _fingerprintString(ctx, "TargetEntry");
  _fingerprintTargetEntry(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTblRef:
  _fingerprintString(ctx, "RangeTblRef");
  _fingerprintRangeTblRef(ctx, obj, parent, field_name, depth);
  break;
case T_JoinExpr:
  _fingerprintString(ctx, "JoinExpr");
  _fingerprintJoinExpr(ctx, obj, parent, field_name, depth);
  break;
case T_FromExpr:
  _fingerprintString(ctx, "FromExpr");
  _fingerprintFromExpr(ctx, obj, parent, field_name, depth);
  break;
case T_OnConflictExpr:
  _fingerprintString(ctx, "OnConflictExpr");
  _fingerprintOnConflictExpr(ctx, obj, parent, field_name, depth);
  break;
case T_IntoClause:
  _fingerprintString(ctx, "IntoClause");
  _fingerprintIntoClause(ctx, obj, parent, field_name, depth);
  break;
case T_MergeAction:
  _fingerprintString(ctx, "MergeAction");
  _fingerprintMergeAction(ctx, obj, parent, field_name, depth);
  break;
case T_RawStmt:
  _fingerprintString(ctx, "RawStmt");
  _fingerprintRawStmt(ctx, obj, parent, field_name, depth);
  break;
case T_Query:
  _fingerprintString(ctx, "Query");
  _fingerprintQuery(ctx, obj, parent, field_name, depth);
  break;
case T_InsertStmt:
  _fingerprintString(ctx, "InsertStmt");
  _fingerprintInsertStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DeleteStmt:
  _fingerprintString(ctx, "DeleteStmt");
  _fingerprintDeleteStmt(ctx, obj, parent, field_name, depth);
  break;
case T_UpdateStmt:
  _fingerprintString(ctx, "UpdateStmt");
  _fingerprintUpdateStmt(ctx, obj, parent, field_name, depth);
  break;
case T_MergeStmt:
  _fingerprintString(ctx, "MergeStmt");
  _fingerprintMergeStmt(ctx, obj, parent, field_name, depth);
  break;
case T_SelectStmt:
  _fingerprintString(ctx, "SelectStmt");
  _fingerprintSelectStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ReturnStmt:
  _fingerprintString(ctx, "ReturnStmt");
  _fingerprintReturnStmt(ctx, obj, parent, field_name, depth);
  break;
case T_PLAssignStmt:
  _fingerprintString(ctx, "PLAssignStmt");
  _fingerprintPLAssignStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTableStmt:
  _fingerprintString(ctx, "AlterTableStmt");
  _fingerprintAlterTableStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTableCmd:
  _fingerprintString(ctx, "AlterTableCmd");
  _fingerprintAlterTableCmd(ctx, obj, parent, field_name, depth);
  break;
case T_AlterDomainStmt:
  _fingerprintString(ctx, "AlterDomainStmt");
  _fingerprintAlterDomainStmt(ctx, obj, parent, field_name, depth);
  break;
case T_SetOperationStmt:
  _fingerprintString(ctx, "SetOperationStmt");
  _fingerprintSetOperationStmt(ctx, obj, parent, field_name, depth);
  break;
case T_GrantStmt:
  _fingerprintString(ctx, "GrantStmt");
  _fingerprintGrantStmt(ctx, obj, parent, field_name, depth);
  break;
case T_GrantRoleStmt:
  _fingerprintString(ctx, "GrantRoleStmt");
  _fingerprintGrantRoleStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterDefaultPrivilegesStmt:
  _fingerprintString(ctx, "AlterDefaultPrivilegesStmt");
  _fingerprintAlterDefaultPrivilegesStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ClosePortalStmt:
  _fingerprintString(ctx, "ClosePortalStmt");
  _fingerprintClosePortalStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ClusterStmt:
  _fingerprintString(ctx, "ClusterStmt");
  _fingerprintClusterStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CopyStmt:
  _fingerprintString(ctx, "CopyStmt");
  _fingerprintCopyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateStmt:
  _fingerprintString(ctx, "CreateStmt");
  _fingerprintCreateStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DefineStmt:
  _fingerprintString(ctx, "DefineStmt");
  _fingerprintDefineStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropStmt:
  _fingerprintString(ctx, "DropStmt");
  _fingerprintDropStmt(ctx, obj, parent, field_name, depth);
  break;
case T_TruncateStmt:
  _fingerprintString(ctx, "TruncateStmt");
  _fingerprintTruncateStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CommentStmt:
  _fingerprintString(ctx, "CommentStmt");
  _fingerprintCommentStmt(ctx, obj, parent, field_name, depth);
  break;
case T_FetchStmt:
  _fingerprintString(ctx, "FetchStmt");
  _fingerprintFetchStmt(ctx, obj, parent, field_name, depth);
  break;
case T_IndexStmt:
  _fingerprintString(ctx, "IndexStmt");
  _fingerprintIndexStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateFunctionStmt:
  _fingerprintString(ctx, "CreateFunctionStmt");
  _fingerprintCreateFunctionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterFunctionStmt:
  _fingerprintString(ctx, "AlterFunctionStmt");
  _fingerprintAlterFunctionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DoStmt:
  _fingerprintString(ctx, "DoStmt");
  _fingerprintDoStmt(ctx, obj, parent, field_name, depth);
  break;
case T_RenameStmt:
  _fingerprintString(ctx, "RenameStmt");
  _fingerprintRenameStmt(ctx, obj, parent, field_name, depth);
  break;
case T_RuleStmt:
  _fingerprintString(ctx, "RuleStmt");
  _fingerprintRuleStmt(ctx, obj, parent, field_name, depth);
  break;
case T_NotifyStmt:
  _fingerprintString(ctx, "NotifyStmt");
  _fingerprintNotifyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ListenStmt:
  _fingerprintString(ctx, "ListenStmt");
  _fingerprintListenStmt(ctx, obj, parent, field_name, depth);
  break;
case T_UnlistenStmt:
  _fingerprintString(ctx, "UnlistenStmt");
  _fingerprintUnlistenStmt(ctx, obj, parent, field_name, depth);
  break;
case T_TransactionStmt:
  _fingerprintString(ctx, "TransactionStmt");
  _fingerprintTransactionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ViewStmt:
  _fingerprintString(ctx, "ViewStmt");
  _fingerprintViewStmt(ctx, obj, parent, field_name, depth);
  break;
case T_LoadStmt:
  _fingerprintString(ctx, "LoadStmt");
  _fingerprintLoadStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateDomainStmt:
  _fingerprintString(ctx, "CreateDomainStmt");
  _fingerprintCreateDomainStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreatedbStmt:
  _fingerprintString(ctx, "CreatedbStmt");
  _fingerprintCreatedbStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropdbStmt:
  _fingerprintString(ctx, "DropdbStmt");
  _fingerprintDropdbStmt(ctx, obj, parent, field_name, depth);
  break;
case T_VacuumStmt:
  _fingerprintString(ctx, "VacuumStmt");
  _fingerprintVacuumStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ExplainStmt:
  _fingerprintString(ctx, "ExplainStmt");
  _fingerprintExplainStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateTableAsStmt:
  _fingerprintString(ctx, "CreateTableAsStmt");
  _fingerprintCreateTableAsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateSeqStmt:
  _fingerprintString(ctx, "CreateSeqStmt");
  _fingerprintCreateSeqStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterSeqStmt:
  _fingerprintString(ctx, "AlterSeqStmt");
  _fingerprintAlterSeqStmt(ctx, obj, parent, field_name, depth);
  break;
case T_VariableSetStmt:
  _fingerprintString(ctx, "VariableSetStmt");
  _fingerprintVariableSetStmt(ctx, obj, parent, field_name, depth);
  break;
case T_VariableShowStmt:
  _fingerprintString(ctx, "VariableShowStmt");
  _fingerprintVariableShowStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DiscardStmt:
  _fingerprintString(ctx, "DiscardStmt");
  _fingerprintDiscardStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateTrigStmt:
  _fingerprintString(ctx, "CreateTrigStmt");
  _fingerprintCreateTrigStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreatePLangStmt:
  _fingerprintString(ctx, "CreatePLangStmt");
  _fingerprintCreatePLangStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateRoleStmt:
  _fingerprintString(ctx, "CreateRoleStmt");
  _fingerprintCreateRoleStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterRoleStmt:
  _fingerprintString(ctx, "AlterRoleStmt");
  _fingerprintAlterRoleStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropRoleStmt:
  _fingerprintString(ctx, "DropRoleStmt");
  _fingerprintDropRoleStmt(ctx, obj, parent, field_name, depth);
  break;
case T_LockStmt:
  _fingerprintString(ctx, "LockStmt");
  _fingerprintLockStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ConstraintsSetStmt:
  _fingerprintString(ctx, "ConstraintsSetStmt");
  _fingerprintConstraintsSetStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ReindexStmt:
  _fingerprintString(ctx, "ReindexStmt");
  _fingerprintReindexStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CheckPointStmt:
  _fingerprintString(ctx, "CheckPointStmt");
  _fingerprintCheckPointStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateSchemaStmt:
  _fingerprintString(ctx, "CreateSchemaStmt");
  _fingerprintCreateSchemaStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterDatabaseStmt:
  _fingerprintString(ctx, "AlterDatabaseStmt");
  _fingerprintAlterDatabaseStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterDatabaseRefreshCollStmt:
  _fingerprintString(ctx, "AlterDatabaseRefreshCollStmt");
  _fingerprintAlterDatabaseRefreshCollStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterDatabaseSetStmt:
  _fingerprintString(ctx, "AlterDatabaseSetStmt");
  _fingerprintAlterDatabaseSetStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterRoleSetStmt:
  _fingerprintString(ctx, "AlterRoleSetStmt");
  _fingerprintAlterRoleSetStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateConversionStmt:
  _fingerprintString(ctx, "CreateConversionStmt");
  _fingerprintCreateConversionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateCastStmt:
  _fingerprintString(ctx, "CreateCastStmt");
  _fingerprintCreateCastStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateOpClassStmt:
  _fingerprintString(ctx, "CreateOpClassStmt");
  _fingerprintCreateOpClassStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateOpFamilyStmt:
  _fingerprintString(ctx, "CreateOpFamilyStmt");
  _fingerprintCreateOpFamilyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterOpFamilyStmt:
  _fingerprintString(ctx, "AlterOpFamilyStmt");
  _fingerprintAlterOpFamilyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_PrepareStmt:
  _fingerprintString(ctx, "PrepareStmt");
  _fingerprintPrepareStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ExecuteStmt:
  _fingerprintString(ctx, "ExecuteStmt");
  _fingerprintExecuteStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DeallocateStmt:
  _fingerprintString(ctx, "DeallocateStmt");
  _fingerprintDeallocateStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DeclareCursorStmt:
  _fingerprintString(ctx, "DeclareCursorStmt");
  _fingerprintDeclareCursorStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateTableSpaceStmt:
  _fingerprintString(ctx, "CreateTableSpaceStmt");
  _fingerprintCreateTableSpaceStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropTableSpaceStmt:
  _fingerprintString(ctx, "DropTableSpaceStmt");
  _fingerprintDropTableSpaceStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterObjectDependsStmt:
  _fingerprintString(ctx, "AlterObjectDependsStmt");
  _fingerprintAlterObjectDependsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterObjectSchemaStmt:
  _fingerprintString(ctx, "AlterObjectSchemaStmt");
  _fingerprintAlterObjectSchemaStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterOwnerStmt:
  _fingerprintString(ctx, "AlterOwnerStmt");
  _fingerprintAlterOwnerStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterOperatorStmt:
  _fingerprintString(ctx, "AlterOperatorStmt");
  _fingerprintAlterOperatorStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTypeStmt:
  _fingerprintString(ctx, "AlterTypeStmt");
  _fingerprintAlterTypeStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropOwnedStmt:
  _fingerprintString(ctx, "DropOwnedStmt");
  _fingerprintDropOwnedStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ReassignOwnedStmt:
  _fingerprintString(ctx, "ReassignOwnedStmt");
  _fingerprintReassignOwnedStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CompositeTypeStmt:
  _fingerprintString(ctx, "CompositeTypeStmt");
  _fingerprintCompositeTypeStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateEnumStmt:
  _fingerprintString(ctx, "CreateEnumStmt");
  _fingerprintCreateEnumStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateRangeStmt:
  _fingerprintString(ctx, "CreateRangeStmt");
  _fingerprintCreateRangeStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterEnumStmt:
  _fingerprintString(ctx, "AlterEnumStmt");
  _fingerprintAlterEnumStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTSDictionaryStmt:
  _fingerprintString(ctx, "AlterTSDictionaryStmt");
  _fingerprintAlterTSDictionaryStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTSConfigurationStmt:
  _fingerprintString(ctx, "AlterTSConfigurationStmt");
  _fingerprintAlterTSConfigurationStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateFdwStmt:
  _fingerprintString(ctx, "CreateFdwStmt");
  _fingerprintCreateFdwStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterFdwStmt:
  _fingerprintString(ctx, "AlterFdwStmt");
  _fingerprintAlterFdwStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateForeignServerStmt:
  _fingerprintString(ctx, "CreateForeignServerStmt");
  _fingerprintCreateForeignServerStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterForeignServerStmt:
  _fingerprintString(ctx, "AlterForeignServerStmt");
  _fingerprintAlterForeignServerStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateUserMappingStmt:
  _fingerprintString(ctx, "CreateUserMappingStmt");
  _fingerprintCreateUserMappingStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterUserMappingStmt:
  _fingerprintString(ctx, "AlterUserMappingStmt");
  _fingerprintAlterUserMappingStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropUserMappingStmt:
  _fingerprintString(ctx, "DropUserMappingStmt");
  _fingerprintDropUserMappingStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTableSpaceOptionsStmt:
  _fingerprintString(ctx, "AlterTableSpaceOptionsStmt");
  _fingerprintAlterTableSpaceOptionsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterTableMoveAllStmt:
  _fingerprintString(ctx, "AlterTableMoveAllStmt");
  _fingerprintAlterTableMoveAllStmt(ctx, obj, parent, field_name, depth);
  break;
case T_SecLabelStmt:
  _fingerprintString(ctx, "SecLabelStmt");
  _fingerprintSecLabelStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateForeignTableStmt:
  _fingerprintString(ctx, "CreateForeignTableStmt");
  _fingerprintCreateForeignTableStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ImportForeignSchemaStmt:
  _fingerprintString(ctx, "ImportForeignSchemaStmt");
  _fingerprintImportForeignSchemaStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateExtensionStmt:
  _fingerprintString(ctx, "CreateExtensionStmt");
  _fingerprintCreateExtensionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterExtensionStmt:
  _fingerprintString(ctx, "AlterExtensionStmt");
  _fingerprintAlterExtensionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterExtensionContentsStmt:
  _fingerprintString(ctx, "AlterExtensionContentsStmt");
  _fingerprintAlterExtensionContentsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateEventTrigStmt:
  _fingerprintString(ctx, "CreateEventTrigStmt");
  _fingerprintCreateEventTrigStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterEventTrigStmt:
  _fingerprintString(ctx, "AlterEventTrigStmt");
  _fingerprintAlterEventTrigStmt(ctx, obj, parent, field_name, depth);
  break;
case T_RefreshMatViewStmt:
  _fingerprintString(ctx, "RefreshMatViewStmt");
  _fingerprintRefreshMatViewStmt(ctx, obj, parent, field_name, depth);
  break;
case T_ReplicaIdentityStmt:
  _fingerprintString(ctx, "ReplicaIdentityStmt");
  _fingerprintReplicaIdentityStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterSystemStmt:
  _fingerprintString(ctx, "AlterSystemStmt");
  _fingerprintAlterSystemStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreatePolicyStmt:
  _fingerprintString(ctx, "CreatePolicyStmt");
  _fingerprintCreatePolicyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterPolicyStmt:
  _fingerprintString(ctx, "AlterPolicyStmt");
  _fingerprintAlterPolicyStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateTransformStmt:
  _fingerprintString(ctx, "CreateTransformStmt");
  _fingerprintCreateTransformStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateAmStmt:
  _fingerprintString(ctx, "CreateAmStmt");
  _fingerprintCreateAmStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreatePublicationStmt:
  _fingerprintString(ctx, "CreatePublicationStmt");
  _fingerprintCreatePublicationStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterPublicationStmt:
  _fingerprintString(ctx, "AlterPublicationStmt");
  _fingerprintAlterPublicationStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateSubscriptionStmt:
  _fingerprintString(ctx, "CreateSubscriptionStmt");
  _fingerprintCreateSubscriptionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterSubscriptionStmt:
  _fingerprintString(ctx, "AlterSubscriptionStmt");
  _fingerprintAlterSubscriptionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_DropSubscriptionStmt:
  _fingerprintString(ctx, "DropSubscriptionStmt");
  _fingerprintDropSubscriptionStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CreateStatsStmt:
  _fingerprintString(ctx, "CreateStatsStmt");
  _fingerprintCreateStatsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterCollationStmt:
  _fingerprintString(ctx, "AlterCollationStmt");
  _fingerprintAlterCollationStmt(ctx, obj, parent, field_name, depth);
  break;
case T_CallStmt:
  _fingerprintString(ctx, "CallStmt");
  _fingerprintCallStmt(ctx, obj, parent, field_name, depth);
  break;
case T_AlterStatsStmt:
  _fingerprintString(ctx, "AlterStatsStmt");
  _fingerprintAlterStatsStmt(ctx, obj, parent, field_name, depth);
  break;
case T_A_Expr:
  _fingerprintString(ctx, "A_Expr");
  _fingerprintA_Expr(ctx, obj, parent, field_name, depth);
  break;
case T_ColumnRef:
  _fingerprintString(ctx, "ColumnRef");
  _fingerprintColumnRef(ctx, obj, parent, field_name, depth);
  break;
case T_ParamRef:
  // Intentionally ignoring for fingerprinting
  break;
case T_FuncCall:
  _fingerprintString(ctx, "FuncCall");
  _fingerprintFuncCall(ctx, obj, parent, field_name, depth);
  break;
case T_A_Star:
  _fingerprintString(ctx, "A_Star");
  _fingerprintA_Star(ctx, obj, parent, field_name, depth);
  break;
case T_A_Indices:
  _fingerprintString(ctx, "A_Indices");
  _fingerprintA_Indices(ctx, obj, parent, field_name, depth);
  break;
case T_A_Indirection:
  _fingerprintString(ctx, "A_Indirection");
  _fingerprintA_Indirection(ctx, obj, parent, field_name, depth);
  break;
case T_A_ArrayExpr:
  _fingerprintString(ctx, "A_ArrayExpr");
  _fingerprintA_ArrayExpr(ctx, obj, parent, field_name, depth);
  break;
case T_ResTarget:
  _fingerprintString(ctx, "ResTarget");
  _fingerprintResTarget(ctx, obj, parent, field_name, depth);
  break;
case T_MultiAssignRef:
  _fingerprintString(ctx, "MultiAssignRef");
  _fingerprintMultiAssignRef(ctx, obj, parent, field_name, depth);
  break;
case T_TypeCast:
  if (!IsA(castNode(TypeCast, (void*) obj)->arg, A_Const) && !IsA(castNode(TypeCast, (void*) obj)->arg, ParamRef))
  {
  _fingerprintString(ctx, "TypeCast");
  _fingerprintTypeCast(ctx, obj, parent, field_name, depth);
  }
  break;
case T_CollateClause:
  _fingerprintString(ctx, "CollateClause");
  _fingerprintCollateClause(ctx, obj, parent, field_name, depth);
  break;
case T_SortBy:
  _fingerprintString(ctx, "SortBy");
  _fingerprintSortBy(ctx, obj, parent, field_name, depth);
  break;
case T_WindowDef:
  _fingerprintString(ctx, "WindowDef");
  _fingerprintWindowDef(ctx, obj, parent, field_name, depth);
  break;
case T_RangeSubselect:
  _fingerprintString(ctx, "RangeSubselect");
  _fingerprintRangeSubselect(ctx, obj, parent, field_name, depth);
  break;
case T_RangeFunction:
  _fingerprintString(ctx, "RangeFunction");
  _fingerprintRangeFunction(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTableSample:
  _fingerprintString(ctx, "RangeTableSample");
  _fingerprintRangeTableSample(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTableFunc:
  _fingerprintString(ctx, "RangeTableFunc");
  _fingerprintRangeTableFunc(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTableFuncCol:
  _fingerprintString(ctx, "RangeTableFuncCol");
  _fingerprintRangeTableFuncCol(ctx, obj, parent, field_name, depth);
  break;
case T_TypeName:
  _fingerprintString(ctx, "TypeName");
  _fingerprintTypeName(ctx, obj, parent, field_name, depth);
  break;
case T_ColumnDef:
  _fingerprintString(ctx, "ColumnDef");
  _fingerprintColumnDef(ctx, obj, parent, field_name, depth);
  break;
case T_IndexElem:
  _fingerprintString(ctx, "IndexElem");
  _fingerprintIndexElem(ctx, obj, parent, field_name, depth);
  break;
case T_StatsElem:
  _fingerprintString(ctx, "StatsElem");
  _fingerprintStatsElem(ctx, obj, parent, field_name, depth);
  break;
case T_Constraint:
  _fingerprintString(ctx, "Constraint");
  _fingerprintConstraint(ctx, obj, parent, field_name, depth);
  break;
case T_DefElem:
  _fingerprintString(ctx, "DefElem");
  _fingerprintDefElem(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTblEntry:
  _fingerprintString(ctx, "RangeTblEntry");
  _fingerprintRangeTblEntry(ctx, obj, parent, field_name, depth);
  break;
case T_RangeTblFunction:
  _fingerprintString(ctx, "RangeTblFunction");
  _fingerprintRangeTblFunction(ctx, obj, parent, field_name, depth);
  break;
case T_TableSampleClause:
  _fingerprintString(ctx, "TableSampleClause");
  _fingerprintTableSampleClause(ctx, obj, parent, field_name, depth);
  break;
case T_WithCheckOption:
  _fingerprintString(ctx, "WithCheckOption");
  _fingerprintWithCheckOption(ctx, obj, parent, field_name, depth);
  break;
case T_SortGroupClause:
  _fingerprintString(ctx, "SortGroupClause");
  _fingerprintSortGroupClause(ctx, obj, parent, field_name, depth);
  break;
case T_GroupingSet:
  _fingerprintString(ctx, "GroupingSet");
  _fingerprintGroupingSet(ctx, obj, parent, field_name, depth);
  break;
case T_WindowClause:
  _fingerprintString(ctx, "WindowClause");
  _fingerprintWindowClause(ctx, obj, parent, field_name, depth);
  break;
case T_ObjectWithArgs:
  _fingerprintString(ctx, "ObjectWithArgs");
  _fingerprintObjectWithArgs(ctx, obj, parent, field_name, depth);
  break;
case T_AccessPriv:
  _fingerprintString(ctx, "AccessPriv");
  _fingerprintAccessPriv(ctx, obj, parent, field_name, depth);
  break;
case T_CreateOpClassItem:
  _fingerprintString(ctx, "CreateOpClassItem");
  _fingerprintCreateOpClassItem(ctx, obj, parent, field_name, depth);
  break;
case T_TableLikeClause:
  _fingerprintString(ctx, "TableLikeClause");
  _fingerprintTableLikeClause(ctx, obj, parent, field_name, depth);
  break;
case T_FunctionParameter:
  _fingerprintString(ctx, "FunctionParameter");
  _fingerprintFunctionParameter(ctx, obj, parent, field_name, depth);
  break;
case T_LockingClause:
  _fingerprintString(ctx, "LockingClause");
  _fingerprintLockingClause(ctx, obj, parent, field_name, depth);
  break;
case T_RowMarkClause:
  _fingerprintString(ctx, "RowMarkClause");
  _fingerprintRowMarkClause(ctx, obj, parent, field_name, depth);
  break;
case T_XmlSerialize:
  _fingerprintString(ctx, "XmlSerialize");
  _fingerprintXmlSerialize(ctx, obj, parent, field_name, depth);
  break;
case T_WithClause:
  _fingerprintString(ctx, "WithClause");
  _fingerprintWithClause(ctx, obj, parent, field_name, depth);
  break;
case T_InferClause:
  _fingerprintString(ctx, "InferClause");
  _fingerprintInferClause(ctx, obj, parent, field_name, depth);
  break;
case T_OnConflictClause:
  _fingerprintString(ctx, "OnConflictClause");
  _fingerprintOnConflictClause(ctx, obj, parent, field_name, depth);
  break;
case T_CTESearchClause:
  _fingerprintString(ctx, "CTESearchClause");
  _fingerprintCTESearchClause(ctx, obj, parent, field_name, depth);
  break;
case T_CTECycleClause:
  _fingerprintString(ctx, "CTECycleClause");
  _fingerprintCTECycleClause(ctx, obj, parent, field_name, depth);
  break;
case T_CommonTableExpr:
  _fingerprintString(ctx, "CommonTableExpr");
  _fingerprintCommonTableExpr(ctx, obj, parent, field_name, depth);
  break;
case T_MergeWhenClause:
  _fingerprintString(ctx, "MergeWhenClause");
  _fingerprintMergeWhenClause(ctx, obj, parent, field_name, depth);
  break;
case T_RoleSpec:
  _fingerprintString(ctx, "RoleSpec");
  _fingerprintRoleSpec(ctx, obj, parent, field_name, depth);
  break;
case T_TriggerTransition:
  _fingerprintString(ctx, "TriggerTransition");
  _fingerprintTriggerTransition(ctx, obj, parent, field_name, depth);
  break;
case T_PartitionElem:
  _fingerprintString(ctx, "PartitionElem");
  _fingerprintPartitionElem(ctx, obj, parent, field_name, depth);
  break;
case T_PartitionSpec:
  _fingerprintString(ctx, "PartitionSpec");
  _fingerprintPartitionSpec(ctx, obj, parent, field_name, depth);
  break;
case T_PartitionBoundSpec:
  _fingerprintString(ctx, "PartitionBoundSpec");
  _fingerprintPartitionBoundSpec(ctx, obj, parent, field_name, depth);
  break;
case T_PartitionRangeDatum:
  _fingerprintString(ctx, "PartitionRangeDatum");
  _fingerprintPartitionRangeDatum(ctx, obj, parent, field_name, depth);
  break;
case T_PartitionCmd:
  _fingerprintString(ctx, "PartitionCmd");
  _fingerprintPartitionCmd(ctx, obj, parent, field_name, depth);
  break;
case T_VacuumRelation:
  _fingerprintString(ctx, "VacuumRelation");
  _fingerprintVacuumRelation(ctx, obj, parent, field_name, depth);
  break;
case T_PublicationObjSpec:
  _fingerprintString(ctx, "PublicationObjSpec");
  _fingerprintPublicationObjSpec(ctx, obj, parent, field_name, depth);
  break;
case T_PublicationTable:
  _fingerprintString(ctx, "PublicationTable");
  _fingerprintPublicationTable(ctx, obj, parent, field_name, depth);
  break;
case T_InlineCodeBlock:
  _fingerprintString(ctx, "InlineCodeBlock");
  _fingerprintInlineCodeBlock(ctx, obj, parent, field_name, depth);
  break;
case T_CallContext:
  _fingerprintString(ctx, "CallContext");
  _fingerprintCallContext(ctx, obj, parent, field_name, depth);
  break;
