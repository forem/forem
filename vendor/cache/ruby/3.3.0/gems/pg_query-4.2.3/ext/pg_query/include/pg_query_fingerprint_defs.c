static void _fingerprintAlias(FingerprintContext *ctx, const Alias *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeVar(FingerprintContext *ctx, const RangeVar *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTableFunc(FingerprintContext *ctx, const TableFunc *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintVar(FingerprintContext *ctx, const Var *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintConst(FingerprintContext *ctx, const Const *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintParam(FingerprintContext *ctx, const Param *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAggref(FingerprintContext *ctx, const Aggref *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintGroupingFunc(FingerprintContext *ctx, const GroupingFunc *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintWindowFunc(FingerprintContext *ctx, const WindowFunc *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSubscriptingRef(FingerprintContext *ctx, const SubscriptingRef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFuncExpr(FingerprintContext *ctx, const FuncExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintNamedArgExpr(FingerprintContext *ctx, const NamedArgExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintOpExpr(FingerprintContext *ctx, const OpExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintScalarArrayOpExpr(FingerprintContext *ctx, const ScalarArrayOpExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintBoolExpr(FingerprintContext *ctx, const BoolExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSubLink(FingerprintContext *ctx, const SubLink *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSubPlan(FingerprintContext *ctx, const SubPlan *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlternativeSubPlan(FingerprintContext *ctx, const AlternativeSubPlan *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFieldSelect(FingerprintContext *ctx, const FieldSelect *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFieldStore(FingerprintContext *ctx, const FieldStore *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRelabelType(FingerprintContext *ctx, const RelabelType *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCoerceViaIO(FingerprintContext *ctx, const CoerceViaIO *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintArrayCoerceExpr(FingerprintContext *ctx, const ArrayCoerceExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintConvertRowtypeExpr(FingerprintContext *ctx, const ConvertRowtypeExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCollateExpr(FingerprintContext *ctx, const CollateExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCaseExpr(FingerprintContext *ctx, const CaseExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCaseWhen(FingerprintContext *ctx, const CaseWhen *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCaseTestExpr(FingerprintContext *ctx, const CaseTestExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintArrayExpr(FingerprintContext *ctx, const ArrayExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRowExpr(FingerprintContext *ctx, const RowExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRowCompareExpr(FingerprintContext *ctx, const RowCompareExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCoalesceExpr(FingerprintContext *ctx, const CoalesceExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintMinMaxExpr(FingerprintContext *ctx, const MinMaxExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSQLValueFunction(FingerprintContext *ctx, const SQLValueFunction *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintXmlExpr(FingerprintContext *ctx, const XmlExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintNullTest(FingerprintContext *ctx, const NullTest *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintBooleanTest(FingerprintContext *ctx, const BooleanTest *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCoerceToDomain(FingerprintContext *ctx, const CoerceToDomain *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCoerceToDomainValue(FingerprintContext *ctx, const CoerceToDomainValue *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSetToDefault(FingerprintContext *ctx, const SetToDefault *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCurrentOfExpr(FingerprintContext *ctx, const CurrentOfExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintNextValueExpr(FingerprintContext *ctx, const NextValueExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintInferenceElem(FingerprintContext *ctx, const InferenceElem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTargetEntry(FingerprintContext *ctx, const TargetEntry *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTblRef(FingerprintContext *ctx, const RangeTblRef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintJoinExpr(FingerprintContext *ctx, const JoinExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFromExpr(FingerprintContext *ctx, const FromExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintOnConflictExpr(FingerprintContext *ctx, const OnConflictExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintIntoClause(FingerprintContext *ctx, const IntoClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintMergeAction(FingerprintContext *ctx, const MergeAction *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRawStmt(FingerprintContext *ctx, const RawStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintQuery(FingerprintContext *ctx, const Query *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintInsertStmt(FingerprintContext *ctx, const InsertStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDeleteStmt(FingerprintContext *ctx, const DeleteStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintUpdateStmt(FingerprintContext *ctx, const UpdateStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintMergeStmt(FingerprintContext *ctx, const MergeStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSelectStmt(FingerprintContext *ctx, const SelectStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintReturnStmt(FingerprintContext *ctx, const ReturnStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPLAssignStmt(FingerprintContext *ctx, const PLAssignStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTableStmt(FingerprintContext *ctx, const AlterTableStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTableCmd(FingerprintContext *ctx, const AlterTableCmd *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterDomainStmt(FingerprintContext *ctx, const AlterDomainStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSetOperationStmt(FingerprintContext *ctx, const SetOperationStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintGrantStmt(FingerprintContext *ctx, const GrantStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintGrantRoleStmt(FingerprintContext *ctx, const GrantRoleStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterDefaultPrivilegesStmt(FingerprintContext *ctx, const AlterDefaultPrivilegesStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintClosePortalStmt(FingerprintContext *ctx, const ClosePortalStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintClusterStmt(FingerprintContext *ctx, const ClusterStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCopyStmt(FingerprintContext *ctx, const CopyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateStmt(FingerprintContext *ctx, const CreateStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDefineStmt(FingerprintContext *ctx, const DefineStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropStmt(FingerprintContext *ctx, const DropStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTruncateStmt(FingerprintContext *ctx, const TruncateStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCommentStmt(FingerprintContext *ctx, const CommentStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFetchStmt(FingerprintContext *ctx, const FetchStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintIndexStmt(FingerprintContext *ctx, const IndexStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateFunctionStmt(FingerprintContext *ctx, const CreateFunctionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterFunctionStmt(FingerprintContext *ctx, const AlterFunctionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDoStmt(FingerprintContext *ctx, const DoStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRenameStmt(FingerprintContext *ctx, const RenameStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRuleStmt(FingerprintContext *ctx, const RuleStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintNotifyStmt(FingerprintContext *ctx, const NotifyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintListenStmt(FingerprintContext *ctx, const ListenStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintUnlistenStmt(FingerprintContext *ctx, const UnlistenStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTransactionStmt(FingerprintContext *ctx, const TransactionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintViewStmt(FingerprintContext *ctx, const ViewStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintLoadStmt(FingerprintContext *ctx, const LoadStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateDomainStmt(FingerprintContext *ctx, const CreateDomainStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreatedbStmt(FingerprintContext *ctx, const CreatedbStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropdbStmt(FingerprintContext *ctx, const DropdbStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintVacuumStmt(FingerprintContext *ctx, const VacuumStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintExplainStmt(FingerprintContext *ctx, const ExplainStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateTableAsStmt(FingerprintContext *ctx, const CreateTableAsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateSeqStmt(FingerprintContext *ctx, const CreateSeqStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterSeqStmt(FingerprintContext *ctx, const AlterSeqStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintVariableSetStmt(FingerprintContext *ctx, const VariableSetStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintVariableShowStmt(FingerprintContext *ctx, const VariableShowStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDiscardStmt(FingerprintContext *ctx, const DiscardStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateTrigStmt(FingerprintContext *ctx, const CreateTrigStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreatePLangStmt(FingerprintContext *ctx, const CreatePLangStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateRoleStmt(FingerprintContext *ctx, const CreateRoleStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterRoleStmt(FingerprintContext *ctx, const AlterRoleStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropRoleStmt(FingerprintContext *ctx, const DropRoleStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintLockStmt(FingerprintContext *ctx, const LockStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintConstraintsSetStmt(FingerprintContext *ctx, const ConstraintsSetStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintReindexStmt(FingerprintContext *ctx, const ReindexStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCheckPointStmt(FingerprintContext *ctx, const CheckPointStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateSchemaStmt(FingerprintContext *ctx, const CreateSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterDatabaseStmt(FingerprintContext *ctx, const AlterDatabaseStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterDatabaseRefreshCollStmt(FingerprintContext *ctx, const AlterDatabaseRefreshCollStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterDatabaseSetStmt(FingerprintContext *ctx, const AlterDatabaseSetStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterRoleSetStmt(FingerprintContext *ctx, const AlterRoleSetStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateConversionStmt(FingerprintContext *ctx, const CreateConversionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateCastStmt(FingerprintContext *ctx, const CreateCastStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateOpClassStmt(FingerprintContext *ctx, const CreateOpClassStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateOpFamilyStmt(FingerprintContext *ctx, const CreateOpFamilyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterOpFamilyStmt(FingerprintContext *ctx, const AlterOpFamilyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPrepareStmt(FingerprintContext *ctx, const PrepareStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintExecuteStmt(FingerprintContext *ctx, const ExecuteStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDeallocateStmt(FingerprintContext *ctx, const DeallocateStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDeclareCursorStmt(FingerprintContext *ctx, const DeclareCursorStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateTableSpaceStmt(FingerprintContext *ctx, const CreateTableSpaceStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropTableSpaceStmt(FingerprintContext *ctx, const DropTableSpaceStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterObjectDependsStmt(FingerprintContext *ctx, const AlterObjectDependsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterObjectSchemaStmt(FingerprintContext *ctx, const AlterObjectSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterOwnerStmt(FingerprintContext *ctx, const AlterOwnerStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterOperatorStmt(FingerprintContext *ctx, const AlterOperatorStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTypeStmt(FingerprintContext *ctx, const AlterTypeStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropOwnedStmt(FingerprintContext *ctx, const DropOwnedStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintReassignOwnedStmt(FingerprintContext *ctx, const ReassignOwnedStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCompositeTypeStmt(FingerprintContext *ctx, const CompositeTypeStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateEnumStmt(FingerprintContext *ctx, const CreateEnumStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateRangeStmt(FingerprintContext *ctx, const CreateRangeStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterEnumStmt(FingerprintContext *ctx, const AlterEnumStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTSDictionaryStmt(FingerprintContext *ctx, const AlterTSDictionaryStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTSConfigurationStmt(FingerprintContext *ctx, const AlterTSConfigurationStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateFdwStmt(FingerprintContext *ctx, const CreateFdwStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterFdwStmt(FingerprintContext *ctx, const AlterFdwStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateForeignServerStmt(FingerprintContext *ctx, const CreateForeignServerStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterForeignServerStmt(FingerprintContext *ctx, const AlterForeignServerStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateUserMappingStmt(FingerprintContext *ctx, const CreateUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterUserMappingStmt(FingerprintContext *ctx, const AlterUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropUserMappingStmt(FingerprintContext *ctx, const DropUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTableSpaceOptionsStmt(FingerprintContext *ctx, const AlterTableSpaceOptionsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterTableMoveAllStmt(FingerprintContext *ctx, const AlterTableMoveAllStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSecLabelStmt(FingerprintContext *ctx, const SecLabelStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateForeignTableStmt(FingerprintContext *ctx, const CreateForeignTableStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintImportForeignSchemaStmt(FingerprintContext *ctx, const ImportForeignSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateExtensionStmt(FingerprintContext *ctx, const CreateExtensionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterExtensionStmt(FingerprintContext *ctx, const AlterExtensionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterExtensionContentsStmt(FingerprintContext *ctx, const AlterExtensionContentsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateEventTrigStmt(FingerprintContext *ctx, const CreateEventTrigStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterEventTrigStmt(FingerprintContext *ctx, const AlterEventTrigStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRefreshMatViewStmt(FingerprintContext *ctx, const RefreshMatViewStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintReplicaIdentityStmt(FingerprintContext *ctx, const ReplicaIdentityStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterSystemStmt(FingerprintContext *ctx, const AlterSystemStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreatePolicyStmt(FingerprintContext *ctx, const CreatePolicyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterPolicyStmt(FingerprintContext *ctx, const AlterPolicyStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateTransformStmt(FingerprintContext *ctx, const CreateTransformStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateAmStmt(FingerprintContext *ctx, const CreateAmStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreatePublicationStmt(FingerprintContext *ctx, const CreatePublicationStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterPublicationStmt(FingerprintContext *ctx, const AlterPublicationStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateSubscriptionStmt(FingerprintContext *ctx, const CreateSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterSubscriptionStmt(FingerprintContext *ctx, const AlterSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDropSubscriptionStmt(FingerprintContext *ctx, const DropSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateStatsStmt(FingerprintContext *ctx, const CreateStatsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterCollationStmt(FingerprintContext *ctx, const AlterCollationStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCallStmt(FingerprintContext *ctx, const CallStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAlterStatsStmt(FingerprintContext *ctx, const AlterStatsStmt *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintA_Expr(FingerprintContext *ctx, const A_Expr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintColumnRef(FingerprintContext *ctx, const ColumnRef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintParamRef(FingerprintContext *ctx, const ParamRef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFuncCall(FingerprintContext *ctx, const FuncCall *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintA_Star(FingerprintContext *ctx, const A_Star *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintA_Indices(FingerprintContext *ctx, const A_Indices *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintA_Indirection(FingerprintContext *ctx, const A_Indirection *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintA_ArrayExpr(FingerprintContext *ctx, const A_ArrayExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintResTarget(FingerprintContext *ctx, const ResTarget *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintMultiAssignRef(FingerprintContext *ctx, const MultiAssignRef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTypeCast(FingerprintContext *ctx, const TypeCast *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCollateClause(FingerprintContext *ctx, const CollateClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSortBy(FingerprintContext *ctx, const SortBy *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintWindowDef(FingerprintContext *ctx, const WindowDef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeSubselect(FingerprintContext *ctx, const RangeSubselect *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeFunction(FingerprintContext *ctx, const RangeFunction *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTableSample(FingerprintContext *ctx, const RangeTableSample *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTableFunc(FingerprintContext *ctx, const RangeTableFunc *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTableFuncCol(FingerprintContext *ctx, const RangeTableFuncCol *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTypeName(FingerprintContext *ctx, const TypeName *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintColumnDef(FingerprintContext *ctx, const ColumnDef *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintIndexElem(FingerprintContext *ctx, const IndexElem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintStatsElem(FingerprintContext *ctx, const StatsElem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintConstraint(FingerprintContext *ctx, const Constraint *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintDefElem(FingerprintContext *ctx, const DefElem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTblEntry(FingerprintContext *ctx, const RangeTblEntry *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRangeTblFunction(FingerprintContext *ctx, const RangeTblFunction *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTableSampleClause(FingerprintContext *ctx, const TableSampleClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintWithCheckOption(FingerprintContext *ctx, const WithCheckOption *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintSortGroupClause(FingerprintContext *ctx, const SortGroupClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintGroupingSet(FingerprintContext *ctx, const GroupingSet *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintWindowClause(FingerprintContext *ctx, const WindowClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintObjectWithArgs(FingerprintContext *ctx, const ObjectWithArgs *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintAccessPriv(FingerprintContext *ctx, const AccessPriv *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCreateOpClassItem(FingerprintContext *ctx, const CreateOpClassItem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTableLikeClause(FingerprintContext *ctx, const TableLikeClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintFunctionParameter(FingerprintContext *ctx, const FunctionParameter *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintLockingClause(FingerprintContext *ctx, const LockingClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRowMarkClause(FingerprintContext *ctx, const RowMarkClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintXmlSerialize(FingerprintContext *ctx, const XmlSerialize *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintWithClause(FingerprintContext *ctx, const WithClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintInferClause(FingerprintContext *ctx, const InferClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintOnConflictClause(FingerprintContext *ctx, const OnConflictClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCTESearchClause(FingerprintContext *ctx, const CTESearchClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCTECycleClause(FingerprintContext *ctx, const CTECycleClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCommonTableExpr(FingerprintContext *ctx, const CommonTableExpr *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintMergeWhenClause(FingerprintContext *ctx, const MergeWhenClause *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintRoleSpec(FingerprintContext *ctx, const RoleSpec *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintTriggerTransition(FingerprintContext *ctx, const TriggerTransition *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPartitionElem(FingerprintContext *ctx, const PartitionElem *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPartitionSpec(FingerprintContext *ctx, const PartitionSpec *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPartitionBoundSpec(FingerprintContext *ctx, const PartitionBoundSpec *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPartitionRangeDatum(FingerprintContext *ctx, const PartitionRangeDatum *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPartitionCmd(FingerprintContext *ctx, const PartitionCmd *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintVacuumRelation(FingerprintContext *ctx, const VacuumRelation *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPublicationObjSpec(FingerprintContext *ctx, const PublicationObjSpec *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintPublicationTable(FingerprintContext *ctx, const PublicationTable *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintInlineCodeBlock(FingerprintContext *ctx, const InlineCodeBlock *node, const void *parent, const char *field_name, unsigned int depth);
static void _fingerprintCallContext(FingerprintContext *ctx, const CallContext *node, const void *parent, const char *field_name, unsigned int depth);


static void
_fingerprintAlias(FingerprintContext *ctx, const Alias *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring all fields for fingerprinting
}

static void
_fingerprintRangeVar(FingerprintContext *ctx, const RangeVar *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->catalogname != NULL) {
    _fingerprintString(ctx, "catalogname");
    _fingerprintString(ctx, node->catalogname);
  }

  if (node->inh) {
    _fingerprintString(ctx, "inh");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->relname != NULL && node->relpersistence != 't') {
    int len = strlen(node->relname);
    char *r = palloc0((len + 1) * sizeof(char));
    char *p = r;
    for (int i = 0; i < len; i++) {
      if (node->relname[i] >= '0' && node->relname[i] <= '9' &&
          ((i + 1 < len && node->relname[i + 1] >= '0' && node->relname[i + 1] <= '9') ||
           (i > 0 && node->relname[i - 1] >= '0' && node->relname[i - 1] <= '9'))) {
        // Skip
      } else {
        *p = node->relname[i];
        p++;
      }
    }
    *p = 0;
    _fingerprintString(ctx, "relname");
    _fingerprintString(ctx, r);
    pfree(r);
  }

  if (node->relpersistence != 0) {
    char buffer[2] = {node->relpersistence, '\0'};
    _fingerprintString(ctx, "relpersistence");
    _fingerprintString(ctx, buffer);
  }

  if (node->schemaname != NULL) {
    _fingerprintString(ctx, "schemaname");
    _fingerprintString(ctx, node->schemaname);
  }

}

static void
_fingerprintTableFunc(FingerprintContext *ctx, const TableFunc *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->colcollations != NULL && node->colcollations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colcollations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colcollations, node, "colcollations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colcollations) == 1 && linitial(node->colcollations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coldefexprs != NULL && node->coldefexprs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coldefexprs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coldefexprs, node, "coldefexprs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coldefexprs) == 1 && linitial(node->coldefexprs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->colexprs != NULL && node->colexprs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colexprs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colexprs, node, "colexprs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colexprs) == 1 && linitial(node->colexprs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->colnames != NULL && node->colnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colnames, node, "colnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colnames) == 1 && linitial(node->colnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coltypes != NULL && node->coltypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coltypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coltypes, node, "coltypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coltypes) == 1 && linitial(node->coltypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coltypmods != NULL && node->coltypmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coltypmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coltypmods, node, "coltypmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coltypmods) == 1 && linitial(node->coltypmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->docexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "docexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->docexpr, node, "docexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->notnulls);

    _fingerprintString(ctx, "notnulls");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

  if (node->ns_names != NULL && node->ns_names->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ns_names");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ns_names, node, "ns_names", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ns_names) == 1 && linitial(node->ns_names) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ns_uris != NULL && node->ns_uris->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ns_uris");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ns_uris, node, "ns_uris", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ns_uris) == 1 && linitial(node->ns_uris) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ordinalitycol != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->ordinalitycol);
    _fingerprintString(ctx, "ordinalitycol");
    _fingerprintString(ctx, buffer);
  }

  if (node->rowexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rowexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rowexpr, node, "rowexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintVar(FingerprintContext *ctx, const Var *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->varattno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varattno);
    _fingerprintString(ctx, "varattno");
    _fingerprintString(ctx, buffer);
  }

  if (node->varattnosyn != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varattnosyn);
    _fingerprintString(ctx, "varattnosyn");
    _fingerprintString(ctx, buffer);
  }

  if (node->varcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varcollid);
    _fingerprintString(ctx, "varcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->varlevelsup != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varlevelsup);
    _fingerprintString(ctx, "varlevelsup");
    _fingerprintString(ctx, buffer);
  }

  if (node->varno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varno);
    _fingerprintString(ctx, "varno");
    _fingerprintString(ctx, buffer);
  }

  if (node->varnosyn != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->varnosyn);
    _fingerprintString(ctx, "varnosyn");
    _fingerprintString(ctx, buffer);
  }

  if (node->vartype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->vartype);
    _fingerprintString(ctx, "vartype");
    _fingerprintString(ctx, buffer);
  }

  if (node->vartypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->vartypmod);
    _fingerprintString(ctx, "vartypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintConst(FingerprintContext *ctx, const Const *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->constbyval) {
    _fingerprintString(ctx, "constbyval");
    _fingerprintString(ctx, "true");
  }

  if (node->constcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->constcollid);
    _fingerprintString(ctx, "constcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->constisnull) {
    _fingerprintString(ctx, "constisnull");
    _fingerprintString(ctx, "true");
  }

  if (node->constlen != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->constlen);
    _fingerprintString(ctx, "constlen");
    _fingerprintString(ctx, buffer);
  }

  if (node->consttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->consttype);
    _fingerprintString(ctx, "consttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->consttypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->consttypmod);
    _fingerprintString(ctx, "consttypmod");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintParam(FingerprintContext *ctx, const Param *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->paramcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->paramcollid);
    _fingerprintString(ctx, "paramcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->paramid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->paramid);
    _fingerprintString(ctx, "paramid");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "paramkind");
    _fingerprintString(ctx, _enumToStringParamKind(node->paramkind));
  }

  if (node->paramtype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->paramtype);
    _fingerprintString(ctx, "paramtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->paramtypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->paramtypmod);
    _fingerprintString(ctx, "paramtypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintAggref(FingerprintContext *ctx, const Aggref *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->aggargtypes != NULL && node->aggargtypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggargtypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggargtypes, node, "aggargtypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aggargtypes) == 1 && linitial(node->aggargtypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->aggcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggcollid);
    _fingerprintString(ctx, "aggcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggdirectargs != NULL && node->aggdirectargs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggdirectargs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggdirectargs, node, "aggdirectargs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aggdirectargs) == 1 && linitial(node->aggdirectargs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->aggdistinct != NULL && node->aggdistinct->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggdistinct");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggdistinct, node, "aggdistinct", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aggdistinct) == 1 && linitial(node->aggdistinct) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->aggfilter != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggfilter");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggfilter, node, "aggfilter", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->aggfnoid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggfnoid);
    _fingerprintString(ctx, "aggfnoid");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggkind != 0) {
    char buffer[2] = {node->aggkind, '\0'};
    _fingerprintString(ctx, "aggkind");
    _fingerprintString(ctx, buffer);
  }

  if (node->agglevelsup != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->agglevelsup);
    _fingerprintString(ctx, "agglevelsup");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggno);
    _fingerprintString(ctx, "aggno");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggorder != NULL && node->aggorder->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggorder");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggorder, node, "aggorder", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aggorder) == 1 && linitial(node->aggorder) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "aggsplit");
    _fingerprintString(ctx, _enumToStringAggSplit(node->aggsplit));
  }

  if (node->aggstar) {
    _fingerprintString(ctx, "aggstar");
    _fingerprintString(ctx, "true");
  }

  if (node->aggtransno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggtransno);
    _fingerprintString(ctx, "aggtransno");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggtranstype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggtranstype);
    _fingerprintString(ctx, "aggtranstype");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggtype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->aggtype);
    _fingerprintString(ctx, "aggtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->aggvariadic) {
    _fingerprintString(ctx, "aggvariadic");
    _fingerprintString(ctx, "true");
  }

  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintGroupingFunc(FingerprintContext *ctx, const GroupingFunc *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->agglevelsup != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->agglevelsup);
    _fingerprintString(ctx, "agglevelsup");
    _fingerprintString(ctx, buffer);
  }

  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->cols != NULL && node->cols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cols, node, "cols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cols) == 1 && linitial(node->cols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->refs != NULL && node->refs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "refs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->refs, node, "refs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->refs) == 1 && linitial(node->refs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintWindowFunc(FingerprintContext *ctx, const WindowFunc *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->aggfilter != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aggfilter");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aggfilter, node, "aggfilter", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->winagg) {
    _fingerprintString(ctx, "winagg");
    _fingerprintString(ctx, "true");
  }

  if (node->wincollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->wincollid);
    _fingerprintString(ctx, "wincollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->winfnoid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->winfnoid);
    _fingerprintString(ctx, "winfnoid");
    _fingerprintString(ctx, buffer);
  }

  if (node->winref != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->winref);
    _fingerprintString(ctx, "winref");
    _fingerprintString(ctx, buffer);
  }

  if (node->winstar) {
    _fingerprintString(ctx, "winstar");
    _fingerprintString(ctx, "true");
  }

  if (node->wintype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->wintype);
    _fingerprintString(ctx, "wintype");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintSubscriptingRef(FingerprintContext *ctx, const SubscriptingRef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->refassgnexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "refassgnexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->refassgnexpr, node, "refassgnexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->refcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->refcollid);
    _fingerprintString(ctx, "refcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->refcontainertype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->refcontainertype);
    _fingerprintString(ctx, "refcontainertype");
    _fingerprintString(ctx, buffer);
  }

  if (node->refelemtype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->refelemtype);
    _fingerprintString(ctx, "refelemtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->refexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "refexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->refexpr, node, "refexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->reflowerindexpr != NULL && node->reflowerindexpr->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "reflowerindexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->reflowerindexpr, node, "reflowerindexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->reflowerindexpr) == 1 && linitial(node->reflowerindexpr) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->refrestype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->refrestype);
    _fingerprintString(ctx, "refrestype");
    _fingerprintString(ctx, buffer);
  }

  if (node->reftypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->reftypmod);
    _fingerprintString(ctx, "reftypmod");
    _fingerprintString(ctx, buffer);
  }

  if (node->refupperindexpr != NULL && node->refupperindexpr->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "refupperindexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->refupperindexpr, node, "refupperindexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->refupperindexpr) == 1 && linitial(node->refupperindexpr) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintFuncExpr(FingerprintContext *ctx, const FuncExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->funccollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->funccollid);
    _fingerprintString(ctx, "funccollid");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "funcformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->funcformat));
  }

  if (node->funcid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->funcid);
    _fingerprintString(ctx, "funcid");
    _fingerprintString(ctx, buffer);
  }

  if (node->funcresulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->funcresulttype);
    _fingerprintString(ctx, "funcresulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->funcretset) {
    _fingerprintString(ctx, "funcretset");
    _fingerprintString(ctx, "true");
  }

  if (node->funcvariadic) {
    _fingerprintString(ctx, "funcvariadic");
    _fingerprintString(ctx, "true");
  }

  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintNamedArgExpr(FingerprintContext *ctx, const NamedArgExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->argnumber != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->argnumber);
    _fingerprintString(ctx, "argnumber");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintOpExpr(FingerprintContext *ctx, const OpExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->opcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opcollid);
    _fingerprintString(ctx, "opcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->opfuncid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opfuncid);
    _fingerprintString(ctx, "opfuncid");
    _fingerprintString(ctx, buffer);
  }

  if (node->opno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opno);
    _fingerprintString(ctx, "opno");
    _fingerprintString(ctx, buffer);
  }

  if (node->opresulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opresulttype);
    _fingerprintString(ctx, "opresulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->opretset) {
    _fingerprintString(ctx, "opretset");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintScalarArrayOpExpr(FingerprintContext *ctx, const ScalarArrayOpExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->hashfuncid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->hashfuncid);
    _fingerprintString(ctx, "hashfuncid");
    _fingerprintString(ctx, buffer);
  }

  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->negfuncid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->negfuncid);
    _fingerprintString(ctx, "negfuncid");
    _fingerprintString(ctx, buffer);
  }

  if (node->opfuncid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opfuncid);
    _fingerprintString(ctx, "opfuncid");
    _fingerprintString(ctx, buffer);
  }

  if (node->opno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->opno);
    _fingerprintString(ctx, "opno");
    _fingerprintString(ctx, buffer);
  }

  if (node->useOr) {
    _fingerprintString(ctx, "useOr");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintBoolExpr(FingerprintContext *ctx, const BoolExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "boolop");
    _fingerprintString(ctx, _enumToStringBoolExprType(node->boolop));
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintSubLink(FingerprintContext *ctx, const SubLink *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->operName != NULL && node->operName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "operName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->operName, node, "operName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->operName) == 1 && linitial(node->operName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->subLinkId != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->subLinkId);
    _fingerprintString(ctx, "subLinkId");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "subLinkType");
    _fingerprintString(ctx, _enumToStringSubLinkType(node->subLinkType));
  }

  if (node->subselect != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "subselect");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->subselect, node, "subselect", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->testexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "testexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->testexpr, node, "testexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintSubPlan(FingerprintContext *ctx, const SubPlan *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->firstColCollation != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->firstColCollation);
    _fingerprintString(ctx, "firstColCollation");
    _fingerprintString(ctx, buffer);
  }

  if (node->firstColType != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->firstColType);
    _fingerprintString(ctx, "firstColType");
    _fingerprintString(ctx, buffer);
  }

  if (node->firstColTypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->firstColTypmod);
    _fingerprintString(ctx, "firstColTypmod");
    _fingerprintString(ctx, buffer);
  }

  if (node->parParam != NULL && node->parParam->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "parParam");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->parParam, node, "parParam", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->parParam) == 1 && linitial(node->parParam) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->parallel_safe) {
    _fingerprintString(ctx, "parallel_safe");
    _fingerprintString(ctx, "true");
  }

  if (node->paramIds != NULL && node->paramIds->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "paramIds");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->paramIds, node, "paramIds", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->paramIds) == 1 && linitial(node->paramIds) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->per_call_cost != 0) {
    char buffer[50];
    sprintf(buffer, "%f", node->per_call_cost);
    _fingerprintString(ctx, "per_call_cost");
    _fingerprintString(ctx, buffer);
  }

  if (node->plan_id != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->plan_id);
    _fingerprintString(ctx, "plan_id");
    _fingerprintString(ctx, buffer);
  }

  if (node->plan_name != NULL) {
    _fingerprintString(ctx, "plan_name");
    _fingerprintString(ctx, node->plan_name);
  }

  if (node->setParam != NULL && node->setParam->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "setParam");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->setParam, node, "setParam", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->setParam) == 1 && linitial(node->setParam) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->startup_cost != 0) {
    char buffer[50];
    sprintf(buffer, "%f", node->startup_cost);
    _fingerprintString(ctx, "startup_cost");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "subLinkType");
    _fingerprintString(ctx, _enumToStringSubLinkType(node->subLinkType));
  }

  if (node->testexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "testexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->testexpr, node, "testexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->unknownEqFalse) {
    _fingerprintString(ctx, "unknownEqFalse");
    _fingerprintString(ctx, "true");
  }

  if (node->useHashTable) {
    _fingerprintString(ctx, "useHashTable");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintAlternativeSubPlan(FingerprintContext *ctx, const AlternativeSubPlan *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->subplans != NULL && node->subplans->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "subplans");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->subplans, node, "subplans", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->subplans) == 1 && linitial(node->subplans) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintFieldSelect(FingerprintContext *ctx, const FieldSelect *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->fieldnum != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->fieldnum);
    _fingerprintString(ctx, "fieldnum");
    _fingerprintString(ctx, buffer);
  }

  if (node->resultcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultcollid);
    _fingerprintString(ctx, "resultcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttypmod);
    _fingerprintString(ctx, "resulttypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintFieldStore(FingerprintContext *ctx, const FieldStore *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->fieldnums != NULL && node->fieldnums->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fieldnums");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fieldnums, node, "fieldnums", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fieldnums) == 1 && linitial(node->fieldnums) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->newvals != NULL && node->newvals->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "newvals");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->newvals, node, "newvals", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->newvals) == 1 && linitial(node->newvals) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintRelabelType(FingerprintContext *ctx, const RelabelType *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (true) {
    _fingerprintString(ctx, "relabelformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->relabelformat));
  }

  if (node->resultcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultcollid);
    _fingerprintString(ctx, "resultcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttypmod);
    _fingerprintString(ctx, "resulttypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintCoerceViaIO(FingerprintContext *ctx, const CoerceViaIO *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "coerceformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->coerceformat));
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->resultcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultcollid);
    _fingerprintString(ctx, "resultcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintArrayCoerceExpr(FingerprintContext *ctx, const ArrayCoerceExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "coerceformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->coerceformat));
  }

  if (node->elemexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "elemexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->elemexpr, node, "elemexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->resultcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultcollid);
    _fingerprintString(ctx, "resultcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttypmod);
    _fingerprintString(ctx, "resulttypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintConvertRowtypeExpr(FingerprintContext *ctx, const ConvertRowtypeExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "convertformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->convertformat));
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintCollateExpr(FingerprintContext *ctx, const CollateExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->collOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->collOid);
    _fingerprintString(ctx, "collOid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintCaseExpr(FingerprintContext *ctx, const CaseExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->casecollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->casecollid);
    _fingerprintString(ctx, "casecollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->casetype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->casetype);
    _fingerprintString(ctx, "casetype");
    _fingerprintString(ctx, buffer);
  }

  if (node->defresult != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "defresult");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->defresult, node, "defresult", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintCaseWhen(FingerprintContext *ctx, const CaseWhen *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->result != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "result");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->result, node, "result", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCaseTestExpr(FingerprintContext *ctx, const CaseTestExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collation != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->collation);
    _fingerprintString(ctx, "collation");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeId != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeId);
    _fingerprintString(ctx, "typeId");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeMod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeMod);
    _fingerprintString(ctx, "typeMod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintArrayExpr(FingerprintContext *ctx, const ArrayExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->array_collid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->array_collid);
    _fingerprintString(ctx, "array_collid");
    _fingerprintString(ctx, buffer);
  }

  if (node->array_typeid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->array_typeid);
    _fingerprintString(ctx, "array_typeid");
    _fingerprintString(ctx, buffer);
  }

  if (node->element_typeid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->element_typeid);
    _fingerprintString(ctx, "element_typeid");
    _fingerprintString(ctx, buffer);
  }

  if (node->elements != NULL && node->elements->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "elements");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->elements, node, "elements", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->elements) == 1 && linitial(node->elements) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->multidims) {
    _fingerprintString(ctx, "multidims");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintRowExpr(FingerprintContext *ctx, const RowExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->colnames != NULL && node->colnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colnames, node, "colnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colnames) == 1 && linitial(node->colnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (true) {
    _fingerprintString(ctx, "row_format");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->row_format));
  }

  if (node->row_typeid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->row_typeid);
    _fingerprintString(ctx, "row_typeid");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintRowCompareExpr(FingerprintContext *ctx, const RowCompareExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->inputcollids != NULL && node->inputcollids->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "inputcollids");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->inputcollids, node, "inputcollids", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->inputcollids) == 1 && linitial(node->inputcollids) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->largs != NULL && node->largs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "largs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->largs, node, "largs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->largs) == 1 && linitial(node->largs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opfamilies != NULL && node->opfamilies->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opfamilies");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opfamilies, node, "opfamilies", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opfamilies) == 1 && linitial(node->opfamilies) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opnos != NULL && node->opnos->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opnos");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opnos, node, "opnos", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opnos) == 1 && linitial(node->opnos) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rargs != NULL && node->rargs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rargs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rargs, node, "rargs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->rargs) == 1 && linitial(node->rargs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "rctype");
    _fingerprintString(ctx, _enumToStringRowCompareType(node->rctype));
  }

}

static void
_fingerprintCoalesceExpr(FingerprintContext *ctx, const CoalesceExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coalescecollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->coalescecollid);
    _fingerprintString(ctx, "coalescecollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->coalescetype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->coalescetype);
    _fingerprintString(ctx, "coalescetype");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintMinMaxExpr(FingerprintContext *ctx, const MinMaxExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->inputcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inputcollid);
    _fingerprintString(ctx, "inputcollid");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->minmaxcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->minmaxcollid);
    _fingerprintString(ctx, "minmaxcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->minmaxtype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->minmaxtype);
    _fingerprintString(ctx, "minmaxtype");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "op");
    _fingerprintString(ctx, _enumToStringMinMaxOp(node->op));
  }

}

static void
_fingerprintSQLValueFunction(FingerprintContext *ctx, const SQLValueFunction *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (true) {
    _fingerprintString(ctx, "op");
    _fingerprintString(ctx, _enumToStringSQLValueFunctionOp(node->op));
  }

  if (node->type != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->type);
    _fingerprintString(ctx, "type");
    _fingerprintString(ctx, buffer);
  }

  if (node->typmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typmod);
    _fingerprintString(ctx, "typmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintXmlExpr(FingerprintContext *ctx, const XmlExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg_names != NULL && node->arg_names->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg_names");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg_names, node, "arg_names", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->arg_names) == 1 && linitial(node->arg_names) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->named_args != NULL && node->named_args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "named_args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->named_args, node, "named_args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->named_args) == 1 && linitial(node->named_args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "op");
    _fingerprintString(ctx, _enumToStringXmlExprOp(node->op));
  }

  if (node->type != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->type);
    _fingerprintString(ctx, "type");
    _fingerprintString(ctx, buffer);
  }

  if (node->typmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typmod);
    _fingerprintString(ctx, "typmod");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "xmloption");
    _fingerprintString(ctx, _enumToStringXmlOptionType(node->xmloption));
  }

}

static void
_fingerprintNullTest(FingerprintContext *ctx, const NullTest *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->argisrow) {
    _fingerprintString(ctx, "argisrow");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->location for fingerprinting

  if (true) {
    _fingerprintString(ctx, "nulltesttype");
    _fingerprintString(ctx, _enumToStringNullTestType(node->nulltesttype));
  }

}

static void
_fingerprintBooleanTest(FingerprintContext *ctx, const BooleanTest *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "booltesttype");
    _fingerprintString(ctx, _enumToStringBoolTestType(node->booltesttype));
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintCoerceToDomain(FingerprintContext *ctx, const CoerceToDomain *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "coercionformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->coercionformat));
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->resultcollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultcollid);
    _fingerprintString(ctx, "resultcollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttype);
    _fingerprintString(ctx, "resulttype");
    _fingerprintString(ctx, buffer);
  }

  if (node->resulttypmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resulttypmod);
    _fingerprintString(ctx, "resulttypmod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintCoerceToDomainValue(FingerprintContext *ctx, const CoerceToDomainValue *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collation != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->collation);
    _fingerprintString(ctx, "collation");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->typeId != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeId);
    _fingerprintString(ctx, "typeId");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeMod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeMod);
    _fingerprintString(ctx, "typeMod");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintSetToDefault(FingerprintContext *ctx, const SetToDefault *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring all fields for fingerprinting
}

static void
_fingerprintCurrentOfExpr(FingerprintContext *ctx, const CurrentOfExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cursor_name != NULL) {
    _fingerprintString(ctx, "cursor_name");
    _fingerprintString(ctx, node->cursor_name);
  }

  if (node->cursor_param != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cursor_param);
    _fingerprintString(ctx, "cursor_param");
    _fingerprintString(ctx, buffer);
  }

  if (node->cvarno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cvarno);
    _fingerprintString(ctx, "cvarno");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintNextValueExpr(FingerprintContext *ctx, const NextValueExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->seqid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->seqid);
    _fingerprintString(ctx, "seqid");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeId != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeId);
    _fingerprintString(ctx, "typeId");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintInferenceElem(FingerprintContext *ctx, const InferenceElem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->infercollid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->infercollid);
    _fingerprintString(ctx, "infercollid");
    _fingerprintString(ctx, buffer);
  }

  if (node->inferopclass != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inferopclass);
    _fingerprintString(ctx, "inferopclass");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintTargetEntry(FingerprintContext *ctx, const TargetEntry *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->resjunk) {
    _fingerprintString(ctx, "resjunk");
    _fingerprintString(ctx, "true");
  }

  if (node->resname != NULL) {
    _fingerprintString(ctx, "resname");
    _fingerprintString(ctx, node->resname);
  }

  if (node->resno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resno);
    _fingerprintString(ctx, "resno");
    _fingerprintString(ctx, buffer);
  }

  if (node->resorigcol != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resorigcol);
    _fingerprintString(ctx, "resorigcol");
    _fingerprintString(ctx, buffer);
  }

  if (node->resorigtbl != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resorigtbl);
    _fingerprintString(ctx, "resorigtbl");
    _fingerprintString(ctx, buffer);
  }

  if (node->ressortgroupref != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->ressortgroupref);
    _fingerprintString(ctx, "ressortgroupref");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintRangeTblRef(FingerprintContext *ctx, const RangeTblRef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->rtindex != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->rtindex);
    _fingerprintString(ctx, "rtindex");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintJoinExpr(FingerprintContext *ctx, const JoinExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->isNatural) {
    _fingerprintString(ctx, "isNatural");
    _fingerprintString(ctx, "true");
  }

  if (node->join_using_alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "join_using_alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->join_using_alias, node, "join_using_alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "jointype");
    _fingerprintString(ctx, _enumToStringJoinType(node->jointype));
  }

  if (node->larg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "larg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->larg, node, "larg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->quals != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "quals");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->quals, node, "quals", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->rarg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rarg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rarg, node, "rarg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->rtindex != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->rtindex);
    _fingerprintString(ctx, "rtindex");
    _fingerprintString(ctx, buffer);
  }

  if (node->usingClause != NULL && node->usingClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "usingClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->usingClause, node, "usingClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->usingClause) == 1 && linitial(node->usingClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintFromExpr(FingerprintContext *ctx, const FromExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fromlist != NULL && node->fromlist->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fromlist");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fromlist, node, "fromlist", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fromlist) == 1 && linitial(node->fromlist) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->quals != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "quals");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->quals, node, "quals", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintOnConflictExpr(FingerprintContext *ctx, const OnConflictExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "action");
    _fingerprintString(ctx, _enumToStringOnConflictAction(node->action));
  }

  if (node->arbiterElems != NULL && node->arbiterElems->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arbiterElems");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arbiterElems, node, "arbiterElems", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->arbiterElems) == 1 && linitial(node->arbiterElems) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->arbiterWhere != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arbiterWhere");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arbiterWhere, node, "arbiterWhere", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->constraint != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->constraint);
    _fingerprintString(ctx, "constraint");
    _fingerprintString(ctx, buffer);
  }

  if (node->exclRelIndex != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->exclRelIndex);
    _fingerprintString(ctx, "exclRelIndex");
    _fingerprintString(ctx, buffer);
  }

  if (node->exclRelTlist != NULL && node->exclRelTlist->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "exclRelTlist");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->exclRelTlist, node, "exclRelTlist", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->exclRelTlist) == 1 && linitial(node->exclRelTlist) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->onConflictSet != NULL && node->onConflictSet->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "onConflictSet");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->onConflictSet, node, "onConflictSet", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->onConflictSet) == 1 && linitial(node->onConflictSet) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->onConflictWhere != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "onConflictWhere");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->onConflictWhere, node, "onConflictWhere", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintIntoClause(FingerprintContext *ctx, const IntoClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->accessMethod != NULL) {
    _fingerprintString(ctx, "accessMethod");
    _fingerprintString(ctx, node->accessMethod);
  }

  if (node->colNames != NULL && node->colNames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colNames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colNames, node, "colNames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colNames) == 1 && linitial(node->colNames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "onCommit");
    _fingerprintString(ctx, _enumToStringOnCommitAction(node->onCommit));
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rel != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rel");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->rel, node, "rel", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->skipData) {
    _fingerprintString(ctx, "skipData");
    _fingerprintString(ctx, "true");
  }

  if (node->tableSpaceName != NULL) {
    _fingerprintString(ctx, "tableSpaceName");
    _fingerprintString(ctx, node->tableSpaceName);
  }

  if (node->viewQuery != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "viewQuery");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->viewQuery, node, "viewQuery", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintMergeAction(FingerprintContext *ctx, const MergeAction *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "commandType");
    _fingerprintString(ctx, _enumToStringCmdType(node->commandType));
  }

  if (node->matched) {
    _fingerprintString(ctx, "matched");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "override");
    _fingerprintString(ctx, _enumToStringOverridingKind(node->override));
  }

  if (node->qual != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "qual");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->qual, node, "qual", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->updateColnos != NULL && node->updateColnos->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "updateColnos");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->updateColnos, node, "updateColnos", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->updateColnos) == 1 && linitial(node->updateColnos) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintRawStmt(FingerprintContext *ctx, const RawStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->stmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "stmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->stmt, node, "stmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->stmt_len for fingerprinting

  // Intentionally ignoring node->stmt_location for fingerprinting

}

static void
_fingerprintQuery(FingerprintContext *ctx, const Query *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->canSetTag) {
    _fingerprintString(ctx, "canSetTag");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "commandType");
    _fingerprintString(ctx, _enumToStringCmdType(node->commandType));
  }

  if (node->constraintDeps != NULL && node->constraintDeps->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constraintDeps");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->constraintDeps, node, "constraintDeps", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->constraintDeps) == 1 && linitial(node->constraintDeps) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->cteList != NULL && node->cteList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cteList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cteList, node, "cteList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cteList) == 1 && linitial(node->cteList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->distinctClause != NULL && node->distinctClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "distinctClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->distinctClause, node, "distinctClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->distinctClause) == 1 && linitial(node->distinctClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->groupClause != NULL && node->groupClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "groupClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->groupClause, node, "groupClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->groupClause) == 1 && linitial(node->groupClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->groupDistinct) {
    _fingerprintString(ctx, "groupDistinct");
    _fingerprintString(ctx, "true");
  }

  if (node->groupingSets != NULL && node->groupingSets->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "groupingSets");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->groupingSets, node, "groupingSets", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->groupingSets) == 1 && linitial(node->groupingSets) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->hasAggs) {
    _fingerprintString(ctx, "hasAggs");
    _fingerprintString(ctx, "true");
  }

  if (node->hasDistinctOn) {
    _fingerprintString(ctx, "hasDistinctOn");
    _fingerprintString(ctx, "true");
  }

  if (node->hasForUpdate) {
    _fingerprintString(ctx, "hasForUpdate");
    _fingerprintString(ctx, "true");
  }

  if (node->hasModifyingCTE) {
    _fingerprintString(ctx, "hasModifyingCTE");
    _fingerprintString(ctx, "true");
  }

  if (node->hasRecursive) {
    _fingerprintString(ctx, "hasRecursive");
    _fingerprintString(ctx, "true");
  }

  if (node->hasRowSecurity) {
    _fingerprintString(ctx, "hasRowSecurity");
    _fingerprintString(ctx, "true");
  }

  if (node->hasSubLinks) {
    _fingerprintString(ctx, "hasSubLinks");
    _fingerprintString(ctx, "true");
  }

  if (node->hasTargetSRFs) {
    _fingerprintString(ctx, "hasTargetSRFs");
    _fingerprintString(ctx, "true");
  }

  if (node->hasWindowFuncs) {
    _fingerprintString(ctx, "hasWindowFuncs");
    _fingerprintString(ctx, "true");
  }

  if (node->havingQual != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "havingQual");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->havingQual, node, "havingQual", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->isReturn) {
    _fingerprintString(ctx, "isReturn");
    _fingerprintString(ctx, "true");
  }

  if (node->jointree != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "jointree");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintFromExpr(ctx, node->jointree, node, "jointree", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->limitCount != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "limitCount");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->limitCount, node, "limitCount", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->limitOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "limitOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->limitOffset, node, "limitOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "limitOption");
    _fingerprintString(ctx, _enumToStringLimitOption(node->limitOption));
  }

  if (node->mergeActionList != NULL && node->mergeActionList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "mergeActionList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->mergeActionList, node, "mergeActionList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->mergeActionList) == 1 && linitial(node->mergeActionList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->mergeUseOuterJoin) {
    _fingerprintString(ctx, "mergeUseOuterJoin");
    _fingerprintString(ctx, "true");
  }

  if (node->onConflict != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "onConflict");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintOnConflictExpr(ctx, node->onConflict, node, "onConflict", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "override");
    _fingerprintString(ctx, _enumToStringOverridingKind(node->override));
  }

  if (node->queryId != 0) {
    char buffer[50];
    sprintf(buffer, "%ld", node->queryId);
    _fingerprintString(ctx, "queryId");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "querySource");
    _fingerprintString(ctx, _enumToStringQuerySource(node->querySource));
  }

  if (node->resultRelation != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->resultRelation);
    _fingerprintString(ctx, "resultRelation");
    _fingerprintString(ctx, buffer);
  }

  if (node->returningList != NULL && node->returningList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returningList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->returningList, node, "returningList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->returningList) == 1 && linitial(node->returningList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rowMarks != NULL && node->rowMarks->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rowMarks");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rowMarks, node, "rowMarks", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->rowMarks) == 1 && linitial(node->rowMarks) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rtable != NULL && node->rtable->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rtable");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rtable, node, "rtable", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->rtable) == 1 && linitial(node->rtable) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->setOperations != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "setOperations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->setOperations, node, "setOperations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->sortClause != NULL && node->sortClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sortClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->sortClause, node, "sortClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->sortClause) == 1 && linitial(node->sortClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->stmt_len != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->stmt_len);
    _fingerprintString(ctx, "stmt_len");
    _fingerprintString(ctx, buffer);
  }

  if (node->stmt_location != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->stmt_location);
    _fingerprintString(ctx, "stmt_location");
    _fingerprintString(ctx, buffer);
  }

  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->utilityStmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "utilityStmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->utilityStmt, node, "utilityStmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->windowClause != NULL && node->windowClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "windowClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->windowClause, node, "windowClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->windowClause) == 1 && linitial(node->windowClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->withCheckOptions != NULL && node->withCheckOptions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withCheckOptions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->withCheckOptions, node, "withCheckOptions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->withCheckOptions) == 1 && linitial(node->withCheckOptions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintInsertStmt(FingerprintContext *ctx, const InsertStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cols != NULL && node->cols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cols, node, "cols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cols) == 1 && linitial(node->cols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->onConflictClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "onConflictClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintOnConflictClause(ctx, node->onConflictClause, node, "onConflictClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "override");
    _fingerprintString(ctx, _enumToStringOverridingKind(node->override));
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->returningList != NULL && node->returningList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returningList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->returningList, node, "returningList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->returningList) == 1 && linitial(node->returningList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->selectStmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "selectStmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->selectStmt, node, "selectStmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->withClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWithClause(ctx, node->withClause, node, "withClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintDeleteStmt(FingerprintContext *ctx, const DeleteStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->returningList != NULL && node->returningList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returningList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->returningList, node, "returningList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->returningList) == 1 && linitial(node->returningList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->usingClause != NULL && node->usingClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "usingClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->usingClause, node, "usingClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->usingClause) == 1 && linitial(node->usingClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->withClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWithClause(ctx, node->withClause, node, "withClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintUpdateStmt(FingerprintContext *ctx, const UpdateStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fromClause != NULL && node->fromClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fromClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fromClause, node, "fromClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fromClause) == 1 && linitial(node->fromClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->returningList != NULL && node->returningList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returningList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->returningList, node, "returningList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->returningList) == 1 && linitial(node->returningList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->withClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWithClause(ctx, node->withClause, node, "withClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintMergeStmt(FingerprintContext *ctx, const MergeStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->joinCondition != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "joinCondition");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->joinCondition, node, "joinCondition", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->mergeWhenClauses != NULL && node->mergeWhenClauses->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "mergeWhenClauses");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->mergeWhenClauses, node, "mergeWhenClauses", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->mergeWhenClauses) == 1 && linitial(node->mergeWhenClauses) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->sourceRelation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sourceRelation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->sourceRelation, node, "sourceRelation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->withClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWithClause(ctx, node->withClause, node, "withClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintSelectStmt(FingerprintContext *ctx, const SelectStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->all) {
    _fingerprintString(ctx, "all");
    _fingerprintString(ctx, "true");
  }

  if (node->distinctClause != NULL && node->distinctClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "distinctClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->distinctClause, node, "distinctClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->distinctClause) == 1 && linitial(node->distinctClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->fromClause != NULL && node->fromClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fromClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fromClause, node, "fromClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fromClause) == 1 && linitial(node->fromClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->groupClause != NULL && node->groupClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "groupClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->groupClause, node, "groupClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->groupClause) == 1 && linitial(node->groupClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->groupDistinct) {
    _fingerprintString(ctx, "groupDistinct");
    _fingerprintString(ctx, "true");
  }

  if (node->havingClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "havingClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->havingClause, node, "havingClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->intoClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "intoClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintIntoClause(ctx, node->intoClause, node, "intoClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->larg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "larg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintSelectStmt(ctx, node->larg, node, "larg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->limitCount != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "limitCount");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->limitCount, node, "limitCount", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->limitOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "limitOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->limitOffset, node, "limitOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "limitOption");
    _fingerprintString(ctx, _enumToStringLimitOption(node->limitOption));
  }

  if (node->lockingClause != NULL && node->lockingClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "lockingClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->lockingClause, node, "lockingClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->lockingClause) == 1 && linitial(node->lockingClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "op");
    _fingerprintString(ctx, _enumToStringSetOperation(node->op));
  }

  if (node->rarg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rarg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintSelectStmt(ctx, node->rarg, node, "rarg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->sortClause != NULL && node->sortClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sortClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->sortClause, node, "sortClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->sortClause) == 1 && linitial(node->sortClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->valuesLists != NULL && node->valuesLists->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "valuesLists");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->valuesLists, node, "valuesLists", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->valuesLists) == 1 && linitial(node->valuesLists) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->windowClause != NULL && node->windowClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "windowClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->windowClause, node, "windowClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->windowClause) == 1 && linitial(node->windowClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->withClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "withClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWithClause(ctx, node->withClause, node, "withClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintReturnStmt(FingerprintContext *ctx, const ReturnStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->returnval != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returnval");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->returnval, node, "returnval", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintPLAssignStmt(FingerprintContext *ctx, const PLAssignStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->indirection != NULL && node->indirection->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indirection");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indirection, node, "indirection", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indirection) == 1 && linitial(node->indirection) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->nnames != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->nnames);
    _fingerprintString(ctx, "nnames");
    _fingerprintString(ctx, buffer);
  }

  if (node->val != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "val");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintSelectStmt(ctx, node->val, node, "val", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterTableStmt(FingerprintContext *ctx, const AlterTableStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cmds != NULL && node->cmds->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cmds");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cmds, node, "cmds", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cmds) == 1 && linitial(node->cmds) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterTableCmd(FingerprintContext *ctx, const AlterTableCmd *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->def != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "def");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->def, node, "def", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->newowner != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "newowner");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->newowner, node, "newowner", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->num != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->num);
    _fingerprintString(ctx, "num");
    _fingerprintString(ctx, buffer);
  }

  if (node->recurse) {
    _fingerprintString(ctx, "recurse");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "subtype");
    _fingerprintString(ctx, _enumToStringAlterTableType(node->subtype));
  }

}

static void
_fingerprintAlterDomainStmt(FingerprintContext *ctx, const AlterDomainStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->def != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "def");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->def, node, "def", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->subtype != 0) {
    char buffer[2] = {node->subtype, '\0'};
    _fingerprintString(ctx, "subtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeName != NULL && node->typeName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typeName) == 1 && linitial(node->typeName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintSetOperationStmt(FingerprintContext *ctx, const SetOperationStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->all) {
    _fingerprintString(ctx, "all");
    _fingerprintString(ctx, "true");
  }

  if (node->colCollations != NULL && node->colCollations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colCollations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colCollations, node, "colCollations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colCollations) == 1 && linitial(node->colCollations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->colTypes != NULL && node->colTypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colTypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colTypes, node, "colTypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colTypes) == 1 && linitial(node->colTypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->colTypmods != NULL && node->colTypmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colTypmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colTypmods, node, "colTypmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colTypmods) == 1 && linitial(node->colTypmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->groupClauses != NULL && node->groupClauses->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "groupClauses");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->groupClauses, node, "groupClauses", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->groupClauses) == 1 && linitial(node->groupClauses) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->larg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "larg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->larg, node, "larg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "op");
    _fingerprintString(ctx, _enumToStringSetOperation(node->op));
  }

  if (node->rarg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rarg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rarg, node, "rarg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintGrantStmt(FingerprintContext *ctx, const GrantStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->grant_option) {
    _fingerprintString(ctx, "grant_option");
    _fingerprintString(ctx, "true");
  }

  if (node->grantees != NULL && node->grantees->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "grantees");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->grantees, node, "grantees", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->grantees) == 1 && linitial(node->grantees) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->grantor != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "grantor");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->grantor, node, "grantor", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->is_grant) {
    _fingerprintString(ctx, "is_grant");
    _fingerprintString(ctx, "true");
  }

  if (node->objects != NULL && node->objects->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "objects");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->objects, node, "objects", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->objects) == 1 && linitial(node->objects) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

  if (node->privileges != NULL && node->privileges->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "privileges");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->privileges, node, "privileges", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->privileges) == 1 && linitial(node->privileges) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "targtype");
    _fingerprintString(ctx, _enumToStringGrantTargetType(node->targtype));
  }

}

static void
_fingerprintGrantRoleStmt(FingerprintContext *ctx, const GrantRoleStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->admin_opt) {
    _fingerprintString(ctx, "admin_opt");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->granted_roles != NULL && node->granted_roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "granted_roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->granted_roles, node, "granted_roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->granted_roles) == 1 && linitial(node->granted_roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->grantee_roles != NULL && node->grantee_roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "grantee_roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->grantee_roles, node, "grantee_roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->grantee_roles) == 1 && linitial(node->grantee_roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->grantor != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "grantor");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->grantor, node, "grantor", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->is_grant) {
    _fingerprintString(ctx, "is_grant");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintAlterDefaultPrivilegesStmt(FingerprintContext *ctx, const AlterDefaultPrivilegesStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->action != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "action");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintGrantStmt(ctx, node->action, node, "action", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintClosePortalStmt(FingerprintContext *ctx, const ClosePortalStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->portalname for fingerprinting

}

static void
_fingerprintClusterStmt(FingerprintContext *ctx, const ClusterStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->indexname != NULL) {
    _fingerprintString(ctx, "indexname");
    _fingerprintString(ctx, node->indexname);
  }

  if (node->params != NULL && node->params->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "params");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->params, node, "params", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->params) == 1 && linitial(node->params) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCopyStmt(FingerprintContext *ctx, const CopyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->attlist != NULL && node->attlist->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "attlist");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->attlist, node, "attlist", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->attlist) == 1 && linitial(node->attlist) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->filename != NULL) {
    _fingerprintString(ctx, "filename");
    _fingerprintString(ctx, node->filename);
  }

  if (node->is_from) {
    _fingerprintString(ctx, "is_from");
    _fingerprintString(ctx, "true");
  }

  if (node->is_program) {
    _fingerprintString(ctx, "is_program");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateStmt(FingerprintContext *ctx, const CreateStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->accessMethod != NULL) {
    _fingerprintString(ctx, "accessMethod");
    _fingerprintString(ctx, node->accessMethod);
  }

  if (node->constraints != NULL && node->constraints->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constraints");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->constraints, node, "constraints", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->constraints) == 1 && linitial(node->constraints) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->inhRelations != NULL && node->inhRelations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "inhRelations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->inhRelations, node, "inhRelations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->inhRelations) == 1 && linitial(node->inhRelations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ofTypename != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ofTypename");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->ofTypename, node, "ofTypename", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "oncommit");
    _fingerprintString(ctx, _enumToStringOnCommitAction(node->oncommit));
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->partbound != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "partbound");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintPartitionBoundSpec(ctx, node->partbound, node, "partbound", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->partspec != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "partspec");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintPartitionSpec(ctx, node->partspec, node, "partspec", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->tableElts != NULL && node->tableElts->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "tableElts");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->tableElts, node, "tableElts", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->tableElts) == 1 && linitial(node->tableElts) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->tablespacename != NULL) {
    _fingerprintString(ctx, "tablespacename");
    _fingerprintString(ctx, node->tablespacename);
  }

}

static void
_fingerprintDefineStmt(FingerprintContext *ctx, const DefineStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->definition != NULL && node->definition->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "definition");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->definition, node, "definition", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->definition) == 1 && linitial(node->definition) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->defnames != NULL && node->defnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "defnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->defnames, node, "defnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->defnames) == 1 && linitial(node->defnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringObjectType(node->kind));
  }

  if (node->oldstyle) {
    _fingerprintString(ctx, "oldstyle");
    _fingerprintString(ctx, "true");
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintDropStmt(FingerprintContext *ctx, const DropStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->concurrent) {
    _fingerprintString(ctx, "concurrent");
    _fingerprintString(ctx, "true");
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->objects != NULL && node->objects->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "objects");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->objects, node, "objects", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->objects) == 1 && linitial(node->objects) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "removeType");
    _fingerprintString(ctx, _enumToStringObjectType(node->removeType));
  }

}

static void
_fingerprintTruncateStmt(FingerprintContext *ctx, const TruncateStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->relations != NULL && node->relations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->relations, node, "relations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->relations) == 1 && linitial(node->relations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->restart_seqs) {
    _fingerprintString(ctx, "restart_seqs");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintCommentStmt(FingerprintContext *ctx, const CommentStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->comment != NULL) {
    _fingerprintString(ctx, "comment");
    _fingerprintString(ctx, node->comment);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

}

static void
_fingerprintFetchStmt(FingerprintContext *ctx, const FetchStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "direction");
    _fingerprintString(ctx, _enumToStringFetchDirection(node->direction));
  }

  if (node->howMany != 0) {
    char buffer[50];
    sprintf(buffer, "%ld", node->howMany);
    _fingerprintString(ctx, "howMany");
    _fingerprintString(ctx, buffer);
  }

  if (node->ismove) {
    _fingerprintString(ctx, "ismove");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->portalname for fingerprinting

}

static void
_fingerprintIndexStmt(FingerprintContext *ctx, const IndexStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->accessMethod != NULL) {
    _fingerprintString(ctx, "accessMethod");
    _fingerprintString(ctx, node->accessMethod);
  }

  if (node->concurrent) {
    _fingerprintString(ctx, "concurrent");
    _fingerprintString(ctx, "true");
  }

  if (node->deferrable) {
    _fingerprintString(ctx, "deferrable");
    _fingerprintString(ctx, "true");
  }

  if (node->excludeOpNames != NULL && node->excludeOpNames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "excludeOpNames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->excludeOpNames, node, "excludeOpNames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->excludeOpNames) == 1 && linitial(node->excludeOpNames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->idxcomment != NULL) {
    _fingerprintString(ctx, "idxcomment");
    _fingerprintString(ctx, node->idxcomment);
  }

  if (node->idxname != NULL) {
    _fingerprintString(ctx, "idxname");
    _fingerprintString(ctx, node->idxname);
  }

  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->indexIncludingParams != NULL && node->indexIncludingParams->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indexIncludingParams");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indexIncludingParams, node, "indexIncludingParams", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indexIncludingParams) == 1 && linitial(node->indexIncludingParams) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->indexOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->indexOid);
    _fingerprintString(ctx, "indexOid");
    _fingerprintString(ctx, buffer);
  }

  if (node->indexParams != NULL && node->indexParams->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indexParams");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indexParams, node, "indexParams", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indexParams) == 1 && linitial(node->indexParams) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->initdeferred) {
    _fingerprintString(ctx, "initdeferred");
    _fingerprintString(ctx, "true");
  }

  if (node->isconstraint) {
    _fingerprintString(ctx, "isconstraint");
    _fingerprintString(ctx, "true");
  }

  if (node->nulls_not_distinct) {
    _fingerprintString(ctx, "nulls_not_distinct");
    _fingerprintString(ctx, "true");
  }

  if (node->oldCreateSubid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->oldCreateSubid);
    _fingerprintString(ctx, "oldCreateSubid");
    _fingerprintString(ctx, buffer);
  }

  if (node->oldFirstRelfilenodeSubid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->oldFirstRelfilenodeSubid);
    _fingerprintString(ctx, "oldFirstRelfilenodeSubid");
    _fingerprintString(ctx, buffer);
  }

  if (node->oldNode != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->oldNode);
    _fingerprintString(ctx, "oldNode");
    _fingerprintString(ctx, buffer);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->primary) {
    _fingerprintString(ctx, "primary");
    _fingerprintString(ctx, "true");
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->reset_default_tblspc) {
    _fingerprintString(ctx, "reset_default_tblspc");
    _fingerprintString(ctx, "true");
  }

  if (node->tableSpace != NULL) {
    _fingerprintString(ctx, "tableSpace");
    _fingerprintString(ctx, node->tableSpace);
  }

  if (node->transformed) {
    _fingerprintString(ctx, "transformed");
    _fingerprintString(ctx, "true");
  }

  if (node->unique) {
    _fingerprintString(ctx, "unique");
    _fingerprintString(ctx, "true");
  }

  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateFunctionStmt(FingerprintContext *ctx, const CreateFunctionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->funcname != NULL && node->funcname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funcname, node, "funcname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funcname) == 1 && linitial(node->funcname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->is_procedure) {
    _fingerprintString(ctx, "is_procedure");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->options for fingerprinting

  if (node->parameters != NULL && node->parameters->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "parameters");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->parameters, node, "parameters", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->parameters) == 1 && linitial(node->parameters) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->returnType != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "returnType");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->returnType, node, "returnType", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->sql_body != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sql_body");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->sql_body, node, "sql_body", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterFunctionStmt(FingerprintContext *ctx, const AlterFunctionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->actions != NULL && node->actions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "actions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->actions, node, "actions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->actions) == 1 && linitial(node->actions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->func != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "func");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->func, node, "func", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

}

static void
_fingerprintDoStmt(FingerprintContext *ctx, const DoStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->args for fingerprinting

}

static void
_fingerprintRenameStmt(FingerprintContext *ctx, const RenameStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->newname != NULL) {
    _fingerprintString(ctx, "newname");
    _fingerprintString(ctx, node->newname);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "relationType");
    _fingerprintString(ctx, _enumToStringObjectType(node->relationType));
  }

  if (true) {
    _fingerprintString(ctx, "renameType");
    _fingerprintString(ctx, _enumToStringObjectType(node->renameType));
  }

  if (node->subname != NULL) {
    _fingerprintString(ctx, "subname");
    _fingerprintString(ctx, node->subname);
  }

}

static void
_fingerprintRuleStmt(FingerprintContext *ctx, const RuleStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->actions != NULL && node->actions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "actions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->actions, node, "actions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->actions) == 1 && linitial(node->actions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "event");
    _fingerprintString(ctx, _enumToStringCmdType(node->event));
  }

  if (node->instead) {
    _fingerprintString(ctx, "instead");
    _fingerprintString(ctx, "true");
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->rulename != NULL) {
    _fingerprintString(ctx, "rulename");
    _fingerprintString(ctx, node->rulename);
  }

  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintNotifyStmt(FingerprintContext *ctx, const NotifyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->conditionname for fingerprinting

  if (node->payload != NULL) {
    _fingerprintString(ctx, "payload");
    _fingerprintString(ctx, node->payload);
  }

}

static void
_fingerprintListenStmt(FingerprintContext *ctx, const ListenStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->conditionname for fingerprinting

}

static void
_fingerprintUnlistenStmt(FingerprintContext *ctx, const UnlistenStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->conditionname for fingerprinting

}

static void
_fingerprintTransactionStmt(FingerprintContext *ctx, const TransactionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->chain) {
    _fingerprintString(ctx, "chain");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->gid for fingerprinting

  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringTransactionStmtKind(node->kind));
  }

  // Intentionally ignoring node->options for fingerprinting

  // Intentionally ignoring node->savepoint_name for fingerprinting

}

static void
_fingerprintViewStmt(FingerprintContext *ctx, const ViewStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->aliases != NULL && node->aliases->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aliases");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aliases, node, "aliases", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aliases) == 1 && linitial(node->aliases) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->view != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "view");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->view, node, "view", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "withCheckOption");
    _fingerprintString(ctx, _enumToStringViewCheckOption(node->withCheckOption));
  }

}

static void
_fingerprintLoadStmt(FingerprintContext *ctx, const LoadStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->filename != NULL) {
    _fingerprintString(ctx, "filename");
    _fingerprintString(ctx, node->filename);
  }

}

static void
_fingerprintCreateDomainStmt(FingerprintContext *ctx, const CreateDomainStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintCollateClause(ctx, node->collClause, node, "collClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->constraints != NULL && node->constraints->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constraints");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->constraints, node, "constraints", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->constraints) == 1 && linitial(node->constraints) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->domainname != NULL && node->domainname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "domainname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->domainname, node, "domainname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->domainname) == 1 && linitial(node->domainname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->typeName != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreatedbStmt(FingerprintContext *ctx, const CreatedbStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dbname != NULL) {
    _fingerprintString(ctx, "dbname");
    _fingerprintString(ctx, node->dbname);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintDropdbStmt(FingerprintContext *ctx, const DropdbStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dbname != NULL) {
    _fingerprintString(ctx, "dbname");
    _fingerprintString(ctx, node->dbname);
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintVacuumStmt(FingerprintContext *ctx, const VacuumStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->is_vacuumcmd) {
    _fingerprintString(ctx, "is_vacuumcmd");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rels != NULL && node->rels->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rels");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rels, node, "rels", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->rels) == 1 && linitial(node->rels) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintExplainStmt(FingerprintContext *ctx, const ExplainStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateTableAsStmt(FingerprintContext *ctx, const CreateTableAsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->into != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "into");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintIntoClause(ctx, node->into, node, "into", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->is_select_into) {
    _fingerprintString(ctx, "is_select_into");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateSeqStmt(FingerprintContext *ctx, const CreateSeqStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->for_identity) {
    _fingerprintString(ctx, "for_identity");
    _fingerprintString(ctx, "true");
  }

  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ownerId != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->ownerId);
    _fingerprintString(ctx, "ownerId");
    _fingerprintString(ctx, buffer);
  }

  if (node->sequence != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sequence");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->sequence, node, "sequence", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterSeqStmt(FingerprintContext *ctx, const AlterSeqStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->for_identity) {
    _fingerprintString(ctx, "for_identity");
    _fingerprintString(ctx, "true");
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->sequence != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sequence");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->sequence, node, "sequence", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintVariableSetStmt(FingerprintContext *ctx, const VariableSetStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->is_local) {
    _fingerprintString(ctx, "is_local");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringVariableSetKind(node->kind));
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintVariableShowStmt(FingerprintContext *ctx, const VariableShowStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintDiscardStmt(FingerprintContext *ctx, const DiscardStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "target");
    _fingerprintString(ctx, _enumToStringDiscardMode(node->target));
  }

}

static void
_fingerprintCreateTrigStmt(FingerprintContext *ctx, const CreateTrigStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->columns != NULL && node->columns->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "columns");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->columns, node, "columns", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->columns) == 1 && linitial(node->columns) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->constrrel != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constrrel");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->constrrel, node, "constrrel", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->deferrable) {
    _fingerprintString(ctx, "deferrable");
    _fingerprintString(ctx, "true");
  }

  if (node->events != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->events);
    _fingerprintString(ctx, "events");
    _fingerprintString(ctx, buffer);
  }

  if (node->funcname != NULL && node->funcname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funcname, node, "funcname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funcname) == 1 && linitial(node->funcname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->initdeferred) {
    _fingerprintString(ctx, "initdeferred");
    _fingerprintString(ctx, "true");
  }

  if (node->isconstraint) {
    _fingerprintString(ctx, "isconstraint");
    _fingerprintString(ctx, "true");
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->row) {
    _fingerprintString(ctx, "row");
    _fingerprintString(ctx, "true");
  }

  if (node->timing != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->timing);
    _fingerprintString(ctx, "timing");
    _fingerprintString(ctx, buffer);
  }

  if (node->transitionRels != NULL && node->transitionRels->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "transitionRels");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->transitionRels, node, "transitionRels", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->transitionRels) == 1 && linitial(node->transitionRels) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->trigname != NULL) {
    _fingerprintString(ctx, "trigname");
    _fingerprintString(ctx, node->trigname);
  }

  if (node->whenClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whenClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whenClause, node, "whenClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreatePLangStmt(FingerprintContext *ctx, const CreatePLangStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->plhandler != NULL && node->plhandler->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "plhandler");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->plhandler, node, "plhandler", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->plhandler) == 1 && linitial(node->plhandler) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->plinline != NULL && node->plinline->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "plinline");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->plinline, node, "plinline", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->plinline) == 1 && linitial(node->plinline) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->plname != NULL) {
    _fingerprintString(ctx, "plname");
    _fingerprintString(ctx, node->plname);
  }

  if (node->pltrusted) {
    _fingerprintString(ctx, "pltrusted");
    _fingerprintString(ctx, "true");
  }

  if (node->plvalidator != NULL && node->plvalidator->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "plvalidator");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->plvalidator, node, "plvalidator", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->plvalidator) == 1 && linitial(node->plvalidator) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintCreateRoleStmt(FingerprintContext *ctx, const CreateRoleStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->role != NULL) {
    _fingerprintString(ctx, "role");
    _fingerprintString(ctx, node->role);
  }

  if (true) {
    _fingerprintString(ctx, "stmt_type");
    _fingerprintString(ctx, _enumToStringRoleStmtType(node->stmt_type));
  }

}

static void
_fingerprintAlterRoleStmt(FingerprintContext *ctx, const AlterRoleStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->action != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->action);
    _fingerprintString(ctx, "action");
    _fingerprintString(ctx, buffer);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->role != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "role");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->role, node, "role", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintDropRoleStmt(FingerprintContext *ctx, const DropRoleStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintLockStmt(FingerprintContext *ctx, const LockStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->mode != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->mode);
    _fingerprintString(ctx, "mode");
    _fingerprintString(ctx, buffer);
  }

  if (node->nowait) {
    _fingerprintString(ctx, "nowait");
    _fingerprintString(ctx, "true");
  }

  if (node->relations != NULL && node->relations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->relations, node, "relations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->relations) == 1 && linitial(node->relations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintConstraintsSetStmt(FingerprintContext *ctx, const ConstraintsSetStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->constraints != NULL && node->constraints->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constraints");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->constraints, node, "constraints", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->constraints) == 1 && linitial(node->constraints) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->deferred) {
    _fingerprintString(ctx, "deferred");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintReindexStmt(FingerprintContext *ctx, const ReindexStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringReindexObjectType(node->kind));
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->params != NULL && node->params->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "params");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->params, node, "params", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->params) == 1 && linitial(node->params) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCheckPointStmt(FingerprintContext *ctx, const CheckPointStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
}

static void
_fingerprintCreateSchemaStmt(FingerprintContext *ctx, const CreateSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->authrole != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "authrole");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->authrole, node, "authrole", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->schemaElts != NULL && node->schemaElts->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "schemaElts");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->schemaElts, node, "schemaElts", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->schemaElts) == 1 && linitial(node->schemaElts) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->schemaname != NULL) {
    _fingerprintString(ctx, "schemaname");
    _fingerprintString(ctx, node->schemaname);
  }

}

static void
_fingerprintAlterDatabaseStmt(FingerprintContext *ctx, const AlterDatabaseStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dbname != NULL) {
    _fingerprintString(ctx, "dbname");
    _fingerprintString(ctx, node->dbname);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterDatabaseRefreshCollStmt(FingerprintContext *ctx, const AlterDatabaseRefreshCollStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dbname != NULL) {
    _fingerprintString(ctx, "dbname");
    _fingerprintString(ctx, node->dbname);
  }

}

static void
_fingerprintAlterDatabaseSetStmt(FingerprintContext *ctx, const AlterDatabaseSetStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dbname != NULL) {
    _fingerprintString(ctx, "dbname");
    _fingerprintString(ctx, node->dbname);
  }

  if (node->setstmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "setstmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintVariableSetStmt(ctx, node->setstmt, node, "setstmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterRoleSetStmt(FingerprintContext *ctx, const AlterRoleSetStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->database != NULL) {
    _fingerprintString(ctx, "database");
    _fingerprintString(ctx, node->database);
  }

  if (node->role != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "role");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->role, node, "role", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->setstmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "setstmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintVariableSetStmt(ctx, node->setstmt, node, "setstmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateConversionStmt(FingerprintContext *ctx, const CreateConversionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->conversion_name != NULL && node->conversion_name->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "conversion_name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->conversion_name, node, "conversion_name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->conversion_name) == 1 && linitial(node->conversion_name) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->def) {
    _fingerprintString(ctx, "def");
    _fingerprintString(ctx, "true");
  }

  if (node->for_encoding_name != NULL) {
    _fingerprintString(ctx, "for_encoding_name");
    _fingerprintString(ctx, node->for_encoding_name);
  }

  if (node->func_name != NULL && node->func_name->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "func_name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->func_name, node, "func_name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->func_name) == 1 && linitial(node->func_name) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->to_encoding_name != NULL) {
    _fingerprintString(ctx, "to_encoding_name");
    _fingerprintString(ctx, node->to_encoding_name);
  }

}

static void
_fingerprintCreateCastStmt(FingerprintContext *ctx, const CreateCastStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "context");
    _fingerprintString(ctx, _enumToStringCoercionContext(node->context));
  }

  if (node->func != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "func");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->func, node, "func", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->inout) {
    _fingerprintString(ctx, "inout");
    _fingerprintString(ctx, "true");
  }

  if (node->sourcetype != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "sourcetype");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->sourcetype, node, "sourcetype", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->targettype != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targettype");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->targettype, node, "targettype", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateOpClassStmt(FingerprintContext *ctx, const CreateOpClassStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->amname != NULL) {
    _fingerprintString(ctx, "amname");
    _fingerprintString(ctx, node->amname);
  }

  if (node->datatype != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "datatype");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->datatype, node, "datatype", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->isDefault) {
    _fingerprintString(ctx, "isDefault");
    _fingerprintString(ctx, "true");
  }

  if (node->items != NULL && node->items->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "items");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->items, node, "items", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->items) == 1 && linitial(node->items) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opclassname != NULL && node->opclassname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opclassname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opclassname, node, "opclassname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opclassname) == 1 && linitial(node->opclassname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opfamilyname != NULL && node->opfamilyname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opfamilyname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opfamilyname, node, "opfamilyname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opfamilyname) == 1 && linitial(node->opfamilyname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateOpFamilyStmt(FingerprintContext *ctx, const CreateOpFamilyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->amname != NULL) {
    _fingerprintString(ctx, "amname");
    _fingerprintString(ctx, node->amname);
  }

  if (node->opfamilyname != NULL && node->opfamilyname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opfamilyname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opfamilyname, node, "opfamilyname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opfamilyname) == 1 && linitial(node->opfamilyname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterOpFamilyStmt(FingerprintContext *ctx, const AlterOpFamilyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->amname != NULL) {
    _fingerprintString(ctx, "amname");
    _fingerprintString(ctx, node->amname);
  }

  if (node->isDrop) {
    _fingerprintString(ctx, "isDrop");
    _fingerprintString(ctx, "true");
  }

  if (node->items != NULL && node->items->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "items");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->items, node, "items", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->items) == 1 && linitial(node->items) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opfamilyname != NULL && node->opfamilyname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opfamilyname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opfamilyname, node, "opfamilyname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opfamilyname) == 1 && linitial(node->opfamilyname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintPrepareStmt(FingerprintContext *ctx, const PrepareStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->argtypes != NULL && node->argtypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "argtypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->argtypes, node, "argtypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->argtypes) == 1 && linitial(node->argtypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->name for fingerprinting

  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintExecuteStmt(FingerprintContext *ctx, const ExecuteStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->name for fingerprinting

  if (node->params != NULL && node->params->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "params");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->params, node, "params", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->params) == 1 && linitial(node->params) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintDeallocateStmt(FingerprintContext *ctx, const DeallocateStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->name for fingerprinting

}

static void
_fingerprintDeclareCursorStmt(FingerprintContext *ctx, const DeclareCursorStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->options);
    _fingerprintString(ctx, "options");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->portalname for fingerprinting

  if (node->query != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "query");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->query, node, "query", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateTableSpaceStmt(FingerprintContext *ctx, const CreateTableSpaceStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->owner != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "owner");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->owner, node, "owner", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->tablespacename != NULL) {
    _fingerprintString(ctx, "tablespacename");
    _fingerprintString(ctx, node->tablespacename);
  }

}

static void
_fingerprintDropTableSpaceStmt(FingerprintContext *ctx, const DropTableSpaceStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->tablespacename != NULL) {
    _fingerprintString(ctx, "tablespacename");
    _fingerprintString(ctx, node->tablespacename);
  }

}

static void
_fingerprintAlterObjectDependsStmt(FingerprintContext *ctx, const AlterObjectDependsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (strlen(node->extname->sval) > 0) {
    _fingerprintString(ctx, "extname");
    _fingerprintString(ctx, node->extname->sval);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objectType");
    _fingerprintString(ctx, _enumToStringObjectType(node->objectType));
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->remove) {
    _fingerprintString(ctx, "remove");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintAlterObjectSchemaStmt(FingerprintContext *ctx, const AlterObjectSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->newschema != NULL) {
    _fingerprintString(ctx, "newschema");
    _fingerprintString(ctx, node->newschema);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objectType");
    _fingerprintString(ctx, _enumToStringObjectType(node->objectType));
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterOwnerStmt(FingerprintContext *ctx, const AlterOwnerStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->newowner != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "newowner");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->newowner, node, "newowner", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objectType");
    _fingerprintString(ctx, _enumToStringObjectType(node->objectType));
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterOperatorStmt(FingerprintContext *ctx, const AlterOperatorStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->opername != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opername");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->opername, node, "opername", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterTypeStmt(FingerprintContext *ctx, const AlterTypeStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->typeName != NULL && node->typeName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typeName) == 1 && linitial(node->typeName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintDropOwnedStmt(FingerprintContext *ctx, const DropOwnedStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintReassignOwnedStmt(FingerprintContext *ctx, const ReassignOwnedStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->newrole != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "newrole");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->newrole, node, "newrole", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCompositeTypeStmt(FingerprintContext *ctx, const CompositeTypeStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->coldeflist != NULL && node->coldeflist->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coldeflist");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coldeflist, node, "coldeflist", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coldeflist) == 1 && linitial(node->coldeflist) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->typevar != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typevar");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->typevar, node, "typevar", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateEnumStmt(FingerprintContext *ctx, const CreateEnumStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->typeName != NULL && node->typeName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typeName) == 1 && linitial(node->typeName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->vals != NULL && node->vals->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "vals");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->vals, node, "vals", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->vals) == 1 && linitial(node->vals) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateRangeStmt(FingerprintContext *ctx, const CreateRangeStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->params != NULL && node->params->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "params");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->params, node, "params", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->params) == 1 && linitial(node->params) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->typeName != NULL && node->typeName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typeName) == 1 && linitial(node->typeName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterEnumStmt(FingerprintContext *ctx, const AlterEnumStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->newVal != NULL) {
    _fingerprintString(ctx, "newVal");
    _fingerprintString(ctx, node->newVal);
  }

  if (node->newValIsAfter) {
    _fingerprintString(ctx, "newValIsAfter");
    _fingerprintString(ctx, "true");
  }

  if (node->newValNeighbor != NULL) {
    _fingerprintString(ctx, "newValNeighbor");
    _fingerprintString(ctx, node->newValNeighbor);
  }

  if (node->oldVal != NULL) {
    _fingerprintString(ctx, "oldVal");
    _fingerprintString(ctx, node->oldVal);
  }

  if (node->skipIfNewValExists) {
    _fingerprintString(ctx, "skipIfNewValExists");
    _fingerprintString(ctx, "true");
  }

  if (node->typeName != NULL && node->typeName->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typeName) == 1 && linitial(node->typeName) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterTSDictionaryStmt(FingerprintContext *ctx, const AlterTSDictionaryStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->dictname != NULL && node->dictname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "dictname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->dictname, node, "dictname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->dictname) == 1 && linitial(node->dictname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterTSConfigurationStmt(FingerprintContext *ctx, const AlterTSConfigurationStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cfgname != NULL && node->cfgname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cfgname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cfgname, node, "cfgname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cfgname) == 1 && linitial(node->cfgname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->dicts != NULL && node->dicts->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "dicts");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->dicts, node, "dicts", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->dicts) == 1 && linitial(node->dicts) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringAlterTSConfigType(node->kind));
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->override) {
    _fingerprintString(ctx, "override");
    _fingerprintString(ctx, "true");
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->tokentype != NULL && node->tokentype->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "tokentype");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->tokentype, node, "tokentype", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->tokentype) == 1 && linitial(node->tokentype) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateFdwStmt(FingerprintContext *ctx, const CreateFdwStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fdwname != NULL) {
    _fingerprintString(ctx, "fdwname");
    _fingerprintString(ctx, node->fdwname);
  }

  if (node->func_options != NULL && node->func_options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "func_options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->func_options, node, "func_options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->func_options) == 1 && linitial(node->func_options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterFdwStmt(FingerprintContext *ctx, const AlterFdwStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fdwname != NULL) {
    _fingerprintString(ctx, "fdwname");
    _fingerprintString(ctx, node->fdwname);
  }

  if (node->func_options != NULL && node->func_options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "func_options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->func_options, node, "func_options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->func_options) == 1 && linitial(node->func_options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateForeignServerStmt(FingerprintContext *ctx, const CreateForeignServerStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fdwname != NULL) {
    _fingerprintString(ctx, "fdwname");
    _fingerprintString(ctx, node->fdwname);
  }

  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

  if (node->servertype != NULL) {
    _fingerprintString(ctx, "servertype");
    _fingerprintString(ctx, node->servertype);
  }

  if (node->version != NULL) {
    _fingerprintString(ctx, "version");
    _fingerprintString(ctx, node->version);
  }

}

static void
_fingerprintAlterForeignServerStmt(FingerprintContext *ctx, const AlterForeignServerStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->has_version) {
    _fingerprintString(ctx, "has_version");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

  if (node->version != NULL) {
    _fingerprintString(ctx, "version");
    _fingerprintString(ctx, node->version);
  }

}

static void
_fingerprintCreateUserMappingStmt(FingerprintContext *ctx, const CreateUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

  if (node->user != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "user");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->user, node, "user", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterUserMappingStmt(FingerprintContext *ctx, const AlterUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

  if (node->user != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "user");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->user, node, "user", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintDropUserMappingStmt(FingerprintContext *ctx, const DropUserMappingStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

  if (node->user != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "user");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRoleSpec(ctx, node->user, node, "user", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterTableSpaceOptionsStmt(FingerprintContext *ctx, const AlterTableSpaceOptionsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->isReset) {
    _fingerprintString(ctx, "isReset");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->tablespacename != NULL) {
    _fingerprintString(ctx, "tablespacename");
    _fingerprintString(ctx, node->tablespacename);
  }

}

static void
_fingerprintAlterTableMoveAllStmt(FingerprintContext *ctx, const AlterTableMoveAllStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->new_tablespacename != NULL) {
    _fingerprintString(ctx, "new_tablespacename");
    _fingerprintString(ctx, node->new_tablespacename);
  }

  if (node->nowait) {
    _fingerprintString(ctx, "nowait");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

  if (node->orig_tablespacename != NULL) {
    _fingerprintString(ctx, "orig_tablespacename");
    _fingerprintString(ctx, node->orig_tablespacename);
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintSecLabelStmt(FingerprintContext *ctx, const SecLabelStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->label != NULL) {
    _fingerprintString(ctx, "label");
    _fingerprintString(ctx, node->label);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

  if (node->provider != NULL) {
    _fingerprintString(ctx, "provider");
    _fingerprintString(ctx, node->provider);
  }

}

static void
_fingerprintCreateForeignTableStmt(FingerprintContext *ctx, const CreateForeignTableStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  _fingerprintString(ctx, "base");
  _fingerprintCreateStmt(ctx, (const CreateStmt*) &node->base, node, "base", depth);
  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->servername != NULL) {
    _fingerprintString(ctx, "servername");
    _fingerprintString(ctx, node->servername);
  }

}

static void
_fingerprintImportForeignSchemaStmt(FingerprintContext *ctx, const ImportForeignSchemaStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "list_type");
    _fingerprintString(ctx, _enumToStringImportForeignSchemaType(node->list_type));
  }

  if (node->local_schema != NULL) {
    _fingerprintString(ctx, "local_schema");
    _fingerprintString(ctx, node->local_schema);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->remote_schema != NULL) {
    _fingerprintString(ctx, "remote_schema");
    _fingerprintString(ctx, node->remote_schema);
  }

  if (node->server_name != NULL) {
    _fingerprintString(ctx, "server_name");
    _fingerprintString(ctx, node->server_name);
  }

  if (node->table_list != NULL && node->table_list->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "table_list");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->table_list, node, "table_list", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->table_list) == 1 && linitial(node->table_list) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateExtensionStmt(FingerprintContext *ctx, const CreateExtensionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->extname != NULL) {
    _fingerprintString(ctx, "extname");
    _fingerprintString(ctx, node->extname);
  }

  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterExtensionStmt(FingerprintContext *ctx, const AlterExtensionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->extname != NULL) {
    _fingerprintString(ctx, "extname");
    _fingerprintString(ctx, node->extname);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterExtensionContentsStmt(FingerprintContext *ctx, const AlterExtensionContentsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->action != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->action);
    _fingerprintString(ctx, "action");
    _fingerprintString(ctx, buffer);
  }

  if (node->extname != NULL) {
    _fingerprintString(ctx, "extname");
    _fingerprintString(ctx, node->extname);
  }

  if (node->object != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "object");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->object, node, "object", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "objtype");
    _fingerprintString(ctx, _enumToStringObjectType(node->objtype));
  }

}

static void
_fingerprintCreateEventTrigStmt(FingerprintContext *ctx, const CreateEventTrigStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->eventname != NULL) {
    _fingerprintString(ctx, "eventname");
    _fingerprintString(ctx, node->eventname);
  }

  if (node->funcname != NULL && node->funcname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funcname, node, "funcname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funcname) == 1 && linitial(node->funcname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->trigname != NULL) {
    _fingerprintString(ctx, "trigname");
    _fingerprintString(ctx, node->trigname);
  }

  if (node->whenclause != NULL && node->whenclause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whenclause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whenclause, node, "whenclause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->whenclause) == 1 && linitial(node->whenclause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterEventTrigStmt(FingerprintContext *ctx, const AlterEventTrigStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->tgenabled != 0) {
    char buffer[2] = {node->tgenabled, '\0'};
    _fingerprintString(ctx, "tgenabled");
    _fingerprintString(ctx, buffer);
  }

  if (node->trigname != NULL) {
    _fingerprintString(ctx, "trigname");
    _fingerprintString(ctx, node->trigname);
  }

}

static void
_fingerprintRefreshMatViewStmt(FingerprintContext *ctx, const RefreshMatViewStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->concurrent) {
    _fingerprintString(ctx, "concurrent");
    _fingerprintString(ctx, "true");
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->skipData) {
    _fingerprintString(ctx, "skipData");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintReplicaIdentityStmt(FingerprintContext *ctx, const ReplicaIdentityStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->identity_type != 0) {
    char buffer[2] = {node->identity_type, '\0'};
    _fingerprintString(ctx, "identity_type");
    _fingerprintString(ctx, buffer);
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintAlterSystemStmt(FingerprintContext *ctx, const AlterSystemStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->setstmt != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "setstmt");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintVariableSetStmt(ctx, node->setstmt, node, "setstmt", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreatePolicyStmt(FingerprintContext *ctx, const CreatePolicyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cmd_name != NULL) {
    _fingerprintString(ctx, "cmd_name");
    _fingerprintString(ctx, node->cmd_name);
  }

  if (node->permissive) {
    _fingerprintString(ctx, "permissive");
    _fingerprintString(ctx, "true");
  }

  if (node->policy_name != NULL) {
    _fingerprintString(ctx, "policy_name");
    _fingerprintString(ctx, node->policy_name);
  }

  if (node->qual != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "qual");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->qual, node, "qual", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->table != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "table");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->table, node, "table", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->with_check != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "with_check");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->with_check, node, "with_check", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintAlterPolicyStmt(FingerprintContext *ctx, const AlterPolicyStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->policy_name != NULL) {
    _fingerprintString(ctx, "policy_name");
    _fingerprintString(ctx, node->policy_name);
  }

  if (node->qual != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "qual");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->qual, node, "qual", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->roles != NULL && node->roles->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "roles");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->roles, node, "roles", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->roles) == 1 && linitial(node->roles) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->table != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "table");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->table, node, "table", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->with_check != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "with_check");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->with_check, node, "with_check", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateTransformStmt(FingerprintContext *ctx, const CreateTransformStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fromsql != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fromsql");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->fromsql, node, "fromsql", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->lang != NULL) {
    _fingerprintString(ctx, "lang");
    _fingerprintString(ctx, node->lang);
  }

  if (node->replace) {
    _fingerprintString(ctx, "replace");
    _fingerprintString(ctx, "true");
  }

  if (node->tosql != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "tosql");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->tosql, node, "tosql", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->type_name != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "type_name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->type_name, node, "type_name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCreateAmStmt(FingerprintContext *ctx, const CreateAmStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->amname != NULL) {
    _fingerprintString(ctx, "amname");
    _fingerprintString(ctx, node->amname);
  }

  if (node->amtype != 0) {
    char buffer[2] = {node->amtype, '\0'};
    _fingerprintString(ctx, "amtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->handler_name != NULL && node->handler_name->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "handler_name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->handler_name, node, "handler_name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->handler_name) == 1 && linitial(node->handler_name) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreatePublicationStmt(FingerprintContext *ctx, const CreatePublicationStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->for_all_tables) {
    _fingerprintString(ctx, "for_all_tables");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->pubname != NULL) {
    _fingerprintString(ctx, "pubname");
    _fingerprintString(ctx, node->pubname);
  }

  if (node->pubobjects != NULL && node->pubobjects->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "pubobjects");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->pubobjects, node, "pubobjects", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->pubobjects) == 1 && linitial(node->pubobjects) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterPublicationStmt(FingerprintContext *ctx, const AlterPublicationStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "action");
    _fingerprintString(ctx, _enumToStringAlterPublicationAction(node->action));
  }

  if (node->for_all_tables) {
    _fingerprintString(ctx, "for_all_tables");
    _fingerprintString(ctx, "true");
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->pubname != NULL) {
    _fingerprintString(ctx, "pubname");
    _fingerprintString(ctx, node->pubname);
  }

  if (node->pubobjects != NULL && node->pubobjects->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "pubobjects");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->pubobjects, node, "pubobjects", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->pubobjects) == 1 && linitial(node->pubobjects) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCreateSubscriptionStmt(FingerprintContext *ctx, const CreateSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->conninfo != NULL) {
    _fingerprintString(ctx, "conninfo");
    _fingerprintString(ctx, node->conninfo);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->publication != NULL && node->publication->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "publication");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->publication, node, "publication", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->publication) == 1 && linitial(node->publication) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->subname != NULL) {
    _fingerprintString(ctx, "subname");
    _fingerprintString(ctx, node->subname);
  }

}

static void
_fingerprintAlterSubscriptionStmt(FingerprintContext *ctx, const AlterSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->conninfo != NULL) {
    _fingerprintString(ctx, "conninfo");
    _fingerprintString(ctx, node->conninfo);
  }

  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringAlterSubscriptionType(node->kind));
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->publication != NULL && node->publication->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "publication");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->publication, node, "publication", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->publication) == 1 && linitial(node->publication) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->subname != NULL) {
    _fingerprintString(ctx, "subname");
    _fingerprintString(ctx, node->subname);
  }

}

static void
_fingerprintDropSubscriptionStmt(FingerprintContext *ctx, const DropSubscriptionStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "behavior");
    _fingerprintString(ctx, _enumToStringDropBehavior(node->behavior));
  }

  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->subname != NULL) {
    _fingerprintString(ctx, "subname");
    _fingerprintString(ctx, node->subname);
  }

}

static void
_fingerprintCreateStatsStmt(FingerprintContext *ctx, const CreateStatsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->defnames != NULL && node->defnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "defnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->defnames, node, "defnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->defnames) == 1 && linitial(node->defnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->exprs != NULL && node->exprs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "exprs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->exprs, node, "exprs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->exprs) == 1 && linitial(node->exprs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->if_not_exists) {
    _fingerprintString(ctx, "if_not_exists");
    _fingerprintString(ctx, "true");
  }

  if (node->relations != NULL && node->relations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->relations, node, "relations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->relations) == 1 && linitial(node->relations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->stat_types != NULL && node->stat_types->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "stat_types");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->stat_types, node, "stat_types", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->stat_types) == 1 && linitial(node->stat_types) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->stxcomment != NULL) {
    _fingerprintString(ctx, "stxcomment");
    _fingerprintString(ctx, node->stxcomment);
  }

  if (node->transformed) {
    _fingerprintString(ctx, "transformed");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintAlterCollationStmt(FingerprintContext *ctx, const AlterCollationStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collname != NULL && node->collname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->collname, node, "collname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->collname) == 1 && linitial(node->collname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintCallStmt(FingerprintContext *ctx, const CallStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->funccall != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funccall");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintFuncCall(ctx, node->funccall, node, "funccall", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->funcexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintFuncExpr(ctx, node->funcexpr, node, "funcexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->outargs != NULL && node->outargs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "outargs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->outargs, node, "outargs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->outargs) == 1 && linitial(node->outargs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAlterStatsStmt(FingerprintContext *ctx, const AlterStatsStmt *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->defnames != NULL && node->defnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "defnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->defnames, node, "defnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->defnames) == 1 && linitial(node->defnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->missing_ok) {
    _fingerprintString(ctx, "missing_ok");
    _fingerprintString(ctx, "true");
  }

  if (node->stxstattarget != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->stxstattarget);
    _fingerprintString(ctx, "stxstattarget");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintA_Expr(FingerprintContext *ctx, const A_Expr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "kind");
    if (node->kind == AEXPR_OP_ANY || node->kind == AEXPR_IN)
      _fingerprintString(ctx, "AEXPR_OP");
    else
      _fingerprintString(ctx, _enumToStringA_Expr_Kind(node->kind));
  }

  if (node->lexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "lexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->lexpr, node, "lexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL && node->name->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->name, node, "name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->name) == 1 && linitial(node->name) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rexpr, node, "rexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintColumnRef(FingerprintContext *ctx, const ColumnRef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->fields != NULL && node->fields->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fields");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fields, node, "fields", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fields) == 1 && linitial(node->fields) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintParamRef(FingerprintContext *ctx, const ParamRef *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring all fields for fingerprinting
}

static void
_fingerprintFuncCall(FingerprintContext *ctx, const FuncCall *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->agg_distinct) {
    _fingerprintString(ctx, "agg_distinct");
    _fingerprintString(ctx, "true");
  }

  if (node->agg_filter != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "agg_filter");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->agg_filter, node, "agg_filter", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->agg_order != NULL && node->agg_order->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "agg_order");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->agg_order, node, "agg_order", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->agg_order) == 1 && linitial(node->agg_order) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->agg_star) {
    _fingerprintString(ctx, "agg_star");
    _fingerprintString(ctx, "true");
  }

  if (node->agg_within_group) {
    _fingerprintString(ctx, "agg_within_group");
    _fingerprintString(ctx, "true");
  }

  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->func_variadic) {
    _fingerprintString(ctx, "func_variadic");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "funcformat");
    _fingerprintString(ctx, _enumToStringCoercionForm(node->funcformat));
  }

  if (node->funcname != NULL && node->funcname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funcname, node, "funcname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funcname) == 1 && linitial(node->funcname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->over != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "over");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintWindowDef(ctx, node->over, node, "over", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintA_Star(FingerprintContext *ctx, const A_Star *node, const void *parent, const char *field_name, unsigned int depth)
{
}

static void
_fingerprintA_Indices(FingerprintContext *ctx, const A_Indices *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->is_slice) {
    _fingerprintString(ctx, "is_slice");
    _fingerprintString(ctx, "true");
  }

  if (node->lidx != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "lidx");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->lidx, node, "lidx", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->uidx != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "uidx");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->uidx, node, "uidx", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintA_Indirection(FingerprintContext *ctx, const A_Indirection *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->indirection != NULL && node->indirection->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indirection");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indirection, node, "indirection", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indirection) == 1 && linitial(node->indirection) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintA_ArrayExpr(FingerprintContext *ctx, const A_ArrayExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->elements != NULL && node->elements->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "elements");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->elements, node, "elements", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->elements) == 1 && linitial(node->elements) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintResTarget(FingerprintContext *ctx, const ResTarget *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->indirection != NULL && node->indirection->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indirection");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indirection, node, "indirection", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indirection) == 1 && linitial(node->indirection) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL && (field_name == NULL || parent == NULL || !IsA(parent, SelectStmt) || strcmp(field_name, "targetList") != 0)) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->val != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "val");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->val, node, "val", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintMultiAssignRef(FingerprintContext *ctx, const MultiAssignRef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->colno != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->colno);
    _fingerprintString(ctx, "colno");
    _fingerprintString(ctx, buffer);
  }

  if (node->ncolumns != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->ncolumns);
    _fingerprintString(ctx, "ncolumns");
    _fingerprintString(ctx, buffer);
  }

  if (node->source != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "source");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->source, node, "source", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintTypeCast(FingerprintContext *ctx, const TypeCast *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->typeName != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCollateClause(FingerprintContext *ctx, const CollateClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->collname != NULL && node->collname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->collname, node, "collname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->collname) == 1 && linitial(node->collname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintSortBy(FingerprintContext *ctx, const SortBy *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->node != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "node");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->node, node, "node", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "sortby_dir");
    _fingerprintString(ctx, _enumToStringSortByDir(node->sortby_dir));
  }

  if (true) {
    _fingerprintString(ctx, "sortby_nulls");
    _fingerprintString(ctx, _enumToStringSortByNulls(node->sortby_nulls));
  }

  if (node->useOp != NULL && node->useOp->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "useOp");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->useOp, node, "useOp", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->useOp) == 1 && linitial(node->useOp) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintWindowDef(FingerprintContext *ctx, const WindowDef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->endOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "endOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->endOffset, node, "endOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->frameOptions != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->frameOptions);
    _fingerprintString(ctx, "frameOptions");
    _fingerprintString(ctx, buffer);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->orderClause != NULL && node->orderClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "orderClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->orderClause, node, "orderClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->orderClause) == 1 && linitial(node->orderClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->partitionClause != NULL && node->partitionClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "partitionClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->partitionClause, node, "partitionClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->partitionClause) == 1 && linitial(node->partitionClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->refname != NULL) {
    _fingerprintString(ctx, "refname");
    _fingerprintString(ctx, node->refname);
  }

  if (node->startOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "startOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->startOffset, node, "startOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintRangeSubselect(FingerprintContext *ctx, const RangeSubselect *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->lateral) {
    _fingerprintString(ctx, "lateral");
    _fingerprintString(ctx, "true");
  }

  if (node->subquery != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "subquery");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->subquery, node, "subquery", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintRangeFunction(FingerprintContext *ctx, const RangeFunction *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->coldeflist != NULL && node->coldeflist->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coldeflist");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coldeflist, node, "coldeflist", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coldeflist) == 1 && linitial(node->coldeflist) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->functions != NULL && node->functions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "functions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->functions, node, "functions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->functions) == 1 && linitial(node->functions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->is_rowsfrom) {
    _fingerprintString(ctx, "is_rowsfrom");
    _fingerprintString(ctx, "true");
  }

  if (node->lateral) {
    _fingerprintString(ctx, "lateral");
    _fingerprintString(ctx, "true");
  }

  if (node->ordinality) {
    _fingerprintString(ctx, "ordinality");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintRangeTableSample(FingerprintContext *ctx, const RangeTableSample *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->method != NULL && node->method->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "method");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->method, node, "method", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->method) == 1 && linitial(node->method) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->repeatable != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "repeatable");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->repeatable, node, "repeatable", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintRangeTableFunc(FingerprintContext *ctx, const RangeTableFunc *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->columns != NULL && node->columns->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "columns");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->columns, node, "columns", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->columns) == 1 && linitial(node->columns) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->docexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "docexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->docexpr, node, "docexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->lateral) {
    _fingerprintString(ctx, "lateral");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->namespaces != NULL && node->namespaces->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "namespaces");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->namespaces, node, "namespaces", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->namespaces) == 1 && linitial(node->namespaces) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->rowexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "rowexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->rowexpr, node, "rowexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintRangeTableFuncCol(FingerprintContext *ctx, const RangeTableFuncCol *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->coldefexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coldefexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coldefexpr, node, "coldefexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->colexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colexpr, node, "colexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->colname != NULL) {
    _fingerprintString(ctx, "colname");
    _fingerprintString(ctx, node->colname);
  }

  if (node->for_ordinality) {
    _fingerprintString(ctx, "for_ordinality");
    _fingerprintString(ctx, "true");
  }

  if (node->is_not_null) {
    _fingerprintString(ctx, "is_not_null");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->typeName != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintTypeName(FingerprintContext *ctx, const TypeName *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arrayBounds != NULL && node->arrayBounds->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arrayBounds");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arrayBounds, node, "arrayBounds", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->arrayBounds) == 1 && linitial(node->arrayBounds) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->names != NULL && node->names->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "names");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->names, node, "names", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->names) == 1 && linitial(node->names) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->pct_type) {
    _fingerprintString(ctx, "pct_type");
    _fingerprintString(ctx, "true");
  }

  if (node->setof) {
    _fingerprintString(ctx, "setof");
    _fingerprintString(ctx, "true");
  }

  if (node->typeOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typeOid);
    _fingerprintString(ctx, "typeOid");
    _fingerprintString(ctx, buffer);
  }

  if (node->typemod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->typemod);
    _fingerprintString(ctx, "typemod");
    _fingerprintString(ctx, buffer);
  }

  if (node->typmods != NULL && node->typmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->typmods, node, "typmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->typmods) == 1 && linitial(node->typmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintColumnDef(FingerprintContext *ctx, const ColumnDef *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintCollateClause(ctx, node->collClause, node, "collClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->collOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->collOid);
    _fingerprintString(ctx, "collOid");
    _fingerprintString(ctx, buffer);
  }

  if (node->colname != NULL) {
    _fingerprintString(ctx, "colname");
    _fingerprintString(ctx, node->colname);
  }

  if (node->compression != NULL) {
    _fingerprintString(ctx, "compression");
    _fingerprintString(ctx, node->compression);
  }

  if (node->constraints != NULL && node->constraints->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "constraints");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->constraints, node, "constraints", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->constraints) == 1 && linitial(node->constraints) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->cooked_default != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cooked_default");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cooked_default, node, "cooked_default", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->fdwoptions != NULL && node->fdwoptions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fdwoptions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fdwoptions, node, "fdwoptions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fdwoptions) == 1 && linitial(node->fdwoptions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->generated != 0) {
    char buffer[2] = {node->generated, '\0'};
    _fingerprintString(ctx, "generated");
    _fingerprintString(ctx, buffer);
  }

  if (node->identity != 0) {
    char buffer[2] = {node->identity, '\0'};
    _fingerprintString(ctx, "identity");
    _fingerprintString(ctx, buffer);
  }

  if (node->identitySequence != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "identitySequence");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->identitySequence, node, "identitySequence", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->inhcount != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inhcount);
    _fingerprintString(ctx, "inhcount");
    _fingerprintString(ctx, buffer);
  }

  if (node->is_from_type) {
    _fingerprintString(ctx, "is_from_type");
    _fingerprintString(ctx, "true");
  }

  if (node->is_local) {
    _fingerprintString(ctx, "is_local");
    _fingerprintString(ctx, "true");
  }

  if (node->is_not_null) {
    _fingerprintString(ctx, "is_not_null");
    _fingerprintString(ctx, "true");
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->raw_default != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "raw_default");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->raw_default, node, "raw_default", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->storage != 0) {
    char buffer[2] = {node->storage, '\0'};
    _fingerprintString(ctx, "storage");
    _fingerprintString(ctx, buffer);
  }

  if (node->typeName != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintIndexElem(FingerprintContext *ctx, const IndexElem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collation != NULL && node->collation->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->collation, node, "collation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->collation) == 1 && linitial(node->collation) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->indexcolname != NULL) {
    _fingerprintString(ctx, "indexcolname");
    _fingerprintString(ctx, node->indexcolname);
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (true) {
    _fingerprintString(ctx, "nulls_ordering");
    _fingerprintString(ctx, _enumToStringSortByNulls(node->nulls_ordering));
  }

  if (node->opclass != NULL && node->opclass->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opclass");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opclass, node, "opclass", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opclass) == 1 && linitial(node->opclass) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->opclassopts != NULL && node->opclassopts->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opclassopts");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opclassopts, node, "opclassopts", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opclassopts) == 1 && linitial(node->opclassopts) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "ordering");
    _fingerprintString(ctx, _enumToStringSortByDir(node->ordering));
  }

}

static void
_fingerprintStatsElem(FingerprintContext *ctx, const StatsElem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintConstraint(FingerprintContext *ctx, const Constraint *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->access_method != NULL) {
    _fingerprintString(ctx, "access_method");
    _fingerprintString(ctx, node->access_method);
  }

  if (node->conname != NULL) {
    _fingerprintString(ctx, "conname");
    _fingerprintString(ctx, node->conname);
  }

  if (true) {
    _fingerprintString(ctx, "contype");
    _fingerprintString(ctx, _enumToStringConstrType(node->contype));
  }

  if (node->cooked_expr != NULL) {
    _fingerprintString(ctx, "cooked_expr");
    _fingerprintString(ctx, node->cooked_expr);
  }

  if (node->deferrable) {
    _fingerprintString(ctx, "deferrable");
    _fingerprintString(ctx, "true");
  }

  if (node->exclusions != NULL && node->exclusions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "exclusions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->exclusions, node, "exclusions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->exclusions) == 1 && linitial(node->exclusions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->fk_attrs != NULL && node->fk_attrs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fk_attrs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fk_attrs, node, "fk_attrs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fk_attrs) == 1 && linitial(node->fk_attrs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->fk_del_action != 0) {
    char buffer[2] = {node->fk_del_action, '\0'};
    _fingerprintString(ctx, "fk_del_action");
    _fingerprintString(ctx, buffer);
  }

  if (node->fk_del_set_cols != NULL && node->fk_del_set_cols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "fk_del_set_cols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->fk_del_set_cols, node, "fk_del_set_cols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->fk_del_set_cols) == 1 && linitial(node->fk_del_set_cols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->fk_matchtype != 0) {
    char buffer[2] = {node->fk_matchtype, '\0'};
    _fingerprintString(ctx, "fk_matchtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->fk_upd_action != 0) {
    char buffer[2] = {node->fk_upd_action, '\0'};
    _fingerprintString(ctx, "fk_upd_action");
    _fingerprintString(ctx, buffer);
  }

  if (node->generated_when != 0) {
    char buffer[2] = {node->generated_when, '\0'};
    _fingerprintString(ctx, "generated_when");
    _fingerprintString(ctx, buffer);
  }

  if (node->including != NULL && node->including->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "including");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->including, node, "including", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->including) == 1 && linitial(node->including) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->indexname != NULL) {
    _fingerprintString(ctx, "indexname");
    _fingerprintString(ctx, node->indexname);
  }

  if (node->indexspace != NULL) {
    _fingerprintString(ctx, "indexspace");
    _fingerprintString(ctx, node->indexspace);
  }

  if (node->initdeferred) {
    _fingerprintString(ctx, "initdeferred");
    _fingerprintString(ctx, "true");
  }

  if (node->initially_valid) {
    _fingerprintString(ctx, "initially_valid");
    _fingerprintString(ctx, "true");
  }

  if (node->is_no_inherit) {
    _fingerprintString(ctx, "is_no_inherit");
    _fingerprintString(ctx, "true");
  }

  if (node->keys != NULL && node->keys->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "keys");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->keys, node, "keys", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->keys) == 1 && linitial(node->keys) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->nulls_not_distinct) {
    _fingerprintString(ctx, "nulls_not_distinct");
    _fingerprintString(ctx, "true");
  }

  if (node->old_conpfeqop != NULL && node->old_conpfeqop->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "old_conpfeqop");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->old_conpfeqop, node, "old_conpfeqop", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->old_conpfeqop) == 1 && linitial(node->old_conpfeqop) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->old_pktable_oid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->old_pktable_oid);
    _fingerprintString(ctx, "old_pktable_oid");
    _fingerprintString(ctx, buffer);
  }

  if (node->options != NULL && node->options->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "options");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->options, node, "options", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->options) == 1 && linitial(node->options) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->pk_attrs != NULL && node->pk_attrs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "pk_attrs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->pk_attrs, node, "pk_attrs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->pk_attrs) == 1 && linitial(node->pk_attrs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->pktable != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "pktable");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->pktable, node, "pktable", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->raw_expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "raw_expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->raw_expr, node, "raw_expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->reset_default_tblspc) {
    _fingerprintString(ctx, "reset_default_tblspc");
    _fingerprintString(ctx, "true");
  }

  if (node->skip_validation) {
    _fingerprintString(ctx, "skip_validation");
    _fingerprintString(ctx, "true");
  }

  if (node->where_clause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "where_clause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->where_clause, node, "where_clause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintDefElem(FingerprintContext *ctx, const DefElem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->arg != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "arg");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->arg, node, "arg", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "defaction");
    _fingerprintString(ctx, _enumToStringDefElemAction(node->defaction));
  }

  if (node->defname != NULL) {
    _fingerprintString(ctx, "defname");
    _fingerprintString(ctx, node->defname);
  }

  if (node->defnamespace != NULL) {
    _fingerprintString(ctx, "defnamespace");
    _fingerprintString(ctx, node->defnamespace);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintRangeTblEntry(FingerprintContext *ctx, const RangeTblEntry *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->alias, node, "alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->checkAsUser != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->checkAsUser);
    _fingerprintString(ctx, "checkAsUser");
    _fingerprintString(ctx, buffer);
  }

  if (node->colcollations != NULL && node->colcollations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "colcollations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->colcollations, node, "colcollations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->colcollations) == 1 && linitial(node->colcollations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coltypes != NULL && node->coltypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coltypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coltypes, node, "coltypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coltypes) == 1 && linitial(node->coltypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->coltypmods != NULL && node->coltypmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "coltypmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->coltypmods, node, "coltypmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->coltypmods) == 1 && linitial(node->coltypmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ctelevelsup != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->ctelevelsup);
    _fingerprintString(ctx, "ctelevelsup");
    _fingerprintString(ctx, buffer);
  }

  if (node->ctename != NULL) {
    _fingerprintString(ctx, "ctename");
    _fingerprintString(ctx, node->ctename);
  }

  if (node->enrname != NULL) {
    _fingerprintString(ctx, "enrname");
    _fingerprintString(ctx, node->enrname);
  }

  if (node->enrtuples != 0) {
    char buffer[50];
    sprintf(buffer, "%f", node->enrtuples);
    _fingerprintString(ctx, "enrtuples");
    _fingerprintString(ctx, buffer);
  }

  if (node->eref != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "eref");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->eref, node, "eref", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->extraUpdatedCols);

    _fingerprintString(ctx, "extraUpdatedCols");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

  if (node->funcordinality) {
    _fingerprintString(ctx, "funcordinality");
    _fingerprintString(ctx, "true");
  }

  if (node->functions != NULL && node->functions->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "functions");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->functions, node, "functions", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->functions) == 1 && linitial(node->functions) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->inFromCl) {
    _fingerprintString(ctx, "inFromCl");
    _fingerprintString(ctx, "true");
  }

  if (node->inh) {
    _fingerprintString(ctx, "inh");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->insertedCols);

    _fingerprintString(ctx, "insertedCols");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

  if (node->join_using_alias != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "join_using_alias");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintAlias(ctx, node->join_using_alias, node, "join_using_alias", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->joinaliasvars != NULL && node->joinaliasvars->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "joinaliasvars");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->joinaliasvars, node, "joinaliasvars", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->joinaliasvars) == 1 && linitial(node->joinaliasvars) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->joinleftcols != NULL && node->joinleftcols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "joinleftcols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->joinleftcols, node, "joinleftcols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->joinleftcols) == 1 && linitial(node->joinleftcols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->joinmergedcols != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->joinmergedcols);
    _fingerprintString(ctx, "joinmergedcols");
    _fingerprintString(ctx, buffer);
  }

  if (node->joinrightcols != NULL && node->joinrightcols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "joinrightcols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->joinrightcols, node, "joinrightcols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->joinrightcols) == 1 && linitial(node->joinrightcols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "jointype");
    _fingerprintString(ctx, _enumToStringJoinType(node->jointype));
  }

  if (node->lateral) {
    _fingerprintString(ctx, "lateral");
    _fingerprintString(ctx, "true");
  }

  if (node->relid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->relid);
    _fingerprintString(ctx, "relid");
    _fingerprintString(ctx, buffer);
  }

  if (node->relkind != 0) {
    char buffer[2] = {node->relkind, '\0'};
    _fingerprintString(ctx, "relkind");
    _fingerprintString(ctx, buffer);
  }

  if (node->rellockmode != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->rellockmode);
    _fingerprintString(ctx, "rellockmode");
    _fingerprintString(ctx, buffer);
  }

  if (node->requiredPerms != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->requiredPerms);
    _fingerprintString(ctx, "requiredPerms");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "rtekind");
    _fingerprintString(ctx, _enumToStringRTEKind(node->rtekind));
  }

  if (node->securityQuals != NULL && node->securityQuals->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "securityQuals");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->securityQuals, node, "securityQuals", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->securityQuals) == 1 && linitial(node->securityQuals) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->security_barrier) {
    _fingerprintString(ctx, "security_barrier");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->selectedCols);

    _fingerprintString(ctx, "selectedCols");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

  if (node->self_reference) {
    _fingerprintString(ctx, "self_reference");
    _fingerprintString(ctx, "true");
  }

  if (node->subquery != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "subquery");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintQuery(ctx, node->subquery, node, "subquery", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->tablefunc != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "tablefunc");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTableFunc(ctx, node->tablefunc, node, "tablefunc", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->tablesample != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "tablesample");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTableSampleClause(ctx, node->tablesample, node, "tablesample", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->updatedCols);

    _fingerprintString(ctx, "updatedCols");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

  if (node->values_lists != NULL && node->values_lists->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "values_lists");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->values_lists, node, "values_lists", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->values_lists) == 1 && linitial(node->values_lists) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintRangeTblFunction(FingerprintContext *ctx, const RangeTblFunction *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->funccolcollations != NULL && node->funccolcollations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funccolcollations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funccolcollations, node, "funccolcollations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funccolcollations) == 1 && linitial(node->funccolcollations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->funccolcount != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->funccolcount);
    _fingerprintString(ctx, "funccolcount");
    _fingerprintString(ctx, buffer);
  }

  if (node->funccolnames != NULL && node->funccolnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funccolnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funccolnames, node, "funccolnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funccolnames) == 1 && linitial(node->funccolnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->funccoltypes != NULL && node->funccoltypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funccoltypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funccoltypes, node, "funccoltypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funccoltypes) == 1 && linitial(node->funccoltypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->funccoltypmods != NULL && node->funccoltypmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funccoltypmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funccoltypmods, node, "funccoltypmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->funccoltypmods) == 1 && linitial(node->funccoltypmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->funcexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "funcexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->funcexpr, node, "funcexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    int x;
    Bitmapset	*bms = bms_copy(node->funcparams);

    _fingerprintString(ctx, "funcparams");

  	while ((x = bms_first_member(bms)) >= 0) {
      char buffer[50];
      sprintf(buffer, "%d", x);
      _fingerprintString(ctx, buffer);
    }

    bms_free(bms);
  }

}

static void
_fingerprintTableSampleClause(FingerprintContext *ctx, const TableSampleClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args != NULL && node->args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->args, node, "args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->args) == 1 && linitial(node->args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->repeatable != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "repeatable");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->repeatable, node, "repeatable", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->tsmhandler != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->tsmhandler);
    _fingerprintString(ctx, "tsmhandler");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintWithCheckOption(FingerprintContext *ctx, const WithCheckOption *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cascaded) {
    _fingerprintString(ctx, "cascaded");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringWCOKind(node->kind));
  }

  if (node->polname != NULL) {
    _fingerprintString(ctx, "polname");
    _fingerprintString(ctx, node->polname);
  }

  if (node->qual != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "qual");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->qual, node, "qual", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->relname != NULL) {
    _fingerprintString(ctx, "relname");
    _fingerprintString(ctx, node->relname);
  }

}

static void
_fingerprintSortGroupClause(FingerprintContext *ctx, const SortGroupClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->eqop != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->eqop);
    _fingerprintString(ctx, "eqop");
    _fingerprintString(ctx, buffer);
  }

  if (node->hashable) {
    _fingerprintString(ctx, "hashable");
    _fingerprintString(ctx, "true");
  }

  if (node->nulls_first) {
    _fingerprintString(ctx, "nulls_first");
    _fingerprintString(ctx, "true");
  }

  if (node->sortop != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->sortop);
    _fingerprintString(ctx, "sortop");
    _fingerprintString(ctx, buffer);
  }

  if (node->tleSortGroupRef != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->tleSortGroupRef);
    _fingerprintString(ctx, "tleSortGroupRef");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintGroupingSet(FingerprintContext *ctx, const GroupingSet *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->content != NULL && node->content->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "content");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->content, node, "content", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->content) == 1 && linitial(node->content) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringGroupingSetKind(node->kind));
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintWindowClause(FingerprintContext *ctx, const WindowClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->copiedOrder) {
    _fingerprintString(ctx, "copiedOrder");
    _fingerprintString(ctx, "true");
  }

  if (node->endInRangeFunc != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->endInRangeFunc);
    _fingerprintString(ctx, "endInRangeFunc");
    _fingerprintString(ctx, buffer);
  }

  if (node->endOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "endOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->endOffset, node, "endOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->frameOptions != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->frameOptions);
    _fingerprintString(ctx, "frameOptions");
    _fingerprintString(ctx, buffer);
  }

  if (node->inRangeAsc) {
    _fingerprintString(ctx, "inRangeAsc");
    _fingerprintString(ctx, "true");
  }

  if (node->inRangeColl != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->inRangeColl);
    _fingerprintString(ctx, "inRangeColl");
    _fingerprintString(ctx, buffer);
  }

  if (node->inRangeNullsFirst) {
    _fingerprintString(ctx, "inRangeNullsFirst");
    _fingerprintString(ctx, "true");
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->orderClause != NULL && node->orderClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "orderClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->orderClause, node, "orderClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->orderClause) == 1 && linitial(node->orderClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->partitionClause != NULL && node->partitionClause->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "partitionClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->partitionClause, node, "partitionClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->partitionClause) == 1 && linitial(node->partitionClause) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->refname != NULL) {
    _fingerprintString(ctx, "refname");
    _fingerprintString(ctx, node->refname);
  }

  if (node->runCondition != NULL && node->runCondition->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "runCondition");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->runCondition, node, "runCondition", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->runCondition) == 1 && linitial(node->runCondition) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->startInRangeFunc != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->startInRangeFunc);
    _fingerprintString(ctx, "startInRangeFunc");
    _fingerprintString(ctx, buffer);
  }

  if (node->startOffset != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "startOffset");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->startOffset, node, "startOffset", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->winref != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->winref);
    _fingerprintString(ctx, "winref");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintObjectWithArgs(FingerprintContext *ctx, const ObjectWithArgs *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->args_unspecified) {
    _fingerprintString(ctx, "args_unspecified");
    _fingerprintString(ctx, "true");
  }

  if (node->objargs != NULL && node->objargs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "objargs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->objargs, node, "objargs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->objargs) == 1 && linitial(node->objargs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->objfuncargs != NULL && node->objfuncargs->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "objfuncargs");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->objfuncargs, node, "objfuncargs", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->objfuncargs) == 1 && linitial(node->objfuncargs) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->objname != NULL && node->objname->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "objname");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->objname, node, "objname", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->objname) == 1 && linitial(node->objname) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintAccessPriv(FingerprintContext *ctx, const AccessPriv *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cols != NULL && node->cols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cols, node, "cols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cols) == 1 && linitial(node->cols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->priv_name != NULL) {
    _fingerprintString(ctx, "priv_name");
    _fingerprintString(ctx, node->priv_name);
  }

}

static void
_fingerprintCreateOpClassItem(FingerprintContext *ctx, const CreateOpClassItem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->class_args != NULL && node->class_args->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "class_args");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->class_args, node, "class_args", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->class_args) == 1 && linitial(node->class_args) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->itemtype != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->itemtype);
    _fingerprintString(ctx, "itemtype");
    _fingerprintString(ctx, buffer);
  }

  if (node->name != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintObjectWithArgs(ctx, node->name, node, "name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->number != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->number);
    _fingerprintString(ctx, "number");
    _fingerprintString(ctx, buffer);
  }

  if (node->order_family != NULL && node->order_family->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "order_family");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->order_family, node, "order_family", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->order_family) == 1 && linitial(node->order_family) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->storedtype != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "storedtype");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->storedtype, node, "storedtype", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintTableLikeClause(FingerprintContext *ctx, const TableLikeClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->options != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->options);
    _fingerprintString(ctx, "options");
    _fingerprintString(ctx, buffer);
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->relationOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->relationOid);
    _fingerprintString(ctx, "relationOid");
    _fingerprintString(ctx, buffer);
  }

}

static void
_fingerprintFunctionParameter(FingerprintContext *ctx, const FunctionParameter *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->argType != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "argType");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->argType, node, "argType", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->defexpr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "defexpr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->defexpr, node, "defexpr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "mode");
    _fingerprintString(ctx, _enumToStringFunctionParameterMode(node->mode));
  }

  // Intentionally ignoring node->name for fingerprinting

}

static void
_fingerprintLockingClause(FingerprintContext *ctx, const LockingClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->lockedRels != NULL && node->lockedRels->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "lockedRels");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->lockedRels, node, "lockedRels", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->lockedRels) == 1 && linitial(node->lockedRels) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "strength");
    _fingerprintString(ctx, _enumToStringLockClauseStrength(node->strength));
  }

  if (true) {
    _fingerprintString(ctx, "waitPolicy");
    _fingerprintString(ctx, _enumToStringLockWaitPolicy(node->waitPolicy));
  }

}

static void
_fingerprintRowMarkClause(FingerprintContext *ctx, const RowMarkClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->pushedDown) {
    _fingerprintString(ctx, "pushedDown");
    _fingerprintString(ctx, "true");
  }

  if (node->rti != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->rti);
    _fingerprintString(ctx, "rti");
    _fingerprintString(ctx, buffer);
  }

  if (true) {
    _fingerprintString(ctx, "strength");
    _fingerprintString(ctx, _enumToStringLockClauseStrength(node->strength));
  }

  if (true) {
    _fingerprintString(ctx, "waitPolicy");
    _fingerprintString(ctx, _enumToStringLockWaitPolicy(node->waitPolicy));
  }

}

static void
_fingerprintXmlSerialize(FingerprintContext *ctx, const XmlSerialize *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->typeName != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "typeName");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintTypeName(ctx, node->typeName, node, "typeName", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (true) {
    _fingerprintString(ctx, "xmloption");
    _fingerprintString(ctx, _enumToStringXmlOptionType(node->xmloption));
  }

}

static void
_fingerprintWithClause(FingerprintContext *ctx, const WithClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->ctes != NULL && node->ctes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctes, node, "ctes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ctes) == 1 && linitial(node->ctes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->recursive) {
    _fingerprintString(ctx, "recursive");
    _fingerprintString(ctx, "true");
  }

}

static void
_fingerprintInferClause(FingerprintContext *ctx, const InferClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->conname != NULL) {
    _fingerprintString(ctx, "conname");
    _fingerprintString(ctx, node->conname);
  }

  if (node->indexElems != NULL && node->indexElems->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "indexElems");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->indexElems, node, "indexElems", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->indexElems) == 1 && linitial(node->indexElems) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintOnConflictClause(FingerprintContext *ctx, const OnConflictClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "action");
    _fingerprintString(ctx, _enumToStringOnConflictAction(node->action));
  }

  if (node->infer != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "infer");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintInferClause(ctx, node->infer, node, "infer", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintCTESearchClause(FingerprintContext *ctx, const CTESearchClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->search_breadth_first) {
    _fingerprintString(ctx, "search_breadth_first");
    _fingerprintString(ctx, "true");
  }

  if (node->search_col_list != NULL && node->search_col_list->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "search_col_list");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->search_col_list, node, "search_col_list", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->search_col_list) == 1 && linitial(node->search_col_list) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->search_seq_column != NULL) {
    _fingerprintString(ctx, "search_seq_column");
    _fingerprintString(ctx, node->search_seq_column);
  }

}

static void
_fingerprintCTECycleClause(FingerprintContext *ctx, const CTECycleClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->cycle_col_list != NULL && node->cycle_col_list->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cycle_col_list");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cycle_col_list, node, "cycle_col_list", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->cycle_col_list) == 1 && linitial(node->cycle_col_list) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->cycle_mark_collation != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cycle_mark_collation);
    _fingerprintString(ctx, "cycle_mark_collation");
    _fingerprintString(ctx, buffer);
  }

  if (node->cycle_mark_column != NULL) {
    _fingerprintString(ctx, "cycle_mark_column");
    _fingerprintString(ctx, node->cycle_mark_column);
  }

  if (node->cycle_mark_default != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cycle_mark_default");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cycle_mark_default, node, "cycle_mark_default", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->cycle_mark_neop != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cycle_mark_neop);
    _fingerprintString(ctx, "cycle_mark_neop");
    _fingerprintString(ctx, buffer);
  }

  if (node->cycle_mark_type != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cycle_mark_type);
    _fingerprintString(ctx, "cycle_mark_type");
    _fingerprintString(ctx, buffer);
  }

  if (node->cycle_mark_typmod != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cycle_mark_typmod);
    _fingerprintString(ctx, "cycle_mark_typmod");
    _fingerprintString(ctx, buffer);
  }

  if (node->cycle_mark_value != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cycle_mark_value");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->cycle_mark_value, node, "cycle_mark_value", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->cycle_path_column != NULL) {
    _fingerprintString(ctx, "cycle_path_column");
    _fingerprintString(ctx, node->cycle_path_column);
  }

  // Intentionally ignoring node->location for fingerprinting

}

static void
_fingerprintCommonTableExpr(FingerprintContext *ctx, const CommonTableExpr *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->aliascolnames != NULL && node->aliascolnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "aliascolnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->aliascolnames, node, "aliascolnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->aliascolnames) == 1 && linitial(node->aliascolnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ctecolcollations != NULL && node->ctecolcollations->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctecolcollations");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctecolcollations, node, "ctecolcollations", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ctecolcollations) == 1 && linitial(node->ctecolcollations) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ctecolnames != NULL && node->ctecolnames->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctecolnames");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctecolnames, node, "ctecolnames", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ctecolnames) == 1 && linitial(node->ctecolnames) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ctecoltypes != NULL && node->ctecoltypes->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctecoltypes");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctecoltypes, node, "ctecoltypes", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ctecoltypes) == 1 && linitial(node->ctecoltypes) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->ctecoltypmods != NULL && node->ctecoltypmods->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctecoltypmods");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctecoltypmods, node, "ctecoltypmods", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->ctecoltypmods) == 1 && linitial(node->ctecoltypmods) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (true) {
    _fingerprintString(ctx, "ctematerialized");
    _fingerprintString(ctx, _enumToStringCTEMaterialize(node->ctematerialized));
  }

  if (node->ctename != NULL) {
    _fingerprintString(ctx, "ctename");
    _fingerprintString(ctx, node->ctename);
  }

  if (node->ctequery != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "ctequery");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->ctequery, node, "ctequery", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->cterecursive) {
    _fingerprintString(ctx, "cterecursive");
    _fingerprintString(ctx, "true");
  }

  if (node->cterefcount != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->cterefcount);
    _fingerprintString(ctx, "cterefcount");
    _fingerprintString(ctx, buffer);
  }

  if (node->cycle_clause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "cycle_clause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintCTECycleClause(ctx, node->cycle_clause, node, "cycle_clause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->search_clause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "search_clause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintCTESearchClause(ctx, node->search_clause, node, "search_clause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintMergeWhenClause(FingerprintContext *ctx, const MergeWhenClause *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "commandType");
    _fingerprintString(ctx, _enumToStringCmdType(node->commandType));
  }

  if (node->condition != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "condition");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->condition, node, "condition", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->matched) {
    _fingerprintString(ctx, "matched");
    _fingerprintString(ctx, "true");
  }

  if (true) {
    _fingerprintString(ctx, "override");
    _fingerprintString(ctx, _enumToStringOverridingKind(node->override));
  }

  if (node->targetList != NULL && node->targetList->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "targetList");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->targetList, node, "targetList", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->targetList) == 1 && linitial(node->targetList) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->values != NULL && node->values->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "values");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->values, node, "values", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->values) == 1 && linitial(node->values) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintRoleSpec(FingerprintContext *ctx, const RoleSpec *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->rolename != NULL) {
    _fingerprintString(ctx, "rolename");
    _fingerprintString(ctx, node->rolename);
  }

  if (true) {
    _fingerprintString(ctx, "roletype");
    _fingerprintString(ctx, _enumToStringRoleSpecType(node->roletype));
  }

}

static void
_fingerprintTriggerTransition(FingerprintContext *ctx, const TriggerTransition *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->isNew) {
    _fingerprintString(ctx, "isNew");
    _fingerprintString(ctx, "true");
  }

  if (node->isTable) {
    _fingerprintString(ctx, "isTable");
    _fingerprintString(ctx, "true");
  }

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

}

static void
_fingerprintPartitionElem(FingerprintContext *ctx, const PartitionElem *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->collation != NULL && node->collation->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "collation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->collation, node, "collation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->collation) == 1 && linitial(node->collation) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->expr != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "expr");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->expr, node, "expr", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (node->opclass != NULL && node->opclass->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "opclass");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->opclass, node, "opclass", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->opclass) == 1 && linitial(node->opclass) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintPartitionSpec(FingerprintContext *ctx, const PartitionSpec *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->partParams != NULL && node->partParams->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "partParams");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->partParams, node, "partParams", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->partParams) == 1 && linitial(node->partParams) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->strategy != NULL) {
    _fingerprintString(ctx, "strategy");
    _fingerprintString(ctx, node->strategy);
  }

}

static void
_fingerprintPartitionBoundSpec(FingerprintContext *ctx, const PartitionBoundSpec *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->is_default) {
    _fingerprintString(ctx, "is_default");
    _fingerprintString(ctx, "true");
  }

  if (node->listdatums != NULL && node->listdatums->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "listdatums");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->listdatums, node, "listdatums", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->listdatums) == 1 && linitial(node->listdatums) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  // Intentionally ignoring node->location for fingerprinting

  if (node->lowerdatums != NULL && node->lowerdatums->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "lowerdatums");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->lowerdatums, node, "lowerdatums", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->lowerdatums) == 1 && linitial(node->lowerdatums) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->modulus != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->modulus);
    _fingerprintString(ctx, "modulus");
    _fingerprintString(ctx, buffer);
  }

  if (node->remainder != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->remainder);
    _fingerprintString(ctx, "remainder");
    _fingerprintString(ctx, buffer);
  }

  if (node->strategy != 0) {
    char buffer[2] = {node->strategy, '\0'};
    _fingerprintString(ctx, "strategy");
    _fingerprintString(ctx, buffer);
  }

  if (node->upperdatums != NULL && node->upperdatums->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "upperdatums");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->upperdatums, node, "upperdatums", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->upperdatums) == 1 && linitial(node->upperdatums) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintPartitionRangeDatum(FingerprintContext *ctx, const PartitionRangeDatum *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (true) {
    _fingerprintString(ctx, "kind");
    _fingerprintString(ctx, _enumToStringPartitionRangeDatumKind(node->kind));
  }

  // Intentionally ignoring node->location for fingerprinting

  if (node->value != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "value");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->value, node, "value", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintPartitionCmd(FingerprintContext *ctx, const PartitionCmd *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->bound != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "bound");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintPartitionBoundSpec(ctx, node->bound, node, "bound", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->concurrent) {
    _fingerprintString(ctx, "concurrent");
    _fingerprintString(ctx, "true");
  }

  if (node->name != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "name");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->name, node, "name", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintVacuumRelation(FingerprintContext *ctx, const VacuumRelation *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->oid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->oid);
    _fingerprintString(ctx, "oid");
    _fingerprintString(ctx, buffer);
  }

  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->va_cols != NULL && node->va_cols->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "va_cols");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->va_cols, node, "va_cols", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->va_cols) == 1 && linitial(node->va_cols) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
}

static void
_fingerprintPublicationObjSpec(FingerprintContext *ctx, const PublicationObjSpec *node, const void *parent, const char *field_name, unsigned int depth)
{
  // Intentionally ignoring node->location for fingerprinting

  if (node->name != NULL) {
    _fingerprintString(ctx, "name");
    _fingerprintString(ctx, node->name);
  }

  if (true) {
    _fingerprintString(ctx, "pubobjtype");
    _fingerprintString(ctx, _enumToStringPublicationObjSpecType(node->pubobjtype));
  }

  if (node->pubtable != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "pubtable");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintPublicationTable(ctx, node->pubtable, node, "pubtable", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintPublicationTable(FingerprintContext *ctx, const PublicationTable *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->columns != NULL && node->columns->length > 0) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "columns");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->columns, node, "columns", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state) && !(list_length(node->columns) == 1 && linitial(node->columns) == NIL)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }
  if (node->relation != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "relation");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintRangeVar(ctx, node->relation, node, "relation", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

  if (node->whereClause != NULL) {
    XXH3_state_t* prev = XXH3_createState();
    XXH64_hash_t hash;

    XXH3_copyState(prev, ctx->xxh_state);
    _fingerprintString(ctx, "whereClause");

    hash = XXH3_64bits_digest(ctx->xxh_state);
    _fingerprintNode(ctx, node->whereClause, node, "whereClause", depth + 1);
    if (hash == XXH3_64bits_digest(ctx->xxh_state)) {
      XXH3_copyState(ctx->xxh_state, prev);
      if (ctx->write_tokens)
        dlist_delete(dlist_tail_node(&ctx->tokens));
    }
    XXH3_freeState(prev);
  }

}

static void
_fingerprintInlineCodeBlock(FingerprintContext *ctx, const InlineCodeBlock *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->atomic) {
    _fingerprintString(ctx, "atomic");
    _fingerprintString(ctx, "true");
  }

  if (node->langIsTrusted) {
    _fingerprintString(ctx, "langIsTrusted");
    _fingerprintString(ctx, "true");
  }

  if (node->langOid != 0) {
    char buffer[50];
    sprintf(buffer, "%d", node->langOid);
    _fingerprintString(ctx, "langOid");
    _fingerprintString(ctx, buffer);
  }

  if (node->source_text != NULL) {
    _fingerprintString(ctx, "source_text");
    _fingerprintString(ctx, node->source_text);
  }

}

static void
_fingerprintCallContext(FingerprintContext *ctx, const CallContext *node, const void *parent, const char *field_name, unsigned int depth)
{
  if (node->atomic) {
    _fingerprintString(ctx, "atomic");
    _fingerprintString(ctx, "true");
  }

}

