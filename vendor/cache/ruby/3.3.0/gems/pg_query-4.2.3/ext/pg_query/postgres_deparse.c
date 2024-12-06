#include "postgres.h"
#include "catalog/index.h"
#include "catalog/pg_am.h"
#include "catalog/pg_attribute.h"
#include "catalog/pg_class.h"
#include "catalog/pg_trigger.h"
#include "commands/trigger.h"
#include "common/keywords.h"
#include "common/kwlookup.h"
#include "lib/stringinfo.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"
#include "utils/builtins.h"
#include "utils/datetime.h"
#include "utils/timestamp.h"
#include "utils/xml.h"

typedef enum DeparseNodeContext {
	DEPARSE_NODE_CONTEXT_NONE,
	// Parent node type (and sometimes field)
	DEPARSE_NODE_CONTEXT_INSERT_RELATION,
	DEPARSE_NODE_CONTEXT_INSERT_ON_CONFLICT,
	DEPARSE_NODE_CONTEXT_UPDATE,
	DEPARSE_NODE_CONTEXT_RETURNING,
	DEPARSE_NODE_CONTEXT_A_EXPR,
	DEPARSE_NODE_CONTEXT_XMLATTRIBUTES,
	DEPARSE_NODE_CONTEXT_XMLNAMESPACES,
	DEPARSE_NODE_CONTEXT_CREATE_TYPE,
	DEPARSE_NODE_CONTEXT_ALTER_TYPE,
	DEPARSE_NODE_CONTEXT_SET_STATEMENT,
	// Identifier vs constant context
	DEPARSE_NODE_CONTEXT_IDENTIFIER,
	DEPARSE_NODE_CONTEXT_CONSTANT
} DeparseNodeContext;

static void
removeTrailingSpace(StringInfo str)
{
	if (str->len >= 1 && str->data[str->len - 1] == ' ') {
		str->len -= 1;
		str->data[str->len] = '\0';
	}
}

/*
 * Append a SQL string literal representing "val" to buf.
 *
 * Copied here from postgres_fdw/deparse.c to avoid adding
 * many additional dependencies.
 */
static void
deparseStringLiteral(StringInfo buf, const char *val)
{
	const char *valptr;

	/*
	 * Rather than making assumptions about the remote server's value of
	 * standard_conforming_strings, always use E'foo' syntax if there are any
	 * backslashes.  This will fail on remote servers before 8.1, but those
	 * are long out of support.
	 */
	if (strchr(val, '\\') != NULL)
		appendStringInfoChar(buf, ESCAPE_STRING_SYNTAX);
	appendStringInfoChar(buf, '\'');
	for (valptr = val; *valptr; valptr++)
	{
		char		ch = *valptr;

		if (SQL_STR_DOUBLE(ch, true))
			appendStringInfoChar(buf, ch);
		appendStringInfoChar(buf, ch);
	}
	appendStringInfoChar(buf, '\'');
}

// Check whether the value is a reserved keyword, to determine escaping for output
//
// Note that since the parser lowercases all keywords, this does *not* match when the
// value is not all-lowercase and a reserved keyword.
static bool
isReservedKeyword(const char *val)
{
	int	kwnum = ScanKeywordLookup(val, &ScanKeywords);
	bool all_lower_case = true;
	const char *cp;

	for (cp = val; *cp; cp++)
	{
		if (!(
			(*cp >= 'a' && *cp <= 'z') ||
			(*cp >= '0' && *cp <= '9') ||
			(*cp == '_')))
		{
			all_lower_case = false;
			break;
		}
	}

	return all_lower_case && kwnum >= 0 && ScanKeywordCategories[kwnum] == RESERVED_KEYWORD;
}

// Returns whether the given value consists only of operator characters
static bool
isOp(const char *val)
{
	const char *cp;

	Assert(strlen(val) > 0);

	for (cp = val; *cp; cp++)
	{
		if (!(
			*cp == '~' ||
			*cp == '!' ||
			*cp == '@' ||
			*cp == '#' ||
			*cp == '^' ||
			*cp == '&' ||
			*cp == '|' ||
			*cp == '`' ||
			*cp == '?' ||
			*cp == '+' ||
			*cp == '-' ||
			*cp == '*' ||
			*cp == '/' ||
			*cp == '%' ||
			*cp == '<' ||
			*cp == '>' ||
			*cp == '='))
			return false;
	}

	return true;
}

static void deparseSelectStmt(StringInfo str, SelectStmt *stmt);
static void deparseIntoClause(StringInfo str, IntoClause *into_clause);
static void deparseRangeVar(StringInfo str, RangeVar *range_var, DeparseNodeContext context);
static void deparseResTarget(StringInfo str, ResTarget *res_target, DeparseNodeContext context);
void deparseRawStmt(StringInfo str, RawStmt *raw_stmt);
static void deparseAlias(StringInfo str, Alias *alias);
static void deparseWindowDef(StringInfo str, WindowDef* window_def);
static void deparseColumnRef(StringInfo str, ColumnRef* column_ref);
static void deparseSubLink(StringInfo str, SubLink* sub_link);
static void deparseAExpr(StringInfo str, A_Expr* a_expr, DeparseNodeContext context);
static void deparseBoolExpr(StringInfo str, BoolExpr *bool_expr);
static void deparseAStar(StringInfo str, A_Star* a_star);
static void deparseCollateClause(StringInfo str, CollateClause* collate_clause);
static void deparseSortBy(StringInfo str, SortBy* sort_by);
static void deparseParamRef(StringInfo str, ParamRef* param_ref);
static void deparseSQLValueFunction(StringInfo str, SQLValueFunction* sql_value_function);
static void deparseWithClause(StringInfo str, WithClause *with_clause);
static void deparseJoinExpr(StringInfo str, JoinExpr *join_expr);
static void deparseCommonTableExpr(StringInfo str, CommonTableExpr *cte);
static void deparseRangeSubselect(StringInfo str, RangeSubselect *range_subselect);
static void deparseRangeFunction(StringInfo str, RangeFunction *range_func);
static void deparseAArrayExpr(StringInfo str, A_ArrayExpr * array_expr);
static void deparseRowExpr(StringInfo str, RowExpr *row_expr);
static void deparseTypeCast(StringInfo str, TypeCast *type_cast, DeparseNodeContext context);
static void deparseTypeName(StringInfo str, TypeName *type_name);
static void deparseIntervalTypmods(StringInfo str, TypeName *type_name);
static void deparseNullTest(StringInfo str, NullTest *null_test);
static void deparseCaseExpr(StringInfo str, CaseExpr *case_expr);
static void deparseCaseWhen(StringInfo str, CaseWhen *case_when);
static void deparseAIndirection(StringInfo str, A_Indirection *a_indirection);
static void deparseAIndices(StringInfo str, A_Indices *a_indices);
static void deparseCoalesceExpr(StringInfo str, CoalesceExpr *coalesce_expr);
static void deparseBooleanTest(StringInfo str, BooleanTest *boolean_test);
static void deparseColumnDef(StringInfo str, ColumnDef *column_def);
static void deparseInsertStmt(StringInfo str, InsertStmt *insert_stmt);
static void deparseOnConflictClause(StringInfo str, OnConflictClause *on_conflict_clause);
static void deparseIndexElem(StringInfo str, IndexElem* index_elem);
static void deparseUpdateStmt(StringInfo str, UpdateStmt *update_stmt);
static void deparseDeleteStmt(StringInfo str, DeleteStmt *delete_stmt);
static void deparseLockingClause(StringInfo str, LockingClause *locking_clause);
static void deparseSetToDefault(StringInfo str, SetToDefault *set_to_default);
static void deparseCreateCastStmt(StringInfo str, CreateCastStmt *create_cast_stmt);
static void deparseCreateDomainStmt(StringInfo str, CreateDomainStmt *create_domain_stmt);
static void deparseFunctionParameter(StringInfo str, FunctionParameter *function_parameter);
static void deparseRoleSpec(StringInfo str, RoleSpec *role_spec);
static void deparseViewStmt(StringInfo str, ViewStmt *view_stmt);
static void deparseVariableSetStmt(StringInfo str, VariableSetStmt* variable_set_stmt);
static void deparseReplicaIdentityStmt(StringInfo str, ReplicaIdentityStmt *replica_identity_stmt);
static void deparseRangeTableSample(StringInfo str, RangeTableSample *range_table_sample);
static void deparseRangeTableFunc(StringInfo str, RangeTableFunc* range_table_func);
static void deparseGroupingSet(StringInfo str, GroupingSet *grouping_set);
static void deparseFuncCall(StringInfo str, FuncCall *func_call);
static void deparseMinMaxExpr(StringInfo str, MinMaxExpr *min_max_expr);
static void deparseXmlExpr(StringInfo str, XmlExpr* xml_expr);
static void deparseXmlSerialize(StringInfo str, XmlSerialize *xml_serialize);
static void deparseConstraint(StringInfo str, Constraint *constraint);
static void deparseSchemaStmt(StringInfo str, Node *node);
static void deparseExecuteStmt(StringInfo str, ExecuteStmt *execute_stmt);
static void deparseTriggerTransition(StringInfo str, TriggerTransition *trigger_transition);
static void deparseCreateOpClassItem(StringInfo str, CreateOpClassItem *create_op_class_item);
static void deparseAConst(StringInfo str, A_Const *a_const);
static void deparseCurrentOfExpr(StringInfo str, CurrentOfExpr *current_of_expr);
static void deparseGroupingFunc(StringInfo str, GroupingFunc *grouping_func);

static void deparsePreparableStmt(StringInfo str, Node *node);
static void deparseRuleActionStmt(StringInfo str, Node *node);
static void deparseExplainableStmt(StringInfo str, Node *node);
static void deparseStmt(StringInfo str, Node *node);
static void deparseValue(StringInfo str, union ValUnion *value, DeparseNodeContext context);


// "any_name" in gram.y
static void deparseAnyName(StringInfo str, List *parts)
{
	ListCell *lc = NULL;

	foreach(lc, parts)
	{
		Assert(IsA(lfirst(lc), String));
		appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
		if (lnext(parts, lc))
			appendStringInfoChar(str, '.');
	}
}
static void deparseAnyNameSkipFirst(StringInfo str, List *parts)
{
	ListCell *lc = NULL;

	for_each_from(lc, parts, 1)
	{
		Assert(IsA(lfirst(lc), String));
		appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
		if (lnext(parts, lc))
			appendStringInfoChar(str, '.');
	}
}
static void deparseAnyNameSkipLast(StringInfo str, List *parts)
{
	ListCell *lc = NULL;

	foreach (lc, parts)
	{
		if (lnext(parts, lc))
		{
			appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
			if (foreach_current_index(lc) < list_length(parts) - 2)
				appendStringInfoChar(str, '.');
		}
	}
}

// "a_expr" / "b_expr" in gram.y
static void deparseExpr(StringInfo str, Node *node)
{
	if (node == NULL)
		return;
	switch (nodeTag(node))
	{
		case T_FuncCall:
			deparseFuncCall(str, castNode(FuncCall, node));
			break;
		case T_XmlExpr:
			deparseXmlExpr(str, castNode(XmlExpr, node));
			break;
		case T_TypeCast:
			deparseTypeCast(str, castNode(TypeCast, node), DEPARSE_NODE_CONTEXT_NONE);
			break;
		case T_A_Const:
			deparseAConst(str, castNode(A_Const, node));
			break;
		case T_ColumnRef:
			deparseColumnRef(str, castNode(ColumnRef, node));
			break;
		case T_A_Expr:
			deparseAExpr(str, castNode(A_Expr, node), DEPARSE_NODE_CONTEXT_NONE);
			break;
		case T_CaseExpr:
			deparseCaseExpr(str, castNode(CaseExpr, node));
			break;
		case T_A_ArrayExpr:
			deparseAArrayExpr(str, castNode(A_ArrayExpr, node));
			break;
		case T_NullTest:
			deparseNullTest(str, castNode(NullTest, node));
			break;
		case T_XmlSerialize:
			deparseXmlSerialize(str, castNode(XmlSerialize, node));
			break;
		case T_ParamRef:
			deparseParamRef(str, castNode(ParamRef, node));
			break;
		case T_BoolExpr:
			deparseBoolExpr(str, castNode(BoolExpr, node));
			break;
		case T_SubLink:
			deparseSubLink(str, castNode(SubLink, node));
			break;
		case T_RowExpr:
			deparseRowExpr(str, castNode(RowExpr, node));
			break;
		case T_CoalesceExpr:
			deparseCoalesceExpr(str, castNode(CoalesceExpr, node));
			break;
		case T_SetToDefault:
			deparseSetToDefault(str, castNode(SetToDefault, node));
			break;
		case T_A_Indirection:
			deparseAIndirection(str, castNode(A_Indirection, node));
			break;
		case T_CollateClause:
			deparseCollateClause(str, castNode(CollateClause, node));
			break;
		case T_CurrentOfExpr:
			deparseCurrentOfExpr(str, castNode(CurrentOfExpr, node));
			break;
		case T_SQLValueFunction:
			deparseSQLValueFunction(str, castNode(SQLValueFunction, node));
			break;
		case T_MinMaxExpr:
			deparseMinMaxExpr(str, castNode(MinMaxExpr, node));
			break;
		case T_BooleanTest:
			deparseBooleanTest(str, castNode(BooleanTest, node));
			break;
		case T_GroupingFunc:
			deparseGroupingFunc(str, castNode(GroupingFunc, node));
			break;
		default:
			elog(ERROR, "deparse: unpermitted node type in a_expr/b_expr: %d",
				 (int) nodeTag(node));
			break;
	}
}

// "c_expr" in gram.y
static void deparseCExpr(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_ColumnRef:
			deparseColumnRef(str, castNode(ColumnRef, node));
			break;
		case T_A_Const:
			deparseAConst(str, castNode(A_Const, node));
			break;
		case T_TypeCast:
			deparseTypeCast(str, castNode(TypeCast, node), DEPARSE_NODE_CONTEXT_NONE);
			break;
		case T_A_Expr:
			appendStringInfoChar(str, '(');
			deparseAExpr(str, castNode(A_Expr, node), DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoChar(str, ')');
			break;
		case T_ParamRef:
			deparseParamRef(str, castNode(ParamRef, node));
			break;
		case T_A_Indirection:
			deparseAIndirection(str, castNode(A_Indirection, node));
			break;
		case T_CaseExpr:
			deparseCaseExpr(str, castNode(CaseExpr, node));
			break;
		case T_FuncCall:
			deparseFuncCall(str, castNode(FuncCall, node));
			break;
		case T_SubLink:
			deparseSubLink(str, castNode(SubLink, node));
			break;
		case T_A_ArrayExpr:
			deparseAArrayExpr(str, castNode(A_ArrayExpr, node));
			break;
		case T_RowExpr:
			deparseRowExpr(str, castNode(RowExpr, node));
			break;
		case T_GroupingFunc:
			deparseGroupingFunc(str, castNode(GroupingFunc, node));
			break;
		default:
			elog(ERROR, "deparse: unpermitted node type in c_expr: %d",
				 (int) nodeTag(node));
			break;
	}
}

// "expr_list" in gram.y
static void deparseExprList(StringInfo str, List *exprs)
{
	ListCell *lc;
	foreach(lc, exprs)
	{
		deparseExpr(str, lfirst(lc));
		if (lnext(exprs, lc))
			appendStringInfoString(str, ", ");
	}
}

// "ColId", "name", "database_name", "access_method" and "index_name" in gram.y
static void deparseColId(StringInfo str, char *s)
{
	appendStringInfoString(str, quote_identifier(s));
}

// "ColLabel", "attr_name"
//
// Note this is kept separate from ColId in case we ever want to be more
// specific on how to handle keywords here
static void deparseColLabel(StringInfo str, char *s)
{
	appendStringInfoString(str, quote_identifier(s));
}

// "SignedIconst" and "Iconst" in gram.y
static void deparseSignedIconst(StringInfo str, Node *node)
{
	appendStringInfo(str, "%d", intVal(node));
}

// "indirection" and "opt_indirection" in gram.y
static void deparseOptIndirection(StringInfo str, List *indirection, int N)
{
	ListCell *lc = NULL;

	for_each_from(lc, indirection, N)
	{
		if (IsA(lfirst(lc), String))
		{
			appendStringInfoChar(str, '.');
			deparseColLabel(str, strVal(lfirst(lc)));
		}
		else if (IsA(lfirst(lc), A_Star))
		{
			appendStringInfoString(str, ".*");
		}
		else if (IsA(lfirst(lc), A_Indices))
		{
			deparseAIndices(str, castNode(A_Indices, lfirst(lc)));
		}
		else
		{
			// No other nodes should appear here
			Assert(false);
		}
	}
}

// "role_list" in gram.y
static void deparseRoleList(StringInfo str, List *roles)
{
	ListCell *lc;

	foreach(lc, roles)
	{
		RoleSpec *role_spec = castNode(RoleSpec, lfirst(lc));
		deparseRoleSpec(str, role_spec);
		if (lnext(roles, lc))
			appendStringInfoString(str, ", ");
	}
}

// "SimpleTypename" in gram.y
static void deparseSimpleTypename(StringInfo str, Node *node)
{
	deparseTypeName(str, castNode(TypeName, node));
}

// "NumericOnly" in gram.y
static void deparseNumericOnly(StringInfo str, union ValUnion *value)
{
	switch (nodeTag(value))
	{
		case T_Integer:
			appendStringInfo(str, "%d", value->ival.ival);
			break;
		case T_Float:
			appendStringInfoString(str, value->sval.sval);
			break;
		default:
			Assert(false);
	}
}

// "NumericOnly_list" in gram.y
static void deparseNumericOnlyList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		deparseNumericOnly(str, (union ValUnion *) lfirst(lc));
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "SeqOptElem" in gram.y
static void deparseSeqOptElem(StringInfo str, DefElem *def_elem)
{
	ListCell *lc;

	if (strcmp(def_elem->defname, "as") == 0)
	{
		appendStringInfoString(str, "AS ");
		deparseSimpleTypename(str, def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "cache") == 0)
	{
		appendStringInfoString(str, "CACHE ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "cycle") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "CYCLE");
	}
	else if (strcmp(def_elem->defname, "cycle") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NO CYCLE");
	}
	else if (strcmp(def_elem->defname, "increment") == 0)
	{
		appendStringInfoString(str, "INCREMENT ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "maxvalue") == 0 && def_elem->arg != NULL)
	{
		appendStringInfoString(str, "MAXVALUE ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "maxvalue") == 0 && def_elem->arg == NULL)
	{
		appendStringInfoString(str, "NO MAXVALUE");
	}
	else if (strcmp(def_elem->defname, "minvalue") == 0 && def_elem->arg != NULL)
	{
		appendStringInfoString(str, "MINVALUE ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "minvalue") == 0 && def_elem->arg == NULL)
	{
		appendStringInfoString(str, "NO MINVALUE");
	}
	else if (strcmp(def_elem->defname, "owned_by") == 0)
	{
		appendStringInfoString(str, "OWNED BY ");
		deparseAnyName(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "sequence_name") == 0)
	{
		appendStringInfoString(str, "SEQUENCE NAME ");
		deparseAnyName(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "start") == 0)
	{
		appendStringInfoString(str, "START ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else if (strcmp(def_elem->defname, "restart") == 0 && def_elem->arg == NULL)
	{
		appendStringInfoString(str, "RESTART");
	}
	else if (strcmp(def_elem->defname, "restart") == 0 && def_elem->arg != NULL)
	{
		appendStringInfoString(str, "RESTART ");
		deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
	}
	else
	{
		Assert(false);
	}
}

// "SeqOptList" in gram.y
static void deparseSeqOptList(StringInfo str, List *options)
{
	ListCell *lc;
	Assert(list_length(options) > 0);
	foreach (lc, options)
	{
		deparseSeqOptElem(str, castNode(DefElem, lfirst(lc)));
		appendStringInfoChar(str, ' ');
	}
}

// "OptSeqOptList" in gram.y
static void deparseOptSeqOptList(StringInfo str, List *options)
{
	if (list_length(options) > 0)
		deparseSeqOptList(str, options);
}

// "OptParenthesizedSeqOptList" in gram.y
static void deparseOptParenthesizedSeqOptList(StringInfo str, List *options)
{
	if (list_length(options) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseSeqOptList(str, options);
		appendStringInfoChar(str, ')');
	}
}

// "opt_drop_behavior" in gram.y
static void deparseOptDropBehavior(StringInfo str, DropBehavior behavior)
{
	switch (behavior)
	{
		case DROP_RESTRICT:
			// Default
			break;
		case DROP_CASCADE:
			appendStringInfoString(str, "CASCADE ");
			break;
	}
}

// "any_operator" in gram.y
static void deparseAnyOperator(StringInfo str, List *op)
{
	Assert(isOp(strVal(llast(op))));
	if (list_length(op) == 2)
	{
		appendStringInfoString(str, quote_identifier(strVal(linitial(op))));
		appendStringInfoChar(str, '.');
		appendStringInfoString(str, strVal(llast(op)));
	}
	else if (list_length(op) == 1)
	{
		appendStringInfoString(str, strVal(llast(op)));
	}
	else
	{
		Assert(false);
	}
}

// "qual_Op" and "qual_all_Op" in gram.y
static void deparseQualOp(StringInfo str, List *op)
{
	if (list_length(op) == 1 && isOp(strVal(linitial(op))))
	{
		appendStringInfoString(str, strVal(linitial(op)));
	}
	else
	{
		appendStringInfoString(str, "OPERATOR(");
		deparseAnyOperator(str, op);
		appendStringInfoString(str, ")");
	}
}

// "subquery_Op" in gram.y
static void deparseSubqueryOp(StringInfo str, List *op)
{
	if (list_length(op) == 1 && strcmp(strVal(linitial(op)), "~~") == 0)
	{
		appendStringInfoString(str, "LIKE");
	}
	else if (list_length(op) == 1 && strcmp(strVal(linitial(op)), "!~~") == 0)
	{
		appendStringInfoString(str, "NOT LIKE");
	}
	else if (list_length(op) == 1 && strcmp(strVal(linitial(op)), "~~*") == 0)
	{
		appendStringInfoString(str, "ILIKE");
	}
	else if (list_length(op) == 1 && strcmp(strVal(linitial(op)), "!~~*") == 0)
	{
		appendStringInfoString(str, "NOT ILIKE");
	}
	else if (list_length(op) == 1 && isOp(strVal(linitial(op))))
	{
		appendStringInfoString(str, strVal(linitial(op)));
	}
	else
	{
		appendStringInfoString(str, "OPERATOR(");
		deparseAnyOperator(str, op);
		appendStringInfoString(str, ")");
	}
}

// Not present directly in gram.y (usually matched by ColLabel)
static void deparseGenericDefElemName(StringInfo str, const char *in)
{
	Assert(in != NULL);
	char *val = pstrdup(in);
	for (unsigned char *p = (unsigned char *) val; *p; p++)
		*p = pg_toupper(*p);
	appendStringInfoString(str, val);
	pfree(val);
}

// "def_arg" and "operator_def_arg" in gram.y
static void deparseDefArg(StringInfo str, Node *arg, bool is_operator_def_arg)
{
	if (IsA(arg, TypeName)) // func_type
	{
		deparseTypeName(str, castNode(TypeName, arg));
	}
	else if (IsA(arg, List)) // qual_all_Op
	{
		List *l = castNode(List, arg);
		Assert(list_length(l) == 1 || list_length(l) == 2);

		// Schema qualified operator
		if (list_length(l) == 2)
		{
			appendStringInfoString(str, "OPERATOR(");
			deparseAnyOperator(str, l);
			appendStringInfoChar(str, ')');
		}
		else if (list_length(l) == 1)
		{
			appendStringInfoString(str, strVal(linitial(l)));
		}
	}
	else if (IsA(arg, Float) || IsA(arg, Integer)) // NumericOnly
	{
		deparseValue(str, (union ValUnion *) arg, DEPARSE_NODE_CONTEXT_NONE);
	}
	else if (IsA(arg, String))
	{
		char *s = strVal(arg);
		if (!is_operator_def_arg && IsA(arg, String) && strcmp(s, "none") == 0) // NONE
		{
			appendStringInfoString(str, "NONE");
		}
		else if (isReservedKeyword(s)) // reserved_keyword
		{
			appendStringInfoString(str, s);
		}
		else // Sconst
		{
			deparseStringLiteral(str, s);
		}
	}
	else 
	{
		Assert(false);
	}
}

// "definition" in gram.y
static void deparseDefinition(StringInfo str, List *options)
{
	ListCell *lc = NULL;

	appendStringInfoChar(str, '(');
	foreach (lc, options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		appendStringInfoString(str, quote_identifier(def_elem->defname));
		if (def_elem->arg != NULL) {
			appendStringInfoString(str, " = ");
			deparseDefArg(str, def_elem->arg, false);
		}

		if (lnext(options, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

// "opt_definition" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptDefinition(StringInfo str, List *options)
{
	if (list_length(options) > 0)
	{
		appendStringInfoString(str, "WITH ");
		deparseDefinition(str, options);
	}
}

// "create_generic_options" in gram.y
static void deparseCreateGenericOptions(StringInfo str, List *options)
{
	ListCell *lc = NULL;

	if (options == NULL)
		return;

	appendStringInfoString(str, "OPTIONS (");
	foreach(lc, options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		appendStringInfoString(str, quote_identifier(def_elem->defname));
		appendStringInfoChar(str, ' ');
		deparseStringLiteral(str, strVal(def_elem->arg));
		if (lnext(options, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoString(str, ")");
}

// "common_func_opt_item" in gram.y
static void deparseCommonFuncOptItem(StringInfo str, DefElem *def_elem)
{
	if (strcmp(def_elem->defname, "strict") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "RETURNS NULL ON NULL INPUT");
	}
	else if (strcmp(def_elem->defname, "strict") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "CALLED ON NULL INPUT");
	}
	else if (strcmp(def_elem->defname, "volatility") == 0 && strcmp(strVal(def_elem->arg), "immutable") == 0)
	{
		appendStringInfoString(str, "IMMUTABLE");
	}
	else if (strcmp(def_elem->defname, "volatility") == 0 && strcmp(strVal(def_elem->arg), "stable") == 0)
	{
		appendStringInfoString(str, "STABLE");
	}
	else if (strcmp(def_elem->defname, "volatility") == 0 && strcmp(strVal(def_elem->arg), "volatile") == 0)
	{
		appendStringInfoString(str, "VOLATILE");
	}
	else if (strcmp(def_elem->defname, "security") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "SECURITY DEFINER");
	}
	else if (strcmp(def_elem->defname, "security") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "SECURITY INVOKER");
	}
	else if (strcmp(def_elem->defname, "leakproof") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "LEAKPROOF");
	}
	else if (strcmp(def_elem->defname, "leakproof") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOT LEAKPROOF");
	}
	else if (strcmp(def_elem->defname, "cost") == 0)
	{
		appendStringInfoString(str, "COST ");
		deparseValue(str, (union ValUnion *) def_elem->arg, DEPARSE_NODE_CONTEXT_NONE);
	}
	else if (strcmp(def_elem->defname, "rows") == 0)
	{
		appendStringInfoString(str, "ROWS ");
		deparseValue(str, (union ValUnion *) def_elem->arg, DEPARSE_NODE_CONTEXT_NONE);
	}
	else if (strcmp(def_elem->defname, "support") == 0)
	{
		appendStringInfoString(str, "SUPPORT ");
		deparseAnyName(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "set") == 0 && IsA(def_elem->arg, VariableSetStmt)) // FunctionSetResetClause
	{
		deparseVariableSetStmt(str, castNode(VariableSetStmt, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "parallel") == 0)
	{
		appendStringInfoString(str, "PARALLEL ");
		appendStringInfoString(str, quote_identifier(strVal(def_elem->arg)));
	}
	else
	{
		Assert(false);
	}
}

// "NonReservedWord_or_Sconst" in gram.y
//
// Note since both identifiers and string constants are allowed here, we
// currently always return an identifier, except:
//
// 1) when the string is empty (since an empty identifier can't be scanned)
// 2) when the value is equal or larger than NAMEDATALEN (64+ characters)
static void deparseNonReservedWordOrSconst(StringInfo str, const char *val)
{
	if (strlen(val) == 0)
		appendStringInfoString(str, "''");
	else if (strlen(val) >= NAMEDATALEN)
		deparseStringLiteral(str, val);
	else
		appendStringInfoString(str, quote_identifier(val));
}

// "func_as" in gram.y
static void deparseFuncAs(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		char *strval = strVal(lfirst(lc));
		if (strstr(strval, "$$") == NULL)
		{
			appendStringInfoString(str, "$$");
			appendStringInfoString(str, strval);
			appendStringInfoString(str, "$$");
		}
		else
		{
			deparseStringLiteral(str, strval);
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "createfunc_opt_item" in gram.y
static void deparseCreateFuncOptItem(StringInfo str, DefElem *def_elem)
{
	ListCell *lc = NULL;

	if (strcmp(def_elem->defname, "as") == 0)
	{
		appendStringInfoString(str, "AS ");
		deparseFuncAs(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "language") == 0)
	{
		appendStringInfoString(str, "LANGUAGE ");
		deparseNonReservedWordOrSconst(str, strVal(def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "transform") == 0)
	{
		List *l = castNode(List, def_elem->arg);
		appendStringInfoString(str, "TRANSFORM ");
		foreach (lc, l)
		{
			appendStringInfoString(str, "FOR TYPE ");
			deparseTypeName(str, castNode(TypeName, lfirst(lc)));
			if (lnext(l, lc))
				appendStringInfoString(str, ", ");
		}
	}
	else if (strcmp(def_elem->defname, "window") == 0)
	{
		appendStringInfoString(str, "WINDOW");
	}
	else
	{
		deparseCommonFuncOptItem(str, def_elem);
	}
}

// "alter_generic_options" in gram.y
static void deparseAlterGenericOptions(StringInfo str, List *options)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "OPTIONS (");
	foreach(lc, options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		switch (def_elem->defaction)
		{
			case DEFELEM_UNSPEC:
				appendStringInfoString(str, quote_identifier(def_elem->defname));
				appendStringInfoChar(str, ' ');
				deparseStringLiteral(str, strVal(def_elem->arg));
				break;
			case DEFELEM_SET:
				appendStringInfoString(str, "SET ");
				appendStringInfoString(str, quote_identifier(def_elem->defname));
				appendStringInfoChar(str, ' ');
				deparseStringLiteral(str, strVal(def_elem->arg));
				break;
			case DEFELEM_ADD:
				appendStringInfoString(str, "ADD ");
				appendStringInfoString(str, quote_identifier(def_elem->defname));
				appendStringInfoChar(str, ' ');
				deparseStringLiteral(str, strVal(def_elem->arg));
				break;
			case DEFELEM_DROP:
				appendStringInfoString(str, "DROP ");
				appendStringInfoString(str, quote_identifier(def_elem->defname));
				break;
		}

		if (lnext(options, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoString(str, ") ");
}

// "func_name" in gram.y
static void deparseFuncName(StringInfo str, List *func_name)
{
	ListCell *lc = NULL;

	foreach(lc, func_name)
	{
		appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
		if (lnext(func_name, lc))
			appendStringInfoChar(str, '.');
	}
}

// "function_with_argtypes" in gram.y
static void deparseFunctionWithArgtypes(StringInfo str, ObjectWithArgs *object_with_args)
{
	ListCell *lc;
	deparseFuncName(str, object_with_args->objname);

	if (!object_with_args->args_unspecified)
	{
		appendStringInfoChar(str, '(');
		List *objargs = object_with_args->objargs;
		if (object_with_args->objfuncargs)
			objargs = object_with_args->objfuncargs;

		foreach(lc, objargs)
		{
			if (IsA(lfirst(lc), FunctionParameter))
				deparseFunctionParameter(str, castNode(FunctionParameter, lfirst(lc)));
			else
				deparseTypeName(str, castNode(TypeName, lfirst(lc)));
			if (lnext(objargs, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ')');
	}
}

// "function_with_argtypes_list" in gram.y
static void deparseFunctionWithArgtypesList(StringInfo str, List *l)
{
	ListCell *lc;

	foreach(lc, l)
	{
		deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, lfirst(lc)));
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "operator_with_argtypes" in gram.y
static void deparseOperatorWithArgtypes(StringInfo str, ObjectWithArgs *object_with_args)
{
	deparseAnyOperator(str, object_with_args->objname);

	Assert(list_length(object_with_args->objargs) == 2);
	appendStringInfoChar(str, '(');
	if (linitial(object_with_args->objargs) == NULL)
		appendStringInfoString(str, "NONE");
	else
		deparseTypeName(str, castNode(TypeName, linitial(object_with_args->objargs)));
	appendStringInfoString(str, ", ");
	if (lsecond(object_with_args->objargs) == NULL)
		appendStringInfoString(str, "NONE");
	else
		deparseTypeName(str, castNode(TypeName, lsecond(object_with_args->objargs)));
	appendStringInfoChar(str, ')');
}

// "aggr_args" in gram.y
static void deparseAggrArgs(StringInfo str, List *aggr_args)
{
	Assert(list_length(aggr_args) == 2);

	ListCell *lc = NULL;
	List *args = linitial(aggr_args);
	int order_by_pos = intVal(lsecond(aggr_args));

	appendStringInfoChar(str, '(');
	if (args == NULL)
	{
		appendStringInfoChar(str, '*');
	}
	else
	{
		foreach(lc, args)
		{
			if (foreach_current_index(lc) == order_by_pos)
			{
				if (foreach_current_index(lc) > 0)
					appendStringInfoChar(str, ' ');
				appendStringInfoString(str, "ORDER BY ");
			}
			else if (foreach_current_index(lc) > 0)
			{
				appendStringInfoString(str, ", ");
			}

			deparseFunctionParameter(str, castNode(FunctionParameter, lfirst(lc)));
		}

		// Repeat the last direct arg as a ordered arg to handle the
		// simplification done by makeOrderedSetArgs in gram.y
		if (order_by_pos == list_length(args))
		{
			appendStringInfoString(str, " ORDER BY ");
			deparseFunctionParameter(str, castNode(FunctionParameter, llast(args)));
		}
	}
	appendStringInfoChar(str, ')');
}

// "aggregate_with_argtypes" in gram.y
static void deparseAggregateWithArgtypes(StringInfo str, ObjectWithArgs *object_with_args)
{
	ListCell *lc = NULL;

	deparseFuncName(str, object_with_args->objname);

	appendStringInfoChar(str, '(');
	if (object_with_args->objargs == NULL && object_with_args->objfuncargs == NULL)
	{
		appendStringInfoChar(str, '*');
	}
	else
	{
		List *objargs = object_with_args->objargs;
		if (object_with_args->objfuncargs)
			objargs = object_with_args->objfuncargs;

		foreach(lc, objargs)
		{
			if (IsA(lfirst(lc), FunctionParameter))
				deparseFunctionParameter(str, castNode(FunctionParameter, lfirst(lc)));
			else
				deparseTypeName(str, castNode(TypeName, lfirst(lc)));
			if (lnext(objargs, lc))
				appendStringInfoString(str, ", ");
		}
	}
	appendStringInfoChar(str, ')');
}

// "columnList" in gram.y
static void deparseColumnList(StringInfo str, List *columns)
{
	ListCell *lc = NULL;
	foreach(lc, columns)
	{
		appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
		if (lnext(columns, lc))
			appendStringInfoString(str, ", ");
	}
}

// "OptTemp" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptTemp(StringInfo str, char relpersistence)
{
	switch (relpersistence)
	{
		case RELPERSISTENCE_PERMANENT:
			// Default
			break;
		case RELPERSISTENCE_UNLOGGED:
			appendStringInfoString(str, "UNLOGGED ");
			break;
		case RELPERSISTENCE_TEMP:
			appendStringInfoString(str, "TEMPORARY ");
			break;
		default:
			Assert(false);
			break;
	}
}

// "relation_expr_list" in gram.y
static void deparseRelationExprList(StringInfo str, List *relation_exprs)
{
	ListCell *lc = NULL;
	foreach(lc, relation_exprs)
	{
		deparseRangeVar(str, castNode(RangeVar, lfirst(lc)), DEPARSE_NODE_CONTEXT_NONE);
		if (lnext(relation_exprs, lc))
			appendStringInfoString(str, ", ");
	}
}

// "handler_name" in gram.y
static void deparseHandlerName(StringInfo str, List *handler_name)
{
	ListCell *lc = NULL;

	foreach(lc, handler_name)
	{
		appendStringInfoString(str, quote_identifier(strVal(lfirst(lc))));
		if (lnext(handler_name, lc))
			appendStringInfoChar(str, '.');
	}
}

// "fdw_options" in gram.y
static void deparseFdwOptions(StringInfo str, List *fdw_options)
{
	ListCell *lc = NULL;

	foreach (lc, fdw_options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		if (strcmp(def_elem->defname, "handler") == 0 && def_elem->arg != NULL)
		{
			appendStringInfoString(str, "HANDLER ");
			deparseHandlerName(str, castNode(List, def_elem->arg));
		}
		else if (strcmp(def_elem->defname, "handler") == 0 && def_elem->arg == NULL)
		{
			appendStringInfoString(str, "NO HANDLER ");
		}
		else if (strcmp(def_elem->defname, "validator") == 0 && def_elem->arg != NULL)
		{
			appendStringInfoString(str, "VALIDATOR ");
			deparseHandlerName(str, castNode(List, def_elem->arg));
		}
		else if (strcmp(def_elem->defname, "validator") == 0 && def_elem->arg == NULL)
		{
			appendStringInfoString(str, "NO VALIDATOR ");
		}
		else
		{
			Assert(false);
		}

		if (lnext(fdw_options, lc))
			appendStringInfoChar(str, ' ');
	}
}

// "type_list" in gram.y
static void deparseTypeList(StringInfo str, List *type_list)
{
	ListCell *lc = NULL;
	foreach(lc, type_list)
	{
		deparseTypeName(str, castNode(TypeName, lfirst(lc)));
		if (lnext(type_list, lc))
			appendStringInfoString(str, ", ");
	}
}

// "opt_boolean_or_string" in gram.y
static void deparseOptBooleanOrString(StringInfo str, char *s)
{
	if (s == NULL)
		return; // No value set
	else if (strcmp(s, "true") == 0)
		appendStringInfoString(str, "TRUE");
	else if (strcmp(s, "false") == 0)
		appendStringInfoString(str, "FALSE");
	else if (strcmp(s, "on") == 0)
		appendStringInfoString(str, "ON");
	else if (strcmp(s, "off") == 0)
		appendStringInfoString(str, "OFF");
	else
		deparseNonReservedWordOrSconst(str, s);
}

static void deparseOptBoolean(StringInfo str, Node *node)
{
	if (node == NULL)
	{
		return;
	}

	switch (nodeTag(node))
	{
		case T_String:
			appendStringInfo(str, " %s", strVal(node));
			break;
		case T_Integer:
			appendStringInfo(str, " %d", intVal(node));
			break;
		case T_Boolean:
			appendStringInfo(str, " %s", boolVal(node) ? "TRUE" : "FALSE");
			break;
		default:
			Assert(false);
			break;
	}
}

bool optBooleanValue(Node *node)
{
	if (node == NULL)
	{
		return true;
	}

	switch (nodeTag(node))
	{
		case T_String: {
			// Longest valid string is "off\0"
			char lower[4];
			strncpy(lower, strVal(node), 4);
			lower[3] = 0;

			if (strcmp(lower, "on") == 0) {
				return true;
			} else if (strcmp(lower, "off") == 0) {
				return false;
			}

			// No sane way to handle this.
			return false;
		}
		case T_Integer:
			return intVal(node) != 0;
		case T_Boolean:
			return boolVal(node);
		default:
			Assert(false);
			return false;
	}
}

// "var_name"
//
// Note this is kept separate from ColId in case we want to improve the
// output of namespaced variable names
static void deparseVarName(StringInfo str, char *s)
{
	deparseColId(str, s);
}

// "var_list"
static void deparseVarList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		if (IsA(lfirst(lc), ParamRef))
		{
			deparseParamRef(str, castNode(ParamRef, lfirst(lc)));
		}
		else if (IsA(lfirst(lc), A_Const))
		{
			A_Const *a_const = castNode(A_Const, lfirst(lc));
			if (IsA(&a_const->val, Integer) || IsA(&a_const->val, Float))
				deparseNumericOnly(str, (union ValUnion *) &a_const->val);
			else if (IsA(&a_const->val, String))
				deparseOptBooleanOrString(str, strVal(&a_const->val));
			else
				Assert(false);
		}
		else if (IsA(lfirst(lc), TypeCast))
		{
			deparseTypeCast(str, castNode(TypeCast, lfirst(lc)), DEPARSE_NODE_CONTEXT_SET_STATEMENT);
		}
		else
		{
			Assert(false);
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "transaction_mode_list" in gram.y
static void deparseTransactionModeList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach (lc, l)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));

		if (strcmp(def_elem->defname, "transaction_isolation") == 0)
		{
			char *s = strVal(&castNode(A_Const, def_elem->arg)->val);
			appendStringInfoString(str, "ISOLATION LEVEL ");
			if (strcmp(s, "read uncommitted") == 0)
				appendStringInfoString(str, "READ UNCOMMITTED");
			else if (strcmp(s, "read committed") == 0)
				appendStringInfoString(str, "READ COMMITTED");
			else if (strcmp(s, "repeatable read") == 0)
				appendStringInfoString(str, "REPEATABLE READ");
			else if (strcmp(s, "serializable") == 0)
				appendStringInfoString(str, "SERIALIZABLE");
			else
				Assert(false);
		}
		else if (strcmp(def_elem->defname, "transaction_read_only") == 0 && intVal(&castNode(A_Const, def_elem->arg)->val) == 1)
		{
			appendStringInfoString(str, "READ ONLY");
		}
		else if (strcmp(def_elem->defname, "transaction_read_only") == 0 && intVal(&castNode(A_Const, def_elem->arg)->val) == 0)
		{
			appendStringInfoString(str, "READ WRITE");
		}
		else if (strcmp(def_elem->defname, "transaction_deferrable") == 0 && intVal(&castNode(A_Const, def_elem->arg)->val) == 1)
		{
			appendStringInfoString(str, "DEFERRABLE");
		}
		else if (strcmp(def_elem->defname, "transaction_deferrable") == 0 && intVal(&castNode(A_Const, def_elem->arg)->val) == 0)
		{
			appendStringInfoString(str, "NOT DEFERRABLE");
		}
		else
		{
			Assert(false);
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "alter_identity_column_option_list" in gram.y
static void deparseAlterIdentityColumnOptionList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach (lc, l)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		if (strcmp(def_elem->defname, "restart") == 0 && def_elem->arg == NULL)
		{
			appendStringInfoString(str, "RESTART");
		}
		else if (strcmp(def_elem->defname, "restart") == 0 && def_elem->arg != NULL)
		{
			appendStringInfoString(str, "RESTART ");
			deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
		}
		else if (strcmp(def_elem->defname, "generated") == 0)
		{
			appendStringInfoString(str, "SET GENERATED ");
			if (intVal(def_elem->arg) == ATTRIBUTE_IDENTITY_ALWAYS)
				appendStringInfoString(str, "ALWAYS");
			else if (intVal(def_elem->arg) == ATTRIBUTE_IDENTITY_BY_DEFAULT)
				appendStringInfoString(str, "BY DEFAULT");
			else
				Assert(false);
		}
		else
		{
			appendStringInfoString(str, "SET ");
			deparseSeqOptElem(str, def_elem);
		}
		if (lnext(l, lc))
			appendStringInfoChar(str, ' ');
	}
}

// "reloptions" in gram.y
static void deparseRelOptions(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	appendStringInfoChar(str, '(');
	foreach(lc, l)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		if (def_elem->defnamespace != NULL)
		{
			appendStringInfoString(str, quote_identifier(def_elem->defnamespace));
			appendStringInfoChar(str, '.');
		}
		if (def_elem->defname != NULL)
			appendStringInfoString(str, quote_identifier(def_elem->defname));
		if (def_elem->defname != NULL && def_elem->arg != NULL)
			appendStringInfoChar(str, '=');
		if (def_elem->arg != NULL)
			deparseDefArg(str, def_elem->arg, false);

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

// "OptWith" and "opt_reloptions" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptWith(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	if (list_length(l) > 0)
	{
		appendStringInfoString(str, "WITH ");
		deparseRelOptions(str, l);
		appendStringInfoChar(str, ' ');
	}
}

// "target_list" and "opt_target_list" in gram.y
static void deparseTargetList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		ResTarget *res_target = castNode(ResTarget, lfirst(lc));

		if (res_target->val == NULL)
			elog(ERROR, "deparse: error in deparseTargetList: ResTarget without val");
		else if (IsA(res_target->val, ColumnRef))
			deparseColumnRef(str, castNode(ColumnRef, res_target->val));
		else
			deparseExpr(str, res_target->val);

		if (res_target->name != NULL) {
			appendStringInfoString(str, " AS ");
			appendStringInfoString(str, quote_identifier(res_target->name));
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "insert_column_list" in gram.y
static void deparseInsertColumnList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		ResTarget *res_target = castNode(ResTarget, lfirst(lc));
		Assert(res_target->name != NULL);
		appendStringInfoString(str, quote_identifier(res_target->name));
		deparseOptIndirection(str, res_target->indirection, 0);
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "xml_attribute_list" in gram.y
static void deparseXmlAttributeList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		ResTarget *res_target = castNode(ResTarget, lfirst(lc));
		Assert(res_target->val != NULL);

		deparseExpr(str, res_target->val);

		if (res_target->name != NULL)
		{
			appendStringInfoString(str, " AS ");
			appendStringInfoString(str, quote_identifier(res_target->name));
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "xml_namespace_list" in gram.y
static void deparseXmlNamespaceList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		ResTarget *res_target = castNode(ResTarget, lfirst(lc));
		Assert(res_target->val != NULL);

		if (res_target->name == NULL)
			appendStringInfoString(str, "DEFAULT ");

		deparseExpr(str, res_target->val);

		if (res_target->name != NULL)
		{
			appendStringInfoString(str, " AS ");
			appendStringInfoString(str, quote_identifier(res_target->name));
		}

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "table_ref" in gram.y
static void deparseTableRef(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_RangeVar:
			deparseRangeVar(str, castNode(RangeVar, node), DEPARSE_NODE_CONTEXT_NONE);
			break;
		case T_RangeTableSample:
			deparseRangeTableSample(str, castNode(RangeTableSample, node));
			break;
		case T_RangeFunction:
			deparseRangeFunction(str, castNode(RangeFunction, node));
			break;
		case T_RangeTableFunc:
			deparseRangeTableFunc(str, castNode(RangeTableFunc, node));
			break;
		case T_RangeSubselect:
			deparseRangeSubselect(str, castNode(RangeSubselect, node));
			break;
		case T_JoinExpr:
			deparseJoinExpr(str, castNode(JoinExpr, node));
			break;
		default:
			Assert(false);
	}
}

// "from_list" in gram.y
static void deparseFromList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		deparseTableRef(str, lfirst(lc));
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "from_clause" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseFromClause(StringInfo str, List *l)
{
	if (list_length(l) > 0)
	{
		appendStringInfoString(str, "FROM ");
		deparseFromList(str, l);
		appendStringInfoChar(str, ' ');
	}
}

// "where_clause" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseWhereClause(StringInfo str, Node *node)
{
	if (node != NULL)
	{
		appendStringInfoString(str, "WHERE ");
		deparseExpr(str, node);
		appendStringInfoChar(str, ' ');
	}
}

// "group_by_list" in gram.y
static void deparseGroupByList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		if (IsA(lfirst(lc), GroupingSet))
			deparseGroupingSet(str, castNode(GroupingSet, lfirst(lc)));
		else
			deparseExpr(str, lfirst(lc));

		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "set_target" in gram.y
static void deparseSetTarget(StringInfo str, ResTarget *res_target)
{
	Assert(res_target->name != NULL);
	deparseColId(str, res_target->name);
	deparseOptIndirection(str, res_target->indirection, 0);
}

// "any_name_list" in gram.y
static void deparseAnyNameList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		deparseAnyName(str, castNode(List, lfirst(lc)));
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "name_list" in gram.y
static void deparseNameList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		deparseColId(str, strVal(lfirst(lc)));
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "opt_sort_clause" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptSortClause(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	if (list_length(l) > 0)
	{
		appendStringInfoString(str, "ORDER BY ");

		foreach(lc, l)
		{
			deparseSortBy(str, castNode(SortBy, lfirst(lc)));
			if (lnext(l, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ' ');
	}
}

// "func_arg_expr" in gram.y
static void deparseFuncArgExpr(StringInfo str, Node *node)
{
	if (IsA(node, NamedArgExpr))
	{
		NamedArgExpr *named_arg_expr = castNode(NamedArgExpr, node);
		appendStringInfoString(str, named_arg_expr->name);
		appendStringInfoString(str, " := ");
		deparseExpr(str, (Node *) named_arg_expr->arg);
	}
	else
	{
		deparseExpr(str, node);
	}
}

// "set_clause_list" in gram.y
static void deparseSetClauseList(StringInfo str, List *target_list)
{
	ListCell *lc;
	ListCell *lc2;
	int skip_next_n_elems = 0;

	Assert(list_length(target_list) > 0);

	foreach(lc, target_list)
	{
		if (skip_next_n_elems > 0)
		{
			skip_next_n_elems--;
			continue;
		}

		if (foreach_current_index(lc) != 0)
			appendStringInfoString(str, ", ");

		ResTarget *res_target = castNode(ResTarget, lfirst(lc));
		Assert(res_target->val != NULL);

		if (IsA(res_target->val, MultiAssignRef))
		{
			MultiAssignRef *r = castNode(MultiAssignRef, res_target->val);
			appendStringInfoString(str, "(");
			for_each_cell(lc2, target_list, lc)
			{
				deparseSetTarget(str, castNode(ResTarget, lfirst(lc2)));
				if (foreach_current_index(lc2) == r->ncolumns - 1) // Last element in this multi-assign
					break;
				else if (lnext(target_list, lc2))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoString(str, ") = ");
			deparseExpr(str, r->source);
			skip_next_n_elems = r->ncolumns - 1;
		}
		else
		{
			deparseSetTarget(str, res_target);
			appendStringInfoString(str, " = ");
			deparseExpr(str, res_target->val);
		}
	}
}

// "func_expr_windowless" in gram.y
static void deparseFuncExprWindowless(StringInfo str, Node* node)
{
	switch (nodeTag(node))
	{
		case T_FuncCall:
			deparseFuncCall(str, castNode(FuncCall, node));
			break;
		case T_SQLValueFunction:
			deparseSQLValueFunction(str, castNode(SQLValueFunction, node));
			break;
		case T_TypeCast:
			deparseTypeCast(str, castNode(TypeCast, node), DEPARSE_NODE_CONTEXT_NONE);
			break;
		case T_CoalesceExpr:
			deparseCoalesceExpr(str, castNode(CoalesceExpr, node));
			break;
		case T_MinMaxExpr:
			deparseMinMaxExpr(str, castNode(MinMaxExpr, node));
			break;
		case T_XmlExpr:
			deparseXmlExpr(str, castNode(XmlExpr, node));
			break;
		case T_XmlSerialize:
			deparseXmlSerialize(str, castNode(XmlSerialize, node));
			break;
		default:
			Assert(false);
	}
}

// "opt_collate" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptCollate(StringInfo str, List *l)
{
	if (list_length(l) > 0)
	{
		appendStringInfoString(str, "COLLATE ");
		deparseAnyName(str, l);
		appendStringInfoChar(str, ' ');
	}
}

// "index_elem" in gram.y
static void deparseIndexElem(StringInfo str, IndexElem* index_elem)
{
	if (index_elem->name != NULL)
	{
		deparseColId(str, index_elem->name);
		appendStringInfoChar(str, ' ');
	}
	else if (index_elem->expr != NULL)
	{
		switch (nodeTag(index_elem->expr))
		{
			case T_FuncCall:
			case T_SQLValueFunction:
			case T_TypeCast:
			case T_CoalesceExpr:
			case T_MinMaxExpr:
			case T_XmlExpr:
			case T_XmlSerialize:
				deparseFuncExprWindowless(str, index_elem->expr);
				break;
			default:
				appendStringInfoChar(str, '(');
				deparseExpr(str, index_elem->expr);
				appendStringInfoString(str, ") ");
		}
	}
	else
	{
		Assert(false);
	}

	deparseOptCollate(str, index_elem->collation);

	if (list_length(index_elem->opclass) > 0)
	{
		deparseAnyName(str, index_elem->opclass);

		if (list_length(index_elem->opclassopts) > 0)
			deparseRelOptions(str, index_elem->opclassopts);

		appendStringInfoChar(str, ' ');
	}

	switch (index_elem->ordering)
	{
		case SORTBY_DEFAULT:
			// Default
			break;
		case SORTBY_ASC:
			appendStringInfoString(str, "ASC ");
			break;
		case SORTBY_DESC:
			appendStringInfoString(str, "DESC ");
			break;
		case SORTBY_USING:
			// Not allowed in CREATE INDEX
			Assert(false);
			break;
	}

	switch (index_elem->nulls_ordering)
	{
		case SORTBY_NULLS_DEFAULT:
			// Default
			break;
		case SORTBY_NULLS_FIRST:
			appendStringInfoString(str, "NULLS FIRST ");
			break;
		case SORTBY_NULLS_LAST:
			appendStringInfoString(str, "NULLS LAST ");
			break;
	}

	removeTrailingSpace(str);
}

// "qualified_name_list" in gram.y
static void deparseQualifiedNameList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach(lc, l)
	{
		deparseRangeVar(str, castNode(RangeVar, lfirst(lc)), DEPARSE_NODE_CONTEXT_NONE);
		if (lnext(l, lc))
			appendStringInfoString(str, ", ");
	}
}

// "OptInherit" in gram.y
//
// Note this method adds a trailing space if a value is output
static void deparseOptInherit(StringInfo str, List *l)
{
	if (list_length(l) > 0)
	{
		appendStringInfoString(str, "INHERITS (");
		deparseQualifiedNameList(str, l);
		appendStringInfoString(str, ") ");
	}
}

// "privilege_target" in gram.y
static void deparsePrivilegeTarget(StringInfo str, GrantTargetType targtype, ObjectType	objtype, List *objs)
{
	switch (targtype)
	{
		case ACL_TARGET_OBJECT:
			switch (objtype)
			{
				case OBJECT_TABLE:
					deparseQualifiedNameList(str, objs);
					break;
				case OBJECT_SEQUENCE:
					appendStringInfoString(str, "SEQUENCE ");
					deparseQualifiedNameList(str, objs);
					break;
				case OBJECT_FDW:
					appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
					deparseNameList(str, objs);
					break;
				case OBJECT_FOREIGN_SERVER:
					appendStringInfoString(str, "FOREIGN SERVER ");
					deparseNameList(str, objs);
					break;
				case OBJECT_FUNCTION:
					appendStringInfoString(str, "FUNCTION ");
					deparseFunctionWithArgtypesList(str, objs);
					break;
				case OBJECT_PROCEDURE:
					appendStringInfoString(str, "PROCEDURE ");
					deparseFunctionWithArgtypesList(str, objs);
					break;
				case OBJECT_ROUTINE:
					appendStringInfoString(str, "ROUTINE ");
					deparseFunctionWithArgtypesList(str, objs);
					break;
				case OBJECT_DATABASE:
					appendStringInfoString(str, "DATABASE ");
					deparseNameList(str, objs);
					break;
				case OBJECT_DOMAIN:
					appendStringInfoString(str, "DOMAIN ");
					deparseAnyNameList(str, objs);
					break;
				case OBJECT_LANGUAGE:
					appendStringInfoString(str, "LANGUAGE ");
					deparseNameList(str, objs);
					break;
				case OBJECT_LARGEOBJECT:
					appendStringInfoString(str, "LARGE OBJECT ");
					deparseNumericOnlyList(str, objs);
					break;
				case OBJECT_SCHEMA:
					appendStringInfoString(str, "SCHEMA ");
					deparseNameList(str, objs);
					break;
				case OBJECT_TABLESPACE:
					appendStringInfoString(str, "TABLESPACE ");
					deparseNameList(str, objs);
					break;
				case OBJECT_TYPE:
					appendStringInfoString(str, "TYPE ");
					deparseAnyNameList(str, objs);
					break;
				default:
					// Other types are not supported here
					Assert(false);
					break;
			}
			break;
		case ACL_TARGET_ALL_IN_SCHEMA:
			switch (objtype)
			{
				case OBJECT_TABLE:
					appendStringInfoString(str, "ALL TABLES IN SCHEMA ");
					deparseNameList(str, objs);
					break;
				case OBJECT_SEQUENCE:
					appendStringInfoString(str, "ALL SEQUENCES IN SCHEMA ");
					deparseNameList(str, objs);
					break;
				case OBJECT_FUNCTION:
					appendStringInfoString(str, "ALL FUNCTIONS IN SCHEMA ");
					deparseNameList(str, objs);
					break;
				case OBJECT_PROCEDURE:
					appendStringInfoString(str, "ALL PROCEDURES IN SCHEMA ");
					deparseNameList(str, objs);
					break;
				case OBJECT_ROUTINE:
					appendStringInfoString(str, "ALL ROUTINES IN SCHEMA ");
					deparseNameList(str, objs);
					break;
				default:
					// Other types are not supported here
					Assert(false);
					break;
			}
			break;
		case ACL_TARGET_DEFAULTS: // defacl_privilege_target
			switch (objtype)
			{
				case OBJECT_TABLE:
					appendStringInfoString(str, "TABLES");
					break;
				case OBJECT_FUNCTION:
					appendStringInfoString(str, "FUNCTIONS");
					break;
				case OBJECT_SEQUENCE:
					appendStringInfoString(str, "SEQUENCES");
					break;
				case OBJECT_TYPE:
					appendStringInfoString(str, "TYPES");
					break;
				case OBJECT_SCHEMA:
					appendStringInfoString(str, "SCHEMAS");
					break;
				default:
					// Other types are not supported here
					Assert(false);
					break;
			}
			break;
	}
}

// "opclass_item_list" in gram.y
static void deparseOpclassItemList(StringInfo str, List *items)
{
	ListCell *lc = NULL;

	foreach (lc, items)
	{
		deparseCreateOpClassItem(str, castNode(CreateOpClassItem, lfirst(lc)));
		if (lnext(items, lc))
			appendStringInfoString(str, ", ");
	}
}

// "createdb_opt_list" in gram.y
static void deparseCreatedbOptList(StringInfo str, List *l)
{
	ListCell *lc = NULL;

	foreach (lc, l)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		if (strcmp(def_elem->defname, "connection_limit") == 0)
			appendStringInfoString(str, "CONNECTION LIMIT");
		else
			deparseGenericDefElemName(str, def_elem->defname);

		appendStringInfoChar(str, ' ');

		if (def_elem->arg == NULL)
			appendStringInfoString(str, "DEFAULT");
		else if (IsA(def_elem->arg, Integer))
			deparseSignedIconst(str, def_elem->arg);
		else if (IsA(def_elem->arg, String))
			deparseOptBooleanOrString(str, strVal(def_elem->arg));

		if (lnext(l, lc))
			appendStringInfoChar(str, ' ');
	}
}

// "utility_option_list" in gram.y
static void deparseUtilityOptionList(StringInfo str, List *options)
{
	ListCell *lc = NULL;
	char *defname = NULL;

	if (list_length(options) > 0)
	{
		appendStringInfoChar(str, '(');
		foreach(lc, options)
		{
			DefElem *def_elem = castNode(DefElem, lfirst(lc));
			deparseGenericDefElemName(str, def_elem->defname);

			if (def_elem->arg != NULL)
			{
				appendStringInfoChar(str, ' ');
				if (IsA(def_elem->arg, Integer) || IsA(def_elem->arg, Float))
					deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
				else if (IsA(def_elem->arg, String))
					deparseOptBooleanOrString(str, strVal(def_elem->arg));
				else
					Assert(false);
			}

			if (lnext(options, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoString(str, ") ");
	}
}

static void deparseSelectStmt(StringInfo str, SelectStmt *stmt)
{
	const ListCell *lc = NULL;
	const ListCell *lc2 = NULL;

	if (stmt->withClause)
	{
		deparseWithClause(str, stmt->withClause);
		appendStringInfoChar(str, ' ');
	}

	switch (stmt->op) {
		case SETOP_NONE:
			if (list_length(stmt->valuesLists) > 0)
			{
				const ListCell *lc;
				appendStringInfoString(str, "VALUES ");

				foreach(lc, stmt->valuesLists)
				{
					appendStringInfoChar(str, '(');
					deparseExprList(str, lfirst(lc));
					appendStringInfoChar(str, ')');
					if (lnext(stmt->valuesLists, lc))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoChar(str, ' ');
				break;
			}

			appendStringInfoString(str, "SELECT ");

			if (list_length(stmt->targetList) > 0)
			{
				if (stmt->distinctClause != NULL)
				{
					appendStringInfoString(str, "DISTINCT ");

					if (list_length(stmt->distinctClause) > 0 && linitial(stmt->distinctClause) != NULL)
					{
						appendStringInfoString(str, "ON (");
						deparseExprList(str, stmt->distinctClause);
						appendStringInfoString(str, ") ");
					}
				}

				deparseTargetList(str, stmt->targetList);
				appendStringInfoChar(str, ' ');
			}

			if (stmt->intoClause != NULL)
			{
				appendStringInfoString(str, "INTO ");
				deparseOptTemp(str, stmt->intoClause->rel->relpersistence);
				deparseIntoClause(str, stmt->intoClause);
				appendStringInfoChar(str, ' ');
			}

			deparseFromClause(str, stmt->fromClause);
			deparseWhereClause(str, stmt->whereClause);

			if (list_length(stmt->groupClause) > 0)
			{
				appendStringInfoString(str, "GROUP BY ");
				if (stmt->groupDistinct)
					appendStringInfoString(str, "DISTINCT ");
				deparseGroupByList(str, stmt->groupClause);
				appendStringInfoChar(str, ' ');
			}

			if (stmt->havingClause != NULL)
			{
				appendStringInfoString(str, "HAVING ");
				deparseExpr(str, stmt->havingClause);
				appendStringInfoChar(str, ' ');
			}

			if (stmt->windowClause != NULL)
			{
				appendStringInfoString(str, "WINDOW ");
				foreach(lc, stmt->windowClause)
				{
					WindowDef *window_def = castNode(WindowDef, lfirst(lc));
					Assert(window_def->name != NULL);
					appendStringInfoString(str, window_def->name);
					appendStringInfoString(str, " AS ");
					deparseWindowDef(str, window_def);
					if (lnext(stmt->windowClause, lc))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoChar(str, ' ');
			}
			break;
		case SETOP_UNION:
		case SETOP_INTERSECT:
		case SETOP_EXCEPT:
			{
				bool need_larg_parens =
					list_length(stmt->larg->sortClause) > 0 ||
					stmt->larg->limitOffset != NULL ||
					stmt->larg->limitCount != NULL ||
					list_length(stmt->larg->lockingClause) > 0 ||
					stmt->larg->withClause != NULL ||
					stmt->larg->op != SETOP_NONE;
				bool need_rarg_parens =
					list_length(stmt->rarg->sortClause) > 0 ||
					stmt->rarg->limitOffset != NULL ||
					stmt->rarg->limitCount != NULL ||
					list_length(stmt->rarg->lockingClause) > 0 ||
					stmt->rarg->withClause != NULL ||
					stmt->rarg->op != SETOP_NONE;
				if (need_larg_parens)
					appendStringInfoChar(str, '(');
				deparseSelectStmt(str, stmt->larg);
				if (need_larg_parens)
					appendStringInfoChar(str, ')');
				switch (stmt->op)
				{
					case SETOP_UNION:
						appendStringInfoString(str, " UNION ");
						break;
					case SETOP_INTERSECT:
						appendStringInfoString(str, " INTERSECT ");
						break;
					case SETOP_EXCEPT:
						appendStringInfoString(str, " EXCEPT ");
						break;
					default:
						Assert(false);
				}
				if (stmt->all)
					appendStringInfoString(str, "ALL ");
				if (need_rarg_parens)
					appendStringInfoChar(str, '(');
				deparseSelectStmt(str, stmt->rarg);
				if (need_rarg_parens)
					appendStringInfoChar(str, ')');
				appendStringInfoChar(str, ' ');
			}
			break;
	}

	deparseOptSortClause(str, stmt->sortClause);

	if (stmt->limitCount != NULL)
	{
		if (stmt->limitOption == LIMIT_OPTION_COUNT)
			appendStringInfoString(str, "LIMIT ");
		else if (stmt->limitOption == LIMIT_OPTION_WITH_TIES)
			appendStringInfoString(str, "FETCH FIRST ");

		if (IsA(stmt->limitCount, A_Const) && castNode(A_Const, stmt->limitCount)->isnull)
			appendStringInfoString(str, "ALL");
		else if (stmt->limitOption == LIMIT_OPTION_WITH_TIES)
			deparseCExpr(str, stmt->limitCount);
		else
			deparseExpr(str, stmt->limitCount);

		appendStringInfoChar(str, ' ');

		if (stmt->limitOption == LIMIT_OPTION_WITH_TIES)
			appendStringInfoString(str, "ROWS WITH TIES ");
	}

	if (stmt->limitOffset != NULL)
	{
		appendStringInfoString(str, "OFFSET ");
		deparseExpr(str, stmt->limitOffset);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(stmt->lockingClause) > 0)
	{
		foreach(lc, stmt->lockingClause)
		{
			deparseLockingClause(str, castNode(LockingClause, lfirst(lc)));
			if (lnext(stmt->lockingClause, lc))
				appendStringInfoString(str, " ");
		}
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseIntoClause(StringInfo str, IntoClause *into_clause)
{
	ListCell *lc;

	deparseRangeVar(str, into_clause->rel, DEPARSE_NODE_CONTEXT_NONE); /* target relation name */

	if (list_length(into_clause->colNames) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseColumnList(str, into_clause->colNames);
		appendStringInfoChar(str, ')');
	}
	appendStringInfoChar(str, ' ');

	if (into_clause->accessMethod != NULL)
	{
		appendStringInfoString(str, "USING ");
		appendStringInfoString(str, quote_identifier(into_clause->accessMethod));
		appendStringInfoChar(str, ' ');
	}

	deparseOptWith(str, into_clause->options);

	switch (into_clause->onCommit)
	{
		case ONCOMMIT_NOOP:
			// No clause
			break;
		case ONCOMMIT_PRESERVE_ROWS:
			appendStringInfoString(str, "ON COMMIT PRESERVE ROWS ");
			break;
		case ONCOMMIT_DELETE_ROWS:
			appendStringInfoString(str, "ON COMMIT DELETE ROWS ");
			break;
		case ONCOMMIT_DROP:
			appendStringInfoString(str, "ON COMMIT DROP ");
			break;
	}

	if (into_clause->tableSpaceName != NULL)
	{
		appendStringInfoString(str, "TABLESPACE ");
		appendStringInfoString(str, quote_identifier(into_clause->tableSpaceName));
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseRangeVar(StringInfo str, RangeVar *range_var, DeparseNodeContext context)
{
	if (!range_var->inh && context != DEPARSE_NODE_CONTEXT_CREATE_TYPE && context != DEPARSE_NODE_CONTEXT_ALTER_TYPE)
		appendStringInfoString(str, "ONLY ");

	if (range_var->catalogname != NULL)
	{
		appendStringInfoString(str, quote_identifier(range_var->catalogname));
		appendStringInfoChar(str, '.');
	}

	if (range_var->schemaname != NULL)
	{
		appendStringInfoString(str, quote_identifier(range_var->schemaname));
		appendStringInfoChar(str, '.');
	}

	Assert(range_var->relname != NULL);
	appendStringInfoString(str, quote_identifier(range_var->relname));
	appendStringInfoChar(str, ' ');

	if (range_var->alias != NULL)
	{
		if (context == DEPARSE_NODE_CONTEXT_INSERT_RELATION)
			appendStringInfoString(str, "AS ");
		deparseAlias(str, range_var->alias);
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

void deparseRawStmt(StringInfo str, RawStmt *raw_stmt)
{
	if (raw_stmt->stmt == NULL)
		elog(ERROR, "deparse error in deparseRawStmt: RawStmt with empty Stmt");

	deparseStmt(str, raw_stmt->stmt);
}

static void deparseAlias(StringInfo str, Alias *alias)
{
	appendStringInfoString(str, quote_identifier(alias->aliasname));

	if (list_length(alias->colnames) > 0)
	{
		const ListCell *lc = NULL;
		appendStringInfoChar(str, '(');
		deparseNameList(str, alias->colnames);
		appendStringInfoChar(str, ')');
	}
}

static void deparseAConst(StringInfo str, A_Const *a_const)
{
	union ValUnion *val = a_const->isnull ? NULL : &a_const->val;
	deparseValue(str, val, DEPARSE_NODE_CONTEXT_CONSTANT);
}

static void deparseFuncCall(StringInfo str, FuncCall *func_call)
{
	const ListCell *lc = NULL;

	Assert(list_length(func_call->funcname) > 0);

	if (list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "overlay") == 0 &&
		list_length(func_call->args) == 4)
	{
		/*
		 * Note that this is a bit odd, but "OVERLAY" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.overlay)
		 */
		appendStringInfoString(str, "OVERLAY(");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " PLACING ");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, " FROM ");
		deparseExpr(str, lthird(func_call->args));
		appendStringInfoString(str, " FOR ");
		deparseExpr(str, lfourth(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "substring") == 0)
	{
		/*
		 * "SUBSTRING" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.substring)
		 */
		Assert(list_length(func_call->args) == 2 || list_length(func_call->args) == 3);
		appendStringInfoString(str, "SUBSTRING(");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " FROM ");
		deparseExpr(str, lsecond(func_call->args));
		if (list_length(func_call->args) == 3)
		{
			appendStringInfoString(str, " FOR ");
			deparseExpr(str, lthird(func_call->args));
		}
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "position") == 0 &&
		list_length(func_call->args) == 2)
	{
		/*
		 * "POSITION" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.position)
		 * Note that the first and second arguments are switched in this format
		 */
		appendStringInfoString(str, "POSITION(");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, " IN ");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "overlay") == 0 &&
		list_length(func_call->args) == 3)
	{
		/*
		 * "OVERLAY" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.overlay)
		 */
		appendStringInfoString(str, "overlay(");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " placing ");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, " from ");
		deparseExpr(str, lthird(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "pg_collation_for") == 0 &&
		list_length(func_call->args) == 1)
	{
		/*
		 * "collation for" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.overlay)
		 */
		appendStringInfoString(str, "collation for (");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "extract") == 0 &&
		list_length(func_call->args) == 2)
	{
		/*
		 * "EXTRACT" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.extract)
		 */
		appendStringInfoString(str, "extract (");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " FROM ");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "overlaps") == 0 &&
		list_length(func_call->args) == 4)
	{
		/*
		 * "OVERLAPS" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.overlaps)
		 * format: (start_1, end_1) overlaps (start_2, end_2)
		 */
		appendStringInfoChar(str, '(');
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, ", ");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, ") ");

		appendStringInfoString(str, "overlaps ");
		appendStringInfoChar(str, '(');
		deparseExpr(str, lthird(func_call->args));
		appendStringInfoString(str, ", ");
		deparseExpr(str, lfourth(func_call->args));
		appendStringInfoString(str, ") ");
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		(
			strcmp(strVal(lsecond(func_call->funcname)), "ltrim") == 0 ||
			strcmp(strVal(lsecond(func_call->funcname)), "btrim") == 0 ||
			strcmp(strVal(lsecond(func_call->funcname)), "rtrim") == 0
		))
	{
		/*
		 * "TRIM " is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.ltrim)
		 * Note that the first and second arguments are switched in this format
		 */
		Assert(list_length(func_call->args) == 1 || list_length(func_call->args) == 2);
		appendStringInfoString(str, "TRIM (");
		if (strcmp(strVal(lsecond(func_call->funcname)), "ltrim") == 0)
			appendStringInfoString(str, "LEADING ");
		else if (strcmp(strVal(lsecond(func_call->funcname)), "btrim") == 0)
			appendStringInfoString(str, "BOTH ");
		else if (strcmp(strVal(lsecond(func_call->funcname)), "rtrim") == 0)
			appendStringInfoString(str, "TRAILING ");

		if (list_length(func_call->args) == 2)
			deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, " FROM ");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "timezone") == 0 &&
		list_length(func_call->args) == 2)
	{
		/*
		 * "AT TIME ZONE" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.timezone)
		 * Note that the arguments are swapped in this case
		 */
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoString(str, " AT TIME ZONE ");
		deparseExpr(str, linitial(func_call->args));
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "normalize") == 0)
	{
		/*
		 * "NORMALIZE" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.normalize)
		 */
		Assert(list_length(func_call->args) == 1 || list_length(func_call->args) == 2);
		appendStringInfoString(str, "normalize (");

		deparseExpr(str, linitial(func_call->args));
		if (list_length(func_call->args) == 2)
		{
			appendStringInfoString(str, ", ");
			Assert(IsA(lsecond(func_call->args), A_Const));
			A_Const *aconst = lsecond(func_call->args);
			deparseValue(str, &aconst->val, DEPARSE_NODE_CONTEXT_NONE);
		}
		appendStringInfoChar(str, ')');
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "is_normalized") == 0)
	{
		/*
		 * "IS NORMALIZED" is a keyword on its own merit, and only accepts the
		 * keyword parameter style when its called as a keyword, not as a regular function (i.e. pg_catalog.is_normalized)
		 */
		Assert(list_length(func_call->args) == 1 || list_length(func_call->args) == 2);

		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " IS ");
		if (list_length(func_call->args) == 2)
		{
			Assert(IsA(lsecond(func_call->args), A_Const));
			A_Const *aconst = lsecond(func_call->args);
			deparseValue(str, &aconst->val, DEPARSE_NODE_CONTEXT_NONE);
		}
		appendStringInfoString(str, " NORMALIZED ");
		return;
	} else if (func_call->funcformat == COERCE_SQL_SYNTAX &&
		list_length(func_call->funcname) == 2 &&
		strcmp(strVal(linitial(func_call->funcname)), "pg_catalog") == 0 &&
		strcmp(strVal(lsecond(func_call->funcname)), "xmlexists") == 0 &&
		list_length(func_call->args) == 2)
	{
		appendStringInfoString(str, "xmlexists (");
		deparseExpr(str, linitial(func_call->args));
		appendStringInfoString(str, " PASSING ");
		deparseExpr(str, lsecond(func_call->args));
		appendStringInfoChar(str, ')');
		return;
	}
		
	deparseFuncName(str, func_call->funcname);
	appendStringInfoChar(str, '(');

	if (func_call->agg_distinct)
		appendStringInfoString(str, "DISTINCT ");

	if (func_call->agg_star)
	{
		appendStringInfoChar(str, '*');
	}
	else if (list_length(func_call->args) > 0)
	{
		foreach(lc, func_call->args)
		{
			if (func_call->func_variadic && !lnext(func_call->args, lc))
				appendStringInfoString(str, "VARIADIC ");
			deparseFuncArgExpr(str, lfirst(lc));
			if (lnext(func_call->args, lc))
				appendStringInfoString(str, ", ");
		}
	}
	appendStringInfoChar(str, ' ');

	if (func_call->agg_order != NULL && !func_call->agg_within_group)
	{
		deparseOptSortClause(str, func_call->agg_order);
	}

	removeTrailingSpace(str);
	appendStringInfoString(str, ") ");

	if (func_call->agg_order != NULL && func_call->agg_within_group)
	{
		appendStringInfoString(str, "WITHIN GROUP (");
		deparseOptSortClause(str, func_call->agg_order);
		removeTrailingSpace(str);
		appendStringInfoString(str, ") ");
	}

	if (func_call->agg_filter)
	{
		appendStringInfoString(str, "FILTER (WHERE ");
		deparseExpr(str, func_call->agg_filter);
		appendStringInfoString(str, ") ");
	}

	if (func_call->over)
	{
		appendStringInfoString(str, "OVER ");
		if (func_call->over->name)
			appendStringInfoString(str, func_call->over->name);
		else
			deparseWindowDef(str, func_call->over);
	}

	removeTrailingSpace(str);
}

static void deparseWindowDef(StringInfo str, WindowDef* window_def)
{
	ListCell *lc;

	// The parent node is responsible for outputting window_def->name

	appendStringInfoChar(str, '(');

	if (window_def->refname != NULL)
	{
		appendStringInfoString(str, quote_identifier(window_def->refname));
		appendStringInfoChar(str, ' ');
	}

	if (list_length(window_def->partitionClause) > 0)
	{
		appendStringInfoString(str, "PARTITION BY ");
		deparseExprList(str, window_def->partitionClause);
		appendStringInfoChar(str, ' ');
	}

	deparseOptSortClause(str, window_def->orderClause);

	if (window_def->frameOptions & FRAMEOPTION_NONDEFAULT)
	{
		if (window_def->frameOptions & FRAMEOPTION_RANGE)
			appendStringInfoString(str, "RANGE ");
		else if (window_def->frameOptions & FRAMEOPTION_ROWS)
			appendStringInfoString(str, "ROWS ");
		else if (window_def->frameOptions & FRAMEOPTION_GROUPS)
			appendStringInfoString(str, "GROUPS ");
	
		if (window_def->frameOptions & FRAMEOPTION_BETWEEN)
			appendStringInfoString(str, "BETWEEN ");

		// frame_start
		if (window_def->frameOptions & FRAMEOPTION_START_UNBOUNDED_PRECEDING)
		{
			appendStringInfoString(str, "UNBOUNDED PRECEDING ");
		}
		else if (window_def->frameOptions & FRAMEOPTION_START_UNBOUNDED_FOLLOWING)
		{
			Assert(false); // disallowed
		}
		else if (window_def->frameOptions & FRAMEOPTION_START_CURRENT_ROW)
		{
			appendStringInfoString(str, "CURRENT ROW ");
		}
		else if (window_def->frameOptions & FRAMEOPTION_START_OFFSET_PRECEDING)
		{
			Assert(window_def->startOffset != NULL);
			deparseExpr(str, window_def->startOffset);
			appendStringInfoString(str, " PRECEDING ");
		}
		else if (window_def->frameOptions & FRAMEOPTION_START_OFFSET_FOLLOWING)
		{
			Assert(window_def->startOffset != NULL);
			deparseExpr(str, window_def->startOffset);
			appendStringInfoString(str, " FOLLOWING ");
		}

		if (window_def->frameOptions & FRAMEOPTION_BETWEEN)
		{
			appendStringInfoString(str, "AND ");

			// frame_end
			if (window_def->frameOptions & FRAMEOPTION_END_UNBOUNDED_PRECEDING)
			{
				Assert(false); // disallowed
			}
			else if (window_def->frameOptions & FRAMEOPTION_END_UNBOUNDED_FOLLOWING)
			{
				appendStringInfoString(str, "UNBOUNDED FOLLOWING ");
			}
			else if (window_def->frameOptions & FRAMEOPTION_END_CURRENT_ROW)
			{
				appendStringInfoString(str, "CURRENT ROW ");
			}
			else if (window_def->frameOptions & FRAMEOPTION_END_OFFSET_PRECEDING)
			{
				Assert(window_def->endOffset != NULL);
				deparseExpr(str, window_def->endOffset);
				appendStringInfoString(str, " PRECEDING ");
			}
			else if (window_def->frameOptions & FRAMEOPTION_END_OFFSET_FOLLOWING)
			{
				Assert(window_def->endOffset != NULL);
				deparseExpr(str, window_def->endOffset);
				appendStringInfoString(str, " FOLLOWING ");
			}
		}

		if (window_def->frameOptions & FRAMEOPTION_EXCLUDE_CURRENT_ROW)
			appendStringInfoString(str, "EXCLUDE CURRENT ROW ");
		else if (window_def->frameOptions & FRAMEOPTION_EXCLUDE_GROUP)
			appendStringInfoString(str, "EXCLUDE GROUP ");
		else if (window_def->frameOptions & FRAMEOPTION_EXCLUDE_TIES)
			appendStringInfoString(str, "EXCLUDE TIES ");
	}

	removeTrailingSpace(str);
	appendStringInfoChar(str, ')');
}

static void deparseColumnRef(StringInfo str, ColumnRef* column_ref)
{
	Assert(list_length(column_ref->fields) >= 1);

	if (IsA(linitial(column_ref->fields), A_Star))
		deparseAStar(str, castNode(A_Star, linitial(column_ref->fields)));
	else if (IsA(linitial(column_ref->fields), String))
		deparseColLabel(str, strVal(linitial(column_ref->fields)));

	deparseOptIndirection(str, column_ref->fields, 1);
}

static void deparseSubLink(StringInfo str, SubLink* sub_link)
{
	switch (sub_link->subLinkType) {
		case EXISTS_SUBLINK:
			appendStringInfoString(str, "EXISTS (");
			deparseSelectStmt(str, castNode(SelectStmt, sub_link->subselect));
			appendStringInfoChar(str, ')');
			return;
		case ALL_SUBLINK:
			deparseExpr(str, sub_link->testexpr);
			appendStringInfoChar(str, ' ');
			deparseSubqueryOp(str, sub_link->operName);
			appendStringInfoString(str, " ALL (");
			deparseSelectStmt(str, castNode(SelectStmt, sub_link->subselect));
			appendStringInfoChar(str, ')');
			return;
		case ANY_SUBLINK:
			deparseExpr(str, sub_link->testexpr);
			if (list_length(sub_link->operName) > 0)
			{
				appendStringInfoChar(str, ' ');
				deparseSubqueryOp(str, sub_link->operName);
				appendStringInfoString(str, " ANY ");
			}
			else
			{
				appendStringInfoString(str, " IN ");
			}
			appendStringInfoChar(str, '(');
			deparseSelectStmt(str, castNode(SelectStmt, sub_link->subselect));
			appendStringInfoChar(str, ')');
			return;
		case ROWCOMPARE_SUBLINK:
			// Not present in raw parse trees
			Assert(false);
			return;
		case EXPR_SUBLINK:
			appendStringInfoString(str, "(");
			deparseSelectStmt(str, castNode(SelectStmt, sub_link->subselect));
			appendStringInfoChar(str, ')');
			return;
		case MULTIEXPR_SUBLINK:
			// Not present in raw parse trees
			Assert(false);
			return;
		case ARRAY_SUBLINK:
			appendStringInfoString(str, "ARRAY(");
			deparseSelectStmt(str, castNode(SelectStmt, sub_link->subselect));
			appendStringInfoChar(str, ')');
			return;
		case CTE_SUBLINK: /* for SubPlans only */
			// Not present in raw parse trees
			Assert(false);
			return;
	}
}

static void deparseAExpr(StringInfo str, A_Expr* a_expr, DeparseNodeContext context)
{
	ListCell *lc;
	char *name;

	bool need_lexpr_parens = a_expr->lexpr != NULL && (IsA(a_expr->lexpr, BoolExpr) || IsA(a_expr->lexpr, NullTest) || IsA(a_expr->lexpr, A_Expr));
	bool need_rexpr_parens = a_expr->rexpr != NULL && (IsA(a_expr->rexpr, BoolExpr) || IsA(a_expr->rexpr, NullTest) || IsA(a_expr->rexpr, A_Expr));

	switch (a_expr->kind) {
		case AEXPR_OP: /* normal operator */
			{
				bool need_outer_parens = context == DEPARSE_NODE_CONTEXT_A_EXPR;

				if (need_outer_parens)
					appendStringInfoChar(str, '(');
				if (a_expr->lexpr != NULL)
				{
					if (need_lexpr_parens)
						appendStringInfoChar(str, '(');
					deparseExpr(str, a_expr->lexpr);
					if (need_lexpr_parens)
						appendStringInfoChar(str, ')');
					appendStringInfoChar(str, ' ');
				}
				deparseQualOp(str, a_expr->name);
				if (a_expr->rexpr != NULL)
				{
					appendStringInfoChar(str, ' ');
					if (need_rexpr_parens)
						appendStringInfoChar(str, '(');
					deparseExpr(str, a_expr->rexpr);
					if (need_rexpr_parens)
						appendStringInfoChar(str, ')');
				}

				if (need_outer_parens)
					appendStringInfoChar(str, ')');
			}
			return;
		case AEXPR_OP_ANY: /* scalar op ANY (array) */
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');
			deparseSubqueryOp(str, a_expr->name);
			appendStringInfoString(str, " ANY(");
			deparseExpr(str, a_expr->rexpr);
			appendStringInfoChar(str, ')');
			return;
		case AEXPR_OP_ALL: /* scalar op ALL (array) */
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');
			deparseSubqueryOp(str, a_expr->name);
			appendStringInfoString(str, " ALL(");
			deparseExpr(str, a_expr->rexpr);
			appendStringInfoChar(str, ')');
			return;
		case AEXPR_DISTINCT: /* IS DISTINCT FROM - name must be "=" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			Assert(strcmp(strVal(linitial(a_expr->name)), "=") == 0);

			if (need_lexpr_parens)
				appendStringInfoChar(str, '(');
			deparseExpr(str, a_expr->lexpr);
			if (need_lexpr_parens)
				appendStringInfoChar(str, ')');
			appendStringInfoString(str, " IS DISTINCT FROM ");
			if (need_rexpr_parens)
				appendStringInfoChar(str, '(');
			deparseExpr(str, a_expr->rexpr);
			if (need_rexpr_parens)
				appendStringInfoChar(str, ')');
			return;
		case AEXPR_NOT_DISTINCT: /* IS NOT DISTINCT FROM - name must be "=" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			Assert(strcmp(strVal(linitial(a_expr->name)), "=") == 0);

			deparseExpr(str, a_expr->lexpr);
			appendStringInfoString(str, " IS NOT DISTINCT FROM ");
			deparseExpr(str, a_expr->rexpr);
			return;
		case AEXPR_NULLIF: /* NULLIF - name must be "=" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			Assert(strcmp(strVal(linitial(a_expr->name)), "=") == 0);

			appendStringInfoString(str, "NULLIF(");
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoString(str, ", ");
			deparseExpr(str, a_expr->rexpr);
			appendStringInfoChar(str, ')');
			return;
		case AEXPR_IN: /* [NOT] IN - name must be "=" or "<>" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			Assert(IsA(a_expr->rexpr, List));
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');
			name = ((union ValUnion *) linitial(a_expr->name))->sval.sval;
			if (strcmp(name, "=") == 0) {
				appendStringInfoString(str, "IN ");
			} else if (strcmp(name, "<>") == 0) {
				appendStringInfoString(str, "NOT IN ");
			} else {
				Assert(false);
			}
			appendStringInfoChar(str, '(');
			if (IsA(a_expr->rexpr, SubLink))
				deparseSubLink(str, castNode(SubLink, a_expr->rexpr));
			else
				deparseExprList(str, castNode(List, a_expr->rexpr));
			appendStringInfoChar(str, ')');
			return;
		case AEXPR_LIKE: /* [NOT] LIKE - name must be "~~" or "!~~" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');

			name = ((union ValUnion *) linitial(a_expr->name))->sval.sval;
			if (strcmp(name, "~~") == 0) {
				appendStringInfoString(str, "LIKE ");
			} else if (strcmp(name, "!~~") == 0) {
				appendStringInfoString(str, "NOT LIKE ");
			} else {
				Assert(false);
			}

			deparseExpr(str, a_expr->rexpr);
			return;
		case AEXPR_ILIKE: /* [NOT] ILIKE - name must be "~~*" or "!~~*" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');

			name = ((union ValUnion *) linitial(a_expr->name))->sval.sval;
			if (strcmp(name, "~~*") == 0) {
				appendStringInfoString(str, "ILIKE ");
			} else if (strcmp(name, "!~~*") == 0) {
				appendStringInfoString(str, "NOT ILIKE ");
			} else {
				Assert(false);
			}

			deparseExpr(str, a_expr->rexpr);
			return;
		case AEXPR_SIMILAR: /* [NOT] SIMILAR - name must be "~" or "!~" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');

			name = ((union ValUnion *) linitial(a_expr->name))->sval.sval;
			if (strcmp(name, "~") == 0) {
				appendStringInfoString(str, "SIMILAR TO ");
			} else if (strcmp(name, "!~") == 0) {
				appendStringInfoString(str, "NOT SIMILAR TO ");
			} else {
				Assert(false);
			}

			FuncCall *n = castNode(FuncCall, a_expr->rexpr);
			Assert(list_length(n->funcname) == 2);
			Assert(strcmp(strVal(linitial(n->funcname)), "pg_catalog") == 0);
			Assert(strcmp(strVal(lsecond(n->funcname)), "similar_to_escape") == 0);
			Assert(list_length(n->args) == 1 || list_length(n->args) == 2);

			deparseExpr(str, linitial(n->args));
			if (list_length(n->args) == 2)
			{
				appendStringInfoString(str, " ESCAPE ");
				deparseExpr(str, lsecond(n->args));
			}

			return;
		case AEXPR_BETWEEN: /* name must be "BETWEEN" */
		case AEXPR_NOT_BETWEEN: /* name must be "NOT BETWEEN" */
		case AEXPR_BETWEEN_SYM: /* name must be "BETWEEN SYMMETRIC" */
		case AEXPR_NOT_BETWEEN_SYM: /* name must be "NOT BETWEEN SYMMETRIC" */
			Assert(list_length(a_expr->name) == 1);
			Assert(IsA(linitial(a_expr->name), String));
			Assert(IsA(a_expr->rexpr, List));

			deparseExpr(str, a_expr->lexpr);
			appendStringInfoChar(str, ' ');
			appendStringInfoString(str, strVal(linitial(a_expr->name)));
			appendStringInfoChar(str, ' ');

			foreach(lc, castNode(List, a_expr->rexpr)) {
				deparseExpr(str, lfirst(lc));
				if (lnext(castNode(List, a_expr->rexpr), lc))
					appendStringInfoString(str, " AND ");
			}
			return;
	}
}

static void deparseBoolExpr(StringInfo str, BoolExpr *bool_expr)
{
	const ListCell *lc = NULL;
	switch (bool_expr->boolop)
	{
		case AND_EXPR:
			foreach(lc, bool_expr->args)
			{
				// Put parantheses around AND + OR nodes that are inside
				bool need_parens = IsA(lfirst(lc), BoolExpr) && (castNode(BoolExpr, lfirst(lc))->boolop == AND_EXPR || castNode(BoolExpr, lfirst(lc))->boolop == OR_EXPR);

				if (need_parens)
					appendStringInfoChar(str, '(');

				deparseExpr(str, lfirst(lc));

				if (need_parens)
					appendStringInfoChar(str, ')');

				if (lnext(bool_expr->args, lc))
					appendStringInfoString(str, " AND ");
			}
			return;
		case OR_EXPR:
			foreach(lc, bool_expr->args)
			{
				// Put parantheses around AND + OR nodes that are inside
				bool need_parens = IsA(lfirst(lc), BoolExpr) && (castNode(BoolExpr, lfirst(lc))->boolop == AND_EXPR || castNode(BoolExpr, lfirst(lc))->boolop == OR_EXPR);

				if (need_parens)
					appendStringInfoChar(str, '(');

				deparseExpr(str, lfirst(lc));

				if (need_parens)
					appendStringInfoChar(str, ')');

				if (lnext(bool_expr->args, lc))
					appendStringInfoString(str, " OR ");
			}
			return;
		case NOT_EXPR:
			Assert(list_length(bool_expr->args) == 1);
			bool need_parens = IsA(linitial(bool_expr->args), BoolExpr) && (castNode(BoolExpr, linitial(bool_expr->args))->boolop == AND_EXPR || castNode(BoolExpr, linitial(bool_expr->args))->boolop == OR_EXPR);
			appendStringInfoString(str, "NOT ");
			if (need_parens)
				appendStringInfoChar(str, '(');
			deparseExpr(str, linitial(bool_expr->args));
			if (need_parens)
				appendStringInfoChar(str, ')');
			return;
	}
}

static void deparseAStar(StringInfo str, A_Star *a_star)
{
	appendStringInfoChar(str, '*');
}

static void deparseCollateClause(StringInfo str, CollateClause* collate_clause)
{
	ListCell *lc;
	if (collate_clause->arg != NULL)
	{
		bool need_parens = IsA(collate_clause->arg, A_Expr);
		if (need_parens)
			appendStringInfoChar(str, '(');
		deparseExpr(str, collate_clause->arg);
		if (need_parens)
			appendStringInfoChar(str, ')');
		appendStringInfoChar(str, ' ');
	}
	appendStringInfoString(str, "COLLATE ");
	deparseAnyName(str, collate_clause->collname);
}

static void deparseSortBy(StringInfo str, SortBy* sort_by)
{
	deparseExpr(str, sort_by->node);
	appendStringInfoChar(str, ' ');

	switch (sort_by->sortby_dir)
	{
		case SORTBY_DEFAULT:
			break;
		case SORTBY_ASC:
			appendStringInfoString(str, "ASC ");
			break;
		case SORTBY_DESC:
			appendStringInfoString(str, "DESC ");
			break;
		case SORTBY_USING:
			appendStringInfoString(str, "USING ");
			deparseQualOp(str, sort_by->useOp);
			break;
	}

	switch (sort_by->sortby_nulls)
	{
		case SORTBY_NULLS_DEFAULT:
			break;
		case SORTBY_NULLS_FIRST:
			appendStringInfoString(str, "NULLS FIRST ");
			break;
		case SORTBY_NULLS_LAST:
			appendStringInfoString(str, "NULLS LAST ");
			break;
	}

	removeTrailingSpace(str);
}

static void deparseParamRef(StringInfo str, ParamRef* param_ref)
{
	if (param_ref->number == 0) {
		appendStringInfoChar(str, '?');
	} else {
		appendStringInfo(str, "$%d", param_ref->number);
	}
}

static void deparseSQLValueFunction(StringInfo str, SQLValueFunction* sql_value_function)
{
	switch (sql_value_function->op)
	{
		case SVFOP_CURRENT_DATE:
			appendStringInfoString(str, "current_date");
			break;
		case SVFOP_CURRENT_TIME:
			appendStringInfoString(str, "current_time");
			break;
		case SVFOP_CURRENT_TIME_N:
			appendStringInfoString(str, "current_time"); // with precision
			break;
		case SVFOP_CURRENT_TIMESTAMP:
			appendStringInfoString(str, "current_timestamp");
			break;
		case SVFOP_CURRENT_TIMESTAMP_N:
			appendStringInfoString(str, "current_timestamp"); // with precision
			break;
		case SVFOP_LOCALTIME:
			appendStringInfoString(str, "localtime");
			break;
		case SVFOP_LOCALTIME_N:
			appendStringInfoString(str, "localtime"); // with precision
			break;
		case SVFOP_LOCALTIMESTAMP:
			appendStringInfoString(str, "localtimestamp");
			break;
		case SVFOP_LOCALTIMESTAMP_N:
			appendStringInfoString(str, "localtimestamp"); // with precision
			break;
		case SVFOP_CURRENT_ROLE:
			appendStringInfoString(str, "current_role");
			break;
		case SVFOP_CURRENT_USER:
			appendStringInfoString(str, "current_user");
			break;
		case SVFOP_USER:
			appendStringInfoString(str, "user");
			break;
		case SVFOP_SESSION_USER:
			appendStringInfoString(str, "session_user");
			break;
		case SVFOP_CURRENT_CATALOG:
			appendStringInfoString(str, "current_catalog");
			break;
		case SVFOP_CURRENT_SCHEMA:
			appendStringInfoString(str, "current_schema");
			break;
	}

	if (sql_value_function->typmod != -1)
	{
		appendStringInfo(str, "(%d)", sql_value_function->typmod);
	}
}

static void deparseWithClause(StringInfo str, WithClause *with_clause)
{
	ListCell *lc;

	appendStringInfoString(str, "WITH ");
	if (with_clause->recursive)
		appendStringInfoString(str, "RECURSIVE ");
	
	foreach(lc, with_clause->ctes) {
		deparseCommonTableExpr(str, castNode(CommonTableExpr, lfirst(lc)));
		if (lnext(with_clause->ctes, lc))
			appendStringInfoString(str, ", ");
	}

	removeTrailingSpace(str);
}

static void deparseJoinExpr(StringInfo str, JoinExpr *join_expr)
{
	ListCell *lc;
	bool need_alias_parens = join_expr->alias != NULL;
	bool need_rarg_parens = IsA(join_expr->rarg, JoinExpr) && castNode(JoinExpr, join_expr->rarg)->alias == NULL;

	if (need_alias_parens)
		appendStringInfoChar(str, '(');

	deparseTableRef(str, join_expr->larg);

	appendStringInfoChar(str, ' ');

	if (join_expr->isNatural)
		appendStringInfoString(str, "NATURAL ");

	switch (join_expr->jointype)
	{
		case JOIN_INNER: /* matching tuple pairs only */
			if (!join_expr->isNatural && join_expr->quals == NULL && list_length(join_expr->usingClause) == 0)
				appendStringInfoString(str, "CROSS ");
			break;
		case JOIN_LEFT: /* pairs + unmatched LHS tuples */
			appendStringInfoString(str, "LEFT ");
			break;
		case JOIN_FULL: /* pairs + unmatched LHS + unmatched RHS */
			appendStringInfoString(str, "FULL ");
			break;
		case JOIN_RIGHT: /* pairs + unmatched RHS tuples */
			appendStringInfoString(str, "RIGHT ");
			break;
		case JOIN_SEMI:
		case JOIN_ANTI:
		case JOIN_UNIQUE_OUTER:
		case JOIN_UNIQUE_INNER:
			// Only used by the planner/executor, not seen in parser output
			Assert(false);
			break;
	}
	
	appendStringInfoString(str, "JOIN ");

	if (need_rarg_parens)
		appendStringInfoChar(str, '(');
	deparseTableRef(str, join_expr->rarg);
	if (need_rarg_parens)
		appendStringInfoChar(str, ')');
	appendStringInfoChar(str, ' ');

	if (join_expr->quals != NULL)
	{
		appendStringInfoString(str, "ON ");
		deparseExpr(str, join_expr->quals);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(join_expr->usingClause) > 0)
	{
		appendStringInfoString(str, "USING (");
		deparseNameList(str, join_expr->usingClause);
		appendStringInfoString(str, ") ");

		if (join_expr->join_using_alias)
		{
			appendStringInfoString(str, "AS ");
			appendStringInfoString(str, join_expr->join_using_alias->aliasname);
		}
	}

	if (need_alias_parens)
		appendStringInfoString(str, ") ");

	if (join_expr->alias != NULL)
		deparseAlias(str, join_expr->alias);

	removeTrailingSpace(str);
}

static void deparseCTESearchClause(StringInfo str, CTESearchClause *search_clause)
{
	appendStringInfoString(str, " SEARCH ");
	if (search_clause->search_breadth_first)
		appendStringInfoString(str, "BREADTH ");
	else
		appendStringInfoString(str, "DEPTH ");

	appendStringInfoString(str, "FIRST BY ");

	if (search_clause->search_col_list)
		deparseColumnList(str, search_clause->search_col_list);

	appendStringInfoString(str, " SET ");
	appendStringInfoString(str, quote_identifier(search_clause->search_seq_column));
}

static void deparseCTECycleClause(StringInfo str, CTECycleClause *cycle_clause)
{
	appendStringInfoString(str, " CYCLE ");

	if (cycle_clause->cycle_col_list)
		deparseColumnList(str, cycle_clause->cycle_col_list);

	appendStringInfoString(str, " SET ");
	appendStringInfoString(str, quote_identifier(cycle_clause->cycle_mark_column));

	if (cycle_clause->cycle_mark_value)
	{
		appendStringInfoString(str, " TO ");
		deparseExpr(str, cycle_clause->cycle_mark_value);
	}
	
	if (cycle_clause->cycle_mark_default)
	{
		appendStringInfoString(str, " DEFAULT ");
		deparseExpr(str, cycle_clause->cycle_mark_default);
	}
	
	appendStringInfoString(str, " USING ");
	appendStringInfoString(str, quote_identifier(cycle_clause->cycle_path_column));
}

static void deparseCommonTableExpr(StringInfo str, CommonTableExpr *cte)
{
	deparseColId(str, cte->ctename);

	if (list_length(cte->aliascolnames) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseNameList(str, cte->aliascolnames);
		appendStringInfoChar(str, ')');
	}
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "AS ");
	switch (cte->ctematerialized) {
		case CTEMaterializeDefault: /* no option specified */
			break;
		case CTEMaterializeAlways:
			appendStringInfoString(str, "MATERIALIZED ");
			break;
		case CTEMaterializeNever:
			appendStringInfoString(str, "NOT MATERIALIZED ");
			break;
	}

	appendStringInfoChar(str, '(');
	deparsePreparableStmt(str, cte->ctequery);
	appendStringInfoChar(str, ')');

	if (cte->search_clause)
		deparseCTESearchClause(str, cte->search_clause);
	if (cte->cycle_clause)
		deparseCTECycleClause(str, cte->cycle_clause);
}

static void deparseRangeSubselect(StringInfo str, RangeSubselect *range_subselect)
{
	if (range_subselect->lateral)
		appendStringInfoString(str, "LATERAL ");

	appendStringInfoChar(str, '(');
	deparseSelectStmt(str, castNode(SelectStmt, range_subselect->subquery));
	appendStringInfoChar(str, ')');

	if (range_subselect->alias != NULL)
	{
		appendStringInfoChar(str, ' ');
		deparseAlias(str, range_subselect->alias);
	}
}

static void deparseRangeFunction(StringInfo str, RangeFunction *range_func)
{
	ListCell *lc;
	ListCell *lc2;

	if (range_func->lateral)
		appendStringInfoString(str, "LATERAL ");

	if (range_func->is_rowsfrom)
	{
		appendStringInfoString(str, "ROWS FROM ");
		appendStringInfoChar(str, '(');
		foreach(lc, range_func->functions)
		{
			List *lfunc = castNode(List, lfirst(lc));
			Assert(list_length(lfunc) == 2);
			deparseFuncExprWindowless(str, linitial(lfunc));
			appendStringInfoChar(str, ' ');
			List *coldeflist = castNode(List, lsecond(lfunc));
			if (list_length(coldeflist) > 0)
			{
				appendStringInfoString(str, "AS (");
				foreach(lc2, coldeflist)
				{
					deparseColumnDef(str, castNode(ColumnDef, lfirst(lc2)));
					if (lnext(coldeflist, lc2))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoChar(str, ')');
			}
			if (lnext(range_func->functions, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ')');
	}
	else
	{
		Assert(list_length(linitial(range_func->functions)) == 2);
		deparseFuncExprWindowless(str, linitial(linitial(range_func->functions)));
	}
	appendStringInfoChar(str, ' ');

	if (range_func->ordinality)
		appendStringInfoString(str, "WITH ORDINALITY ");

	if (range_func->alias != NULL)
	{
		deparseAlias(str, range_func->alias);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(range_func->coldeflist) > 0)
	{
		if (range_func->alias == NULL)
			appendStringInfoString(str, "AS ");
		appendStringInfoChar(str, '(');
		foreach(lc, range_func->coldeflist)
		{
			deparseColumnDef(str, castNode(ColumnDef, lfirst(lc)));
			if (lnext(range_func->coldeflist, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ')');
	}

	removeTrailingSpace(str);
}

static void deparseAArrayExpr(StringInfo str, A_ArrayExpr *array_expr)
{
	ListCell *lc;

	appendStringInfoString(str, "ARRAY[");
	deparseExprList(str, array_expr->elements);
	appendStringInfoChar(str, ']');
}

static void deparseRowExpr(StringInfo str, RowExpr *row_expr)
{
	ListCell *lc;

	switch (row_expr->row_format)
	{
		case COERCE_EXPLICIT_CALL:
			appendStringInfoString(str, "ROW");
			break;
		case COERCE_SQL_SYNTAX:
		case COERCE_EXPLICIT_CAST:
			// Not present in raw parser output
			Assert(false);
			break;
		case COERCE_IMPLICIT_CAST:
			// No prefix
			break;
	}

	appendStringInfoString(str, "(");
	deparseExprList(str, row_expr->args);
	appendStringInfoChar(str, ')');
}

static void deparseTypeCast(StringInfo str, TypeCast *type_cast, DeparseNodeContext context)
{
	bool need_parens = false;

	Assert(type_cast->typeName != NULL);

	if (IsA(type_cast->arg, A_Expr))
	{
		appendStringInfoString(str, "CAST(");
		deparseExpr(str, type_cast->arg);
		appendStringInfoString(str, " AS ");
		deparseTypeName(str, type_cast->typeName);
		appendStringInfoChar(str, ')');
		return;
	}

	if (IsA(type_cast->arg, A_Const))
	{
		A_Const *a_const = castNode(A_Const, type_cast->arg);

		if (list_length(type_cast->typeName->names) == 2 &&
			strcmp(strVal(linitial(type_cast->typeName->names)), "pg_catalog") == 0)
		{
			char *typename = strVal(lsecond(type_cast->typeName->names));
			if (strcmp(typename, "bpchar") == 0 && type_cast->typeName->typmods == NULL)
			{
				appendStringInfoString(str, "char ");
				deparseAConst(str, a_const);
				return;
			}
			else if (strcmp(typename, "bool") == 0 && IsA(&a_const->val, String))
			{
				/*
				* Handle "bool" or "false" in the statement, which is represented as a typecast
				* (other boolean casts should be represented as a cast, i.e. don't need special handling)
				*/
				char *const_val = strVal(&a_const->val);
				if (strcmp(const_val, "t") == 0)
				{
					appendStringInfoString(str, "true");
					return;
				}
				if (strcmp(const_val, "f") == 0)
				{
					appendStringInfoString(str, "false");
					return;
				}
			}
			else if (strcmp(typename, "interval") == 0 && context == DEPARSE_NODE_CONTEXT_SET_STATEMENT && IsA(&a_const->val, String))
			{
				appendStringInfoString(str, "interval ");
				deparseAConst(str, a_const);
				deparseIntervalTypmods(str, type_cast->typeName);
				return;
			}
		}

		// Ensure negative values have wrapping parentheses
		if (IsA(&a_const->val, Float) || (IsA(&a_const->val, Integer) && intVal(&a_const->val) < 0))
		{
			need_parens = true;
		}

		if (list_length(type_cast->typeName->names) == 1 &&
			strcmp(strVal(linitial(type_cast->typeName->names)), "point") == 0 &&
			a_const->location > type_cast->typeName->location)
		{
			appendStringInfoString(str, " point ");
			deparseAConst(str, a_const);
			return;
		}
	}


	if (need_parens)
		appendStringInfoChar(str, '(');
	deparseExpr(str, type_cast->arg);
	if (need_parens)
		appendStringInfoChar(str, ')');

	appendStringInfoString(str, "::");
	deparseTypeName(str, type_cast->typeName);
}

static void deparseTypeName(StringInfo str, TypeName *type_name)
{
	ListCell *lc;
	bool skip_typmods = false;

	if (type_name->setof)
		appendStringInfoString(str, "SETOF ");

	if (list_length(type_name->names) == 2 && strcmp(strVal(linitial(type_name->names)), "pg_catalog") == 0)
	{
		const char *name = strVal(lsecond(type_name->names));
		if (strcmp(name, "bpchar") == 0)
		{
			appendStringInfoString(str, "char");
		}
		else if (strcmp(name, "varchar") == 0)
		{
			appendStringInfoString(str, "varchar");
		}
		else if (strcmp(name, "numeric") == 0)
		{
			appendStringInfoString(str, "numeric");
		}
		else if (strcmp(name, "bool") == 0)
		{
			appendStringInfoString(str, "boolean");
		}
		else if (strcmp(name, "int2") == 0)
		{
			appendStringInfoString(str, "smallint");
		}
		else if (strcmp(name, "int4") == 0)
		{
			appendStringInfoString(str, "int");
		}
		else if (strcmp(name, "int8") == 0)
		{
			appendStringInfoString(str, "bigint");
		}
		else if (strcmp(name, "real") == 0 || strcmp(name, "float4") == 0)
		{
			appendStringInfoString(str, "real");
		}
		else if (strcmp(name, "float8") == 0)
		{
			appendStringInfoString(str, "double precision");
		}
		else if (strcmp(name, "time") == 0)
		{
			appendStringInfoString(str, "time");
		}
		else if (strcmp(name, "timetz") == 0)
		{
			appendStringInfoString(str, "time ");
			if (list_length(type_name->typmods) > 0)
			{
				appendStringInfoChar(str, '(');
				foreach(lc, type_name->typmods)
				{
					deparseSignedIconst(str, (Node *) &castNode(A_Const, lfirst(lc))->val);
					if (lnext(type_name->typmods, lc))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoString(str, ") ");
			}
			appendStringInfoString(str, "with time zone");
			skip_typmods = true;
		}
		else if (strcmp(name, "timestamp") == 0)
		{
			appendStringInfoString(str, "timestamp");
		}
		else if (strcmp(name, "timestamptz") == 0)
		{
			appendStringInfoString(str, "timestamp ");
			if (list_length(type_name->typmods) > 0)
			{
				appendStringInfoChar(str, '(');
				foreach(lc, type_name->typmods)
				{
					deparseSignedIconst(str, (Node *) &castNode(A_Const, lfirst(lc))->val);
					if (lnext(type_name->typmods, lc))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoString(str, ") ");
			}
			appendStringInfoString(str, "with time zone");
			skip_typmods = true;
		}
		else if (strcmp(name, "interval") == 0 && list_length(type_name->typmods) == 0)
		{
			appendStringInfoString(str, "interval");
		}
		else if (strcmp(name, "interval") == 0 && list_length(type_name->typmods) >= 1)
		{
			appendStringInfoString(str, "interval");
			deparseIntervalTypmods(str, type_name);

			skip_typmods = true;
		}
		else
		{
			appendStringInfoString(str, "pg_catalog.");
			appendStringInfoString(str, name);
		}
	}
	else
	{
		deparseAnyName(str, type_name->names);
	}

	if (list_length(type_name->typmods) > 0 && !skip_typmods)
	{
		appendStringInfoChar(str, '(');
		foreach(lc, type_name->typmods)
		{
			if (IsA(lfirst(lc), A_Const))
				deparseAConst(str, lfirst(lc));
			else if (IsA(lfirst(lc), ParamRef))
				deparseParamRef(str, lfirst(lc));
			else if (IsA(lfirst(lc), ColumnRef))
				deparseColumnRef(str, lfirst(lc));
			else
				Assert(false);

			if (lnext(type_name->typmods, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ')');
	}

	foreach(lc, type_name->arrayBounds)
	{
		appendStringInfoChar(str, '[');
		if (IsA(lfirst(lc), Integer) && intVal(lfirst(lc)) != -1)
			deparseSignedIconst(str, lfirst(lc));
		appendStringInfoChar(str, ']');
	}

	if (type_name->pct_type)
		appendStringInfoString(str, "%type");
}

// Handle typemods for Interval types separately
// so that they can be applied appropriately for different contexts.
// For example, when using `SET` a query like `INTERVAL 'x' hour TO minute`
// the `INTERVAL` keyword is specified first.
// In all other contexts, intervals use the `'x'::interval` style.
static void deparseIntervalTypmods(StringInfo str, TypeName *type_name)
{
	const char *name = strVal(lsecond(type_name->names));
	Assert(strcmp(name, "interval") == 0);
	Assert(list_length(type_name->typmods) >= 1);
	Assert(IsA(linitial(type_name->typmods), A_Const));
	Assert(IsA(&castNode(A_Const, linitial(type_name->typmods))->val, Integer));

	int fields = intVal(&castNode(A_Const, linitial(type_name->typmods))->val);

	// This logic is based on intervaltypmodout in timestamp.c
	switch (fields)
	{
		case INTERVAL_MASK(YEAR):
			appendStringInfoString(str, " year");
			break;
		case INTERVAL_MASK(MONTH):
			appendStringInfoString(str, " month");
			break;
		case INTERVAL_MASK(DAY):
			appendStringInfoString(str, " day");
			break;
		case INTERVAL_MASK(HOUR):
			appendStringInfoString(str, " hour");
			break;
		case INTERVAL_MASK(MINUTE):
			appendStringInfoString(str, " minute");
			break;
		case INTERVAL_MASK(SECOND):
			appendStringInfoString(str, " second");
			break;
		case INTERVAL_MASK(YEAR) | INTERVAL_MASK(MONTH):
			appendStringInfoString(str, " year to month");
			break;
		case INTERVAL_MASK(DAY) | INTERVAL_MASK(HOUR):
			appendStringInfoString(str, " day to hour");
			break;
		case INTERVAL_MASK(DAY) | INTERVAL_MASK(HOUR) | INTERVAL_MASK(MINUTE):
			appendStringInfoString(str, " day to minute");
			break;
		case INTERVAL_MASK(DAY) | INTERVAL_MASK(HOUR) | INTERVAL_MASK(MINUTE) | INTERVAL_MASK(SECOND):
			appendStringInfoString(str, " day to second");
			break;
		case INTERVAL_MASK(HOUR) | INTERVAL_MASK(MINUTE):
			appendStringInfoString(str, " hour to minute");
			break;
		case INTERVAL_MASK(HOUR) | INTERVAL_MASK(MINUTE) | INTERVAL_MASK(SECOND):
			appendStringInfoString(str, " hour to second");
			break;
		case INTERVAL_MASK(MINUTE) | INTERVAL_MASK(SECOND):
			appendStringInfoString(str, " minute to second");
			break;
		case INTERVAL_FULL_RANGE:
			// Nothing
			break;
		default:
			Assert(false);
			break;
	}

	if (list_length(type_name->typmods) == 2)
	{
		int precision = intVal(&castNode(A_Const, lsecond(type_name->typmods))->val);
		if (precision != INTERVAL_FULL_PRECISION)
			appendStringInfo(str, "(%d)", precision);
	}
}

static void deparseNullTest(StringInfo str, NullTest *null_test)
{
	// argisrow is always false in raw parser output
	Assert(null_test->argisrow == false);

	deparseExpr(str, (Node *) null_test->arg);
	switch (null_test->nulltesttype)
	{
		case IS_NULL:
			appendStringInfoString(str, " IS NULL");
			break;
		case IS_NOT_NULL:
			appendStringInfoString(str, " IS NOT NULL");
			break;
	}
}

static void deparseCaseExpr(StringInfo str, CaseExpr *case_expr)
{
	ListCell *lc;

	appendStringInfoString(str, "CASE ");

	if (case_expr->arg != NULL)
	{
		deparseExpr(str, (Node *) case_expr->arg);
		appendStringInfoChar(str, ' ');
	}

	foreach(lc, case_expr->args)
	{
		deparseCaseWhen(str, castNode(CaseWhen, lfirst(lc)));
		appendStringInfoChar(str, ' ');
	}

	if (case_expr->defresult != NULL)
	{
		appendStringInfoString(str, "ELSE ");
		deparseExpr(str, (Node *) case_expr->defresult);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "END");
}

static void deparseCaseWhen(StringInfo str, CaseWhen *case_when)
{
	appendStringInfoString(str, "WHEN ");
	deparseExpr(str, (Node *) case_when->expr);
	appendStringInfoString(str, " THEN ");
	deparseExpr(str, (Node *) case_when->result);
}

static void deparseAIndirection(StringInfo str, A_Indirection *a_indirection)
{
	ListCell *lc;
	bool need_parens =
		IsA(a_indirection->arg, A_Indirection) ||
		IsA(a_indirection->arg, FuncCall) ||
		IsA(a_indirection->arg, A_Expr) ||
		IsA(a_indirection->arg, TypeCast) ||
		IsA(a_indirection->arg, RowExpr) ||
		(IsA(a_indirection->arg, ColumnRef) && !IsA(linitial(a_indirection->indirection), A_Indices));

	if (need_parens)
		appendStringInfoChar(str, '(');

	deparseExpr(str, a_indirection->arg);

	if (need_parens)
		appendStringInfoChar(str, ')');

	deparseOptIndirection(str, a_indirection->indirection, 0);
}

static void deparseAIndices(StringInfo str, A_Indices *a_indices)
{
	appendStringInfoChar(str, '[');
	if (a_indices->lidx != NULL)
		deparseExpr(str, a_indices->lidx);
	if (a_indices->is_slice)
		appendStringInfoChar(str, ':');
	if (a_indices->uidx != NULL)
		deparseExpr(str, a_indices->uidx);
	appendStringInfoChar(str, ']');
}

static void deparseCoalesceExpr(StringInfo str, CoalesceExpr *coalesce_expr)
{
	appendStringInfoString(str, "COALESCE(");
	deparseExprList(str, coalesce_expr->args);
	appendStringInfoChar(str, ')');
}

static void deparseMinMaxExpr(StringInfo str, MinMaxExpr *min_max_expr)
{
	switch (min_max_expr->op)
	{
		case IS_GREATEST:
			appendStringInfoString(str, "GREATEST(");
			break;
		case IS_LEAST:
			appendStringInfoString(str, "LEAST(");
			break;
	}
	deparseExprList(str, min_max_expr->args);
	appendStringInfoChar(str, ')');
}

static void deparseBooleanTest(StringInfo str, BooleanTest *boolean_test)
{
	deparseExpr(str, (Node *) boolean_test->arg);
	switch (boolean_test->booltesttype)
	{
		case IS_TRUE:
			appendStringInfoString(str, " IS TRUE");
			break;
		case IS_NOT_TRUE:
			appendStringInfoString(str, " IS NOT TRUE");
			break;
		case IS_FALSE:
			appendStringInfoString(str, " IS FALSE");
			break;
		case IS_NOT_FALSE:
			appendStringInfoString(str, " IS NOT FALSE");
			break;
		case IS_UNKNOWN:
			appendStringInfoString(str, " IS UNKNOWN");
			break;
		case IS_NOT_UNKNOWN:
			appendStringInfoString(str, " IS NOT UNKNOWN");
			break;
		default:
			Assert(false);
	}
}

static void deparseColumnDef(StringInfo str, ColumnDef *column_def)
{
	ListCell *lc;

	if (column_def->colname != NULL)
	{
		appendStringInfoString(str, quote_identifier(column_def->colname));
		appendStringInfoChar(str, ' ');
	}

	if (column_def->typeName != NULL)
	{
		deparseTypeName(str, column_def->typeName);
		appendStringInfoChar(str, ' ');
	}

	if (column_def->raw_default != NULL)
	{
		appendStringInfoString(str, "USING ");
		deparseExpr(str, column_def->raw_default);
		appendStringInfoChar(str, ' ');
	}

	if (column_def->fdwoptions != NULL)
	{
		deparseCreateGenericOptions(str, column_def->fdwoptions);
		appendStringInfoChar(str, ' ');
	}

	foreach(lc, column_def->constraints)
	{
		deparseConstraint(str, castNode(Constraint, lfirst(lc)));
		appendStringInfoChar(str, ' ');
	}

	if (column_def->collClause != NULL)
	{
		deparseCollateClause(str, column_def->collClause);
	}

	removeTrailingSpace(str);
}

static void deparseInsertOverride(StringInfo str, OverridingKind override)
{
	switch (override)
	{
		case OVERRIDING_NOT_SET:
			// Do nothing
			break;
		case OVERRIDING_USER_VALUE:
			appendStringInfoString(str, "OVERRIDING USER VALUE ");
			break;
		case OVERRIDING_SYSTEM_VALUE:
			appendStringInfoString(str, "OVERRIDING SYSTEM VALUE ");
			break;
	}
}

static void deparseInsertStmt(StringInfo str, InsertStmt *insert_stmt)
{
	ListCell *lc;
	ListCell *lc2;

	if (insert_stmt->withClause != NULL)
	{
		deparseWithClause(str, insert_stmt->withClause);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "INSERT INTO ");
	deparseRangeVar(str, insert_stmt->relation, DEPARSE_NODE_CONTEXT_INSERT_RELATION);
	appendStringInfoChar(str, ' ');

	if (list_length(insert_stmt->cols) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseInsertColumnList(str, insert_stmt->cols);
		appendStringInfoString(str, ") ");
	}

	deparseInsertOverride(str, insert_stmt->override);

	if (insert_stmt->selectStmt != NULL)
	{
		deparseSelectStmt(str, castNode(SelectStmt, insert_stmt->selectStmt));
		appendStringInfoChar(str, ' ');
	}
	else
	{
		appendStringInfoString(str, "DEFAULT VALUES ");
	}

	if (insert_stmt->onConflictClause != NULL)
	{
		deparseOnConflictClause(str, insert_stmt->onConflictClause);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(insert_stmt->returningList) > 0)
	{
		appendStringInfoString(str, "RETURNING ");
		deparseTargetList(str, insert_stmt->returningList);
	}

	removeTrailingSpace(str);
}

static void deparseInferClause(StringInfo str, InferClause *infer_clause)
{
	ListCell *lc;

	if (list_length(infer_clause->indexElems) > 0)
	{
		appendStringInfoChar(str, '(');
		foreach(lc, infer_clause->indexElems)
		{
			deparseIndexElem(str, lfirst(lc));
			if (lnext(infer_clause->indexElems, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoString(str, ") ");
	}

	if (infer_clause->conname != NULL)
	{
		appendStringInfoString(str, "ON CONSTRAINT ");
		appendStringInfoString(str, quote_identifier(infer_clause->conname));
		appendStringInfoChar(str, ' ');
	}

	deparseWhereClause(str, infer_clause->whereClause);

	removeTrailingSpace(str);
}

static void deparseOnConflictClause(StringInfo str, OnConflictClause *on_conflict_clause)
{
	ListCell *lc;

	appendStringInfoString(str, "ON CONFLICT ");

	if (on_conflict_clause->infer != NULL)
	{
		deparseInferClause(str, on_conflict_clause->infer);
		appendStringInfoChar(str, ' ');
	}

	switch (on_conflict_clause->action)
	{
		case ONCONFLICT_NONE:
			Assert(false);
			break;
		case ONCONFLICT_NOTHING:
			appendStringInfoString(str, "DO NOTHING ");
			break;
		case ONCONFLICT_UPDATE:
			appendStringInfoString(str, "DO UPDATE ");
			break;
	}

	if (list_length(on_conflict_clause->targetList) > 0)
	{
		appendStringInfoString(str, "SET ");
		deparseSetClauseList(str, on_conflict_clause->targetList);
		appendStringInfoChar(str, ' ');
	}

	deparseWhereClause(str, on_conflict_clause->whereClause);

	removeTrailingSpace(str);
}

static void deparseUpdateStmt(StringInfo str, UpdateStmt *update_stmt)
{
	ListCell* lc;
	ListCell* lc2;
	ListCell* lc3;

	if (update_stmt->withClause != NULL)
	{
		deparseWithClause(str, update_stmt->withClause);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "UPDATE ");
	deparseRangeVar(str, update_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (list_length(update_stmt->targetList) > 0)
	{
		appendStringInfoString(str, "SET ");
		deparseSetClauseList(str, update_stmt->targetList);
		appendStringInfoChar(str, ' ');
	}

	deparseFromClause(str, update_stmt->fromClause);
	deparseWhereClause(str, update_stmt->whereClause);

	if (list_length(update_stmt->returningList) > 0)
	{
		appendStringInfoString(str, "RETURNING ");
		deparseTargetList(str, update_stmt->returningList);
	}

	removeTrailingSpace(str);
}

static void deparseMergeStmt(StringInfo str, MergeStmt *merge_stmt)
{
	if (merge_stmt->withClause != NULL)
	{
		deparseWithClause(str, merge_stmt->withClause);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "MERGE INTO ");
	deparseRangeVar(str, merge_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "USING ");
	deparseTableRef(str, merge_stmt->sourceRelation);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "ON ");
	deparseExpr(str, merge_stmt->joinCondition);
	appendStringInfoChar(str, ' ');

	ListCell *lc, *lc2;
	foreach (lc, merge_stmt->mergeWhenClauses)
	{
		MergeWhenClause *clause = castNode(MergeWhenClause, lfirst(lc));

		appendStringInfoString(str, "WHEN ");

		if (!clause->matched)
		{
			appendStringInfoString(str, "NOT ");
		}

		appendStringInfoString(str, "MATCHED ");

		if (clause->condition)
		{
			appendStringInfoString(str, "AND ");
			deparseExpr(str, clause->condition);
			appendStringInfoChar(str, ' ');
		}

		appendStringInfoString(str, "THEN ");

		switch (clause->commandType) {
			case CMD_INSERT:
				appendStringInfoString(str, "INSERT ");

				if (clause->targetList) {
					appendStringInfoChar(str, '(');
					deparseInsertColumnList(str, clause->targetList);
					appendStringInfoString(str, ") ");
				}

				deparseInsertOverride(str, clause->override);

				if (clause->values) {
					appendStringInfoString(str, "VALUES (");
					deparseExprList(str, clause->values);
					appendStringInfoString(str, ")");
				} else {
					appendStringInfoString(str, "DEFAULT VALUES ");
				}

				break;
			case CMD_UPDATE:
				appendStringInfoString(str, "UPDATE SET ");
				deparseSetClauseList(str, clause->targetList);
				break;
			case CMD_DELETE:
				appendStringInfoString(str, "DELETE");
				break;
			case CMD_NOTHING:
				appendStringInfoString(str, "DO NOTHING");
				break;
			default:
				elog(ERROR, "deparse: unpermitted command type in merge statement: %d", clause->commandType);
				break;
		}

		if (lfirst(lc) != llast(merge_stmt->mergeWhenClauses))
			appendStringInfoChar(str, ' ');
	}
}

static void deparseDeleteStmt(StringInfo str, DeleteStmt *delete_stmt)
{
	if (delete_stmt->withClause != NULL)
	{
		deparseWithClause(str, delete_stmt->withClause);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "DELETE FROM ");
	deparseRangeVar(str, delete_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (delete_stmt->usingClause != NULL)
	{
		appendStringInfoString(str, "USING ");
		deparseFromList(str, delete_stmt->usingClause);
		appendStringInfoChar(str, ' ');
	}

	deparseWhereClause(str, delete_stmt->whereClause);

	if (list_length(delete_stmt->returningList) > 0)
	{
		appendStringInfoString(str, "RETURNING ");
		deparseTargetList(str, delete_stmt->returningList);
	}

	removeTrailingSpace(str);
}

static void deparseLockingClause(StringInfo str, LockingClause *locking_clause)
{
	ListCell *lc;

	switch (locking_clause->strength)
	{
		case LCS_NONE:
			/* no such clause - only used in PlanRowMark */
			Assert(false);
			break;
		case LCS_FORKEYSHARE:
			appendStringInfoString(str, "FOR KEY SHARE ");
			break;
		case LCS_FORSHARE:
			appendStringInfoString(str, "FOR SHARE ");
			break;
		case LCS_FORNOKEYUPDATE:
			appendStringInfoString(str, "FOR NO KEY UPDATE ");
			break;
		case LCS_FORUPDATE:
			appendStringInfoString(str, "FOR UPDATE ");
			break;
	}

	if (list_length(locking_clause->lockedRels) > 0)
	{
		appendStringInfoString(str, "OF ");
		deparseQualifiedNameList(str, locking_clause->lockedRels);
	}

	switch (locking_clause->waitPolicy)
	{
		case LockWaitError:
			appendStringInfoString(str, "NOWAIT");
			break;
		case LockWaitSkip:
			appendStringInfoString(str, "SKIP LOCKED");
			break;
		case LockWaitBlock:
			// Default
			break;
	}

	removeTrailingSpace(str);
}

static void deparseSetToDefault(StringInfo str, SetToDefault *set_to_default)
{
	appendStringInfoString(str, "DEFAULT");
}

static void deparseCreateCastStmt(StringInfo str, CreateCastStmt *create_cast_stmt)
{
	ListCell *lc;
	ListCell *lc2;

	appendStringInfoString(str, "CREATE CAST (");
	deparseTypeName(str, create_cast_stmt->sourcetype);
	appendStringInfoString(str, " AS ");
	deparseTypeName(str, create_cast_stmt->targettype);
	appendStringInfoString(str, ") ");

	if (create_cast_stmt->func != NULL)
	{
		appendStringInfoString(str, "WITH FUNCTION ");
		deparseFunctionWithArgtypes(str, create_cast_stmt->func);
		appendStringInfoChar(str, ' ');
	}
	else if (create_cast_stmt->inout)
	{
		appendStringInfoString(str, "WITH INOUT ");
	}
	else
	{
		appendStringInfoString(str, "WITHOUT FUNCTION ");
	}

	switch (create_cast_stmt->context)
	{
		case COERCION_IMPLICIT:
			appendStringInfoString(str, "AS IMPLICIT");
			break;
		case COERCION_ASSIGNMENT:
			appendStringInfoString(str, "AS ASSIGNMENT");
			break;
		case COERCION_PLPGSQL:
			// Not present in raw parser output
			Assert(false);
			break;
		case COERCION_EXPLICIT:
			// Default
			break;
	}
}

static void deparseCreateOpClassStmt(StringInfo str, CreateOpClassStmt *create_op_class_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "CREATE OPERATOR CLASS ");

	deparseAnyName(str, create_op_class_stmt->opclassname);
	appendStringInfoChar(str, ' ');

	if (create_op_class_stmt->isDefault)
		appendStringInfoString(str, "DEFAULT ");

	appendStringInfoString(str, "FOR TYPE ");
	deparseTypeName(str, create_op_class_stmt->datatype);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "USING ");
	appendStringInfoString(str, quote_identifier(create_op_class_stmt->amname));
	appendStringInfoChar(str, ' ');

	if (create_op_class_stmt->opfamilyname != NULL)
	{
		appendStringInfoString(str, "FAMILY ");
		deparseAnyName(str, create_op_class_stmt->opfamilyname);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "AS ");
	deparseOpclassItemList(str, create_op_class_stmt->items);
}

static void deparseCreateOpFamilyStmt(StringInfo str, CreateOpFamilyStmt *create_op_family_stmt)
{
	appendStringInfoString(str, "CREATE OPERATOR FAMILY ");

	deparseAnyName(str, create_op_family_stmt->opfamilyname);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "USING ");
	appendStringInfoString(str, quote_identifier(create_op_family_stmt->amname));
}

static void deparseCreateOpClassItem(StringInfo str, CreateOpClassItem *create_op_class_item)
{
	ListCell *lc = NULL;

	switch (create_op_class_item->itemtype)
	{
		case OPCLASS_ITEM_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			appendStringInfo(str, "%d ", create_op_class_item->number);

			if (create_op_class_item->name != NULL)
			{
				if (create_op_class_item->name->objargs != NULL)
					deparseOperatorWithArgtypes(str, create_op_class_item->name);
				else
					deparseAnyOperator(str, create_op_class_item->name->objname);
				appendStringInfoChar(str, ' ');
			}

			if (create_op_class_item->order_family != NULL)
			{
				appendStringInfoString(str, "FOR ORDER BY ");
				deparseAnyName(str, create_op_class_item->order_family);
			}

			if (create_op_class_item->class_args != NULL)
			{
				appendStringInfoChar(str, '(');
				deparseTypeList(str, create_op_class_item->class_args);
				appendStringInfoChar(str, ')');
			}
			removeTrailingSpace(str);
			break;
		case OPCLASS_ITEM_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			appendStringInfo(str, "%d ", create_op_class_item->number);
			if (create_op_class_item->class_args != NULL)
			{
				appendStringInfoChar(str, '(');
				deparseTypeList(str, create_op_class_item->class_args);
				appendStringInfoString(str, ") ");
			}
			if (create_op_class_item->name != NULL)
				deparseFunctionWithArgtypes(str, create_op_class_item->name);
			removeTrailingSpace(str);
			break;
		case OPCLASS_ITEM_STORAGETYPE:
			appendStringInfoString(str, "STORAGE ");
			deparseTypeName(str, create_op_class_item->storedtype);
			break;
		default:
			Assert(false);
	}
}

static void deparseTableLikeClause(StringInfo str, TableLikeClause *table_like_clause)
{
	appendStringInfoString(str, "LIKE ");
	deparseRangeVar(str, table_like_clause->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (table_like_clause->options == CREATE_TABLE_LIKE_ALL)
		appendStringInfoString(str, "INCLUDING ALL ");
	else
	{
		if (table_like_clause->options & CREATE_TABLE_LIKE_COMMENTS)
			appendStringInfoString(str, "INCLUDING COMMENTS ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_CONSTRAINTS)
			appendStringInfoString(str, "INCLUDING CONSTRAINTS ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_DEFAULTS)
			appendStringInfoString(str, "INCLUDING DEFAULTS ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_IDENTITY)
			appendStringInfoString(str, "INCLUDING IDENTITY ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_GENERATED)
			appendStringInfoString(str, "INCLUDING GENERATED ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_INDEXES)
			appendStringInfoString(str, "INCLUDING INDEXES ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_STATISTICS)
			appendStringInfoString(str, "INCLUDING STATISTICS ");
		if (table_like_clause->options & CREATE_TABLE_LIKE_STORAGE)
			appendStringInfoString(str, "INCLUDING STORAGE ");
	}
	removeTrailingSpace(str);
}

static void deparseCreateDomainStmt(StringInfo str, CreateDomainStmt *create_domain_stmt)
{
	ListCell *lc;

	Assert(create_domain_stmt->typeName != NULL);

	appendStringInfoString(str, "CREATE DOMAIN ");
	deparseAnyName(str, create_domain_stmt->domainname);
	appendStringInfoString(str, " AS ");

	deparseTypeName(str, create_domain_stmt->typeName);
	appendStringInfoChar(str, ' ');

	if (create_domain_stmt->collClause != NULL)
	{
		deparseCollateClause(str, create_domain_stmt->collClause);
		appendStringInfoChar(str, ' ');
	}

	foreach(lc, create_domain_stmt->constraints)
	{
		deparseConstraint(str, castNode(Constraint, lfirst(lc)));
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseCreateExtensionStmt(StringInfo str, CreateExtensionStmt *create_extension_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "CREATE EXTENSION ");

	if (create_extension_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	deparseColId(str, create_extension_stmt->extname);
	appendStringInfoChar(str, ' ');

	foreach (lc, create_extension_stmt->options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));

		if (strcmp(def_elem->defname, "schema") == 0)
		{
			appendStringInfoString(str, "SCHEMA ");
			deparseColId(str, strVal(def_elem->arg));
		}
		else if (strcmp(def_elem->defname, "new_version") == 0)
		{
			appendStringInfoString(str, "VERSION ");
			deparseNonReservedWordOrSconst(str, strVal(def_elem->arg));
		}
		else if (strcmp(def_elem->defname, "cascade") == 0)
		{
			appendStringInfoString(str, "CASCADE");
		}
		else
		{
			Assert(false);
		}

		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseConstraint(StringInfo str, Constraint *constraint)
{
	ListCell *lc;

	if (constraint->conname != NULL)
	{
		appendStringInfoString(str, "CONSTRAINT ");
		appendStringInfoString(str, quote_identifier(constraint->conname));
		appendStringInfoChar(str, ' ');
	}

	switch (constraint->contype) {
		case CONSTR_NULL:
			appendStringInfoString(str, "NULL ");
			break;
		case CONSTR_NOTNULL:
			appendStringInfoString(str, "NOT NULL ");
			break;
		case CONSTR_DEFAULT:
			appendStringInfoString(str, "DEFAULT ");
			deparseExpr(str, constraint->raw_expr);
			break;
		case CONSTR_IDENTITY:
			appendStringInfoString(str, "GENERATED ");
			switch (constraint->generated_when)
			{
				case ATTRIBUTE_IDENTITY_ALWAYS:
					appendStringInfoString(str, "ALWAYS ");
					break;
				case ATTRIBUTE_IDENTITY_BY_DEFAULT:
					appendStringInfoString(str, "BY DEFAULT ");
					break;
				default:
					Assert(false);
			}
			appendStringInfoString(str, "AS IDENTITY ");
			deparseOptParenthesizedSeqOptList(str, constraint->options);
			break;
		case CONSTR_GENERATED:
			Assert(constraint->generated_when == ATTRIBUTE_IDENTITY_ALWAYS);
			appendStringInfoString(str, "GENERATED ALWAYS AS (");
			deparseExpr(str, constraint->raw_expr);
			appendStringInfoString(str, ") STORED ");
			break;
		case CONSTR_CHECK:
			appendStringInfoString(str, "CHECK (");
			deparseExpr(str, constraint->raw_expr);
			appendStringInfoString(str, ") ");
			break;
		case CONSTR_PRIMARY:
			appendStringInfoString(str, "PRIMARY KEY ");
			break;
		case CONSTR_UNIQUE:
			appendStringInfoString(str, "UNIQUE ");
			break;
		case CONSTR_EXCLUSION:
			appendStringInfoString(str, "EXCLUDE ");
			if (strcmp(constraint->access_method, DEFAULT_INDEX_TYPE) != 0)
			{
				appendStringInfoString(str, "USING ");
				appendStringInfoString(str, quote_identifier(constraint->access_method));
				appendStringInfoChar(str, ' ');
			}
			appendStringInfoChar(str, '(');
			foreach(lc, constraint->exclusions)
			{
				List *exclusion = castNode(List, lfirst(lc));
				Assert(list_length(exclusion) == 2);
				deparseIndexElem(str, castNode(IndexElem, linitial(exclusion)));
				appendStringInfoString(str, " WITH ");
				deparseAnyOperator(str, castNode(List, lsecond(exclusion)));
				if (lnext(constraint->exclusions, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoString(str, ") ");
			if (constraint->where_clause != NULL)
			{
				appendStringInfoString(str, "WHERE (");
				deparseExpr(str, constraint->where_clause);
				appendStringInfoString(str, ") ");
			}
			break;
		case CONSTR_FOREIGN:
			if (list_length(constraint->fk_attrs) > 0)
				appendStringInfoString(str, "FOREIGN KEY ");
			break;
		case CONSTR_ATTR_DEFERRABLE:
			appendStringInfoString(str, "DEFERRABLE ");
			break;
		case CONSTR_ATTR_NOT_DEFERRABLE:
			appendStringInfoString(str, "NOT DEFERRABLE ");
			break;
		case CONSTR_ATTR_DEFERRED:
			appendStringInfoString(str, "INITIALLY DEFERRED ");
			break;
		case CONSTR_ATTR_IMMEDIATE:
			appendStringInfoString(str, "INITIALLY IMMEDIATE ");
			break;
	}

	if (list_length(constraint->keys) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseColumnList(str, constraint->keys);
		appendStringInfoString(str, ") ");
	}

	if (list_length(constraint->fk_attrs) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseColumnList(str, constraint->fk_attrs);
		appendStringInfoString(str, ") ");
	}

	if (constraint->pktable != NULL)
	{
		appendStringInfoString(str, "REFERENCES ");
		deparseRangeVar(str, constraint->pktable, DEPARSE_NODE_CONTEXT_NONE);
		appendStringInfoChar(str, ' ');
		if (list_length(constraint->pk_attrs) > 0)
		{
			appendStringInfoChar(str, '(');
			deparseColumnList(str, constraint->pk_attrs);
			appendStringInfoString(str, ") ");
		}
	}

	switch (constraint->fk_matchtype)
	{
		case FKCONSTR_MATCH_SIMPLE:
			// Default
			break;
		case FKCONSTR_MATCH_FULL:
			appendStringInfoString(str, "MATCH FULL ");
			break;
		case FKCONSTR_MATCH_PARTIAL:
			// Not implemented in Postgres
			Assert(false);
			break;
		default:
			// Not specified
			break;
	}

	switch (constraint->fk_upd_action)
	{
		case FKCONSTR_ACTION_NOACTION:
			// Default
			break;
		case FKCONSTR_ACTION_RESTRICT:
			appendStringInfoString(str, "ON UPDATE RESTRICT ");
			break;
		case FKCONSTR_ACTION_CASCADE:
			appendStringInfoString(str, "ON UPDATE CASCADE ");
			break;
		case FKCONSTR_ACTION_SETNULL:
			appendStringInfoString(str, "ON UPDATE SET NULL ");
			break;
		case FKCONSTR_ACTION_SETDEFAULT:
			appendStringInfoString(str, "ON UPDATE SET DEFAULT ");
			break;
		default:
			// Not specified
			break;
	}

	switch (constraint->fk_del_action)
	{
		case FKCONSTR_ACTION_NOACTION:
			// Default
			break;
		case FKCONSTR_ACTION_RESTRICT:
			appendStringInfoString(str, "ON DELETE RESTRICT ");
			break;
		case FKCONSTR_ACTION_CASCADE:
			appendStringInfoString(str, "ON DELETE CASCADE ");
			break;
		case FKCONSTR_ACTION_SETNULL:
		case FKCONSTR_ACTION_SETDEFAULT:
			appendStringInfoString(str, "ON DELETE SET ");

			switch (constraint->fk_del_action) {
				case FKCONSTR_ACTION_SETDEFAULT: appendStringInfoString(str, "DEFAULT "); break;
				case FKCONSTR_ACTION_SETNULL:    appendStringInfoString(str, "NULL "); break;
			}

			if (constraint->fk_del_set_cols) {
				appendStringInfoString(str, "(");
				ListCell *lc;
				foreach (lc, constraint->fk_del_set_cols) {
					appendStringInfoString(str, strVal(lfirst(lc)));
					if (lfirst(lc) != llast(constraint->fk_del_set_cols))
						appendStringInfoString(str, ", ");
				}
				appendStringInfoString(str, ")");
			}
			break;
		default:
			// Not specified
			break;
	}

	if (list_length(constraint->including) > 0)
	{
		appendStringInfoString(str, "INCLUDE (");
		deparseColumnList(str, constraint->including);
		appendStringInfoString(str, ") ");
	}

	switch (constraint->contype)
	{
		case CONSTR_PRIMARY:
		case CONSTR_UNIQUE:
		case CONSTR_EXCLUSION:
			deparseOptWith(str, constraint->options);
			break;
		default:
			break;
	}

	if (constraint->indexname != NULL)
		appendStringInfo(str, "USING INDEX %s ", quote_identifier(constraint->indexname));

	if (constraint->indexspace != NULL)
		appendStringInfo(str, "USING INDEX TABLESPACE %s ", quote_identifier(constraint->indexspace));

	if (constraint->deferrable)
		appendStringInfoString(str, "DEFERRABLE ");

	if (constraint->initdeferred)
		appendStringInfoString(str, "INITIALLY DEFERRED ");

	if (constraint->is_no_inherit)
		appendStringInfoString(str, "NO INHERIT ");

	if (constraint->skip_validation)
		appendStringInfoString(str, "NOT VALID ");
	
	removeTrailingSpace(str);
}

static void deparseReturnStmt(StringInfo str, ReturnStmt *return_stmt)
{
	appendStringInfoString(str, "RETURN ");
	deparseExpr(str, return_stmt->returnval);
}

static void deparseCreateFunctionStmt(StringInfo str, CreateFunctionStmt *create_function_stmt)
{
	ListCell *lc;
	bool tableFunc = false;

	appendStringInfoString(str, "CREATE ");
	if (create_function_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");
	if (create_function_stmt->is_procedure)
		appendStringInfoString(str, "PROCEDURE ");
	else
		appendStringInfoString(str, "FUNCTION ");

	deparseFuncName(str, create_function_stmt->funcname);

	appendStringInfoChar(str, '(');
	foreach(lc, create_function_stmt->parameters)
	{
		FunctionParameter *function_parameter = castNode(FunctionParameter, lfirst(lc));
		if (function_parameter->mode != FUNC_PARAM_TABLE)
		{
			deparseFunctionParameter(str, function_parameter);
			if (lnext(create_function_stmt->parameters, lc) && castNode(FunctionParameter, lfirst(lnext(create_function_stmt->parameters, lc)))->mode != FUNC_PARAM_TABLE)
				appendStringInfoString(str, ", ");
		}
		else
		{
			tableFunc = true;
		}
	}
	appendStringInfoString(str, ") ");

	if (tableFunc)
	{
		appendStringInfoString(str, "RETURNS TABLE (");
		foreach(lc, create_function_stmt->parameters)
		{
			FunctionParameter *function_parameter = castNode(FunctionParameter, lfirst(lc));
			if (function_parameter->mode == FUNC_PARAM_TABLE)
			{
				deparseFunctionParameter(str, function_parameter);
				if (lnext(create_function_stmt->parameters, lc))
					appendStringInfoString(str, ", ");
			}
		}
		appendStringInfoString(str, ") ");
	}
	else if (create_function_stmt->returnType != NULL)
	{
		appendStringInfoString(str, "RETURNS ");
		deparseTypeName(str, create_function_stmt->returnType);
		appendStringInfoChar(str, ' ');
	}

	foreach(lc, create_function_stmt->options)
	{
		deparseCreateFuncOptItem(str, castNode(DefElem, lfirst(lc)));
		appendStringInfoChar(str, ' ');
	}

	if (create_function_stmt->sql_body)
	{
		/* RETURN or BEGIN ... END
		 */
		if (IsA(create_function_stmt->sql_body, ReturnStmt))
		{
			deparseReturnStmt(str, castNode(ReturnStmt, create_function_stmt->sql_body));
		}
		else
		{
			appendStringInfoString(str, "BEGIN ATOMIC ");
			if (IsA(create_function_stmt->sql_body, List), linitial((List *) create_function_stmt->sql_body) != NULL)
			{
				List *body_stmt_list = castNode(List, linitial((List *) create_function_stmt->sql_body));
				foreach(lc, body_stmt_list)
				{
					if (IsA(lfirst(lc), ReturnStmt))
					{
						deparseReturnStmt(str, lfirst_node(ReturnStmt, lc));
						appendStringInfoString(str, "; ");
					}
					else
					{
						deparseStmt(str, lfirst(lc));
						appendStringInfoString(str, "; ");
					}
				}
			}
			
			appendStringInfoString(str, "END ");
		}
	}

	removeTrailingSpace(str);
}

static void deparseFunctionParameter(StringInfo str, FunctionParameter *function_parameter)
{
	switch (function_parameter->mode)
	{
		case FUNC_PARAM_IN: /* input only */
			appendStringInfoString(str, "IN ");
			break;
		case FUNC_PARAM_OUT: /* output only */
			appendStringInfoString(str, "OUT ");
			break;
		case FUNC_PARAM_INOUT: /* both */
			appendStringInfoString(str, "INOUT ");
			break;
		case FUNC_PARAM_VARIADIC: /* variadic (always input) */
			appendStringInfoString(str, "VARIADIC ");
			break;
		case FUNC_PARAM_TABLE: /* table function output column */
			// No special annotation, the caller is expected to correctly put
			// this into the RETURNS part of the CREATE FUNCTION statement
			break;
		case FUNC_PARAM_DEFAULT:
			// Default
			break;
		default:
			Assert(false);
			break;
	}

	if (function_parameter->name != NULL)
	{
		appendStringInfoString(str, function_parameter->name);
		appendStringInfoChar(str, ' ');
	}

	deparseTypeName(str, function_parameter->argType);
	appendStringInfoChar(str, ' ');

	if (function_parameter->defexpr != NULL)
	{
		appendStringInfoString(str, "= ");
		deparseExpr(str, function_parameter->defexpr);
	}

	removeTrailingSpace(str);
}

static void deparseCheckPointStmt(StringInfo str, CheckPointStmt *check_point_stmt)
{
	appendStringInfoString(str, "CHECKPOINT");
}

static void deparseCreateSchemaStmt(StringInfo str, CreateSchemaStmt *create_schema_stmt)
{
	ListCell *lc;
	appendStringInfoString(str, "CREATE SCHEMA ");

	if (create_schema_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	if (create_schema_stmt->schemaname)
	{
		deparseColId(str, create_schema_stmt->schemaname);
		appendStringInfoChar(str, ' ');
	}
		
	if (create_schema_stmt->authrole != NULL)
	{
		appendStringInfoString(str, "AUTHORIZATION ");
		deparseRoleSpec(str, create_schema_stmt->authrole);
		appendStringInfoChar(str, ' ');
	}

	if (create_schema_stmt->schemaElts)
	{
		foreach(lc, create_schema_stmt->schemaElts)
		{
			deparseSchemaStmt(str, lfirst(lc));
			if (lnext(create_schema_stmt->schemaElts, lc))
				appendStringInfoChar(str, ' ');
		}
	}

	removeTrailingSpace(str);
}

static void deparseAlterRoleSetStmt(StringInfo str, AlterRoleSetStmt *alter_role_set_stmt)
{
	appendStringInfoString(str, "ALTER ROLE ");

	if (alter_role_set_stmt->role == NULL)
		appendStringInfoString(str, "ALL");
	else
		deparseRoleSpec(str, alter_role_set_stmt->role);

	appendStringInfoChar(str, ' ');
	
	if (alter_role_set_stmt->database != NULL)
	{
		appendStringInfoString(str, "IN DATABASE ");
		appendStringInfoString(str, quote_identifier(alter_role_set_stmt->database));
		appendStringInfoChar(str, ' ');
	}

	deparseVariableSetStmt(str, alter_role_set_stmt->setstmt);
}

static void deparseCreateConversionStmt(StringInfo str, CreateConversionStmt *create_conversion_stmt)
{
	appendStringInfoString(str, "CREATE ");
	if (create_conversion_stmt->def)
		appendStringInfoString(str, "DEFAULT ");

	appendStringInfoString(str, "CONVERSION ");
	deparseAnyName(str, create_conversion_stmt->conversion_name);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "FOR ");
	deparseStringLiteral(str, create_conversion_stmt->for_encoding_name);
	appendStringInfoString(str, " TO ");
	deparseStringLiteral(str, create_conversion_stmt->to_encoding_name);

	appendStringInfoString(str, "FROM ");
	deparseAnyName(str, create_conversion_stmt->func_name);
}

static void deparseRoleSpec(StringInfo str, RoleSpec *role_spec)
{
	switch (role_spec->roletype)
	{
		case ROLESPEC_CSTRING:
			Assert(role_spec->rolename != NULL);
			appendStringInfoString(str, quote_identifier(role_spec->rolename));
			break;
		case ROLESPEC_CURRENT_ROLE:
			appendStringInfoString(str, "CURRENT_ROLE");
			break;
		case ROLESPEC_CURRENT_USER:
			appendStringInfoString(str, "CURRENT_USER");
			break;
		case ROLESPEC_SESSION_USER:
			appendStringInfoString(str, "SESSION_USER");
			break;
		case ROLESPEC_PUBLIC:
			appendStringInfoString(str, "public");
			break;
	}
}

// "part_elem" in gram.y
static void deparsePartitionElem(StringInfo str, PartitionElem *partition_elem)
{
	ListCell *lc;

	if (partition_elem->name != NULL)
	{
		deparseColId(str, partition_elem->name);
		appendStringInfoChar(str, ' ');
	}
	else if (partition_elem->expr != NULL)
	{
		appendStringInfoChar(str, '(');
		deparseExpr(str, partition_elem->expr);
		appendStringInfoString(str, ") ");
	}

	deparseOptCollate(str, partition_elem->collation);
	deparseAnyName(str, partition_elem->opclass);

	removeTrailingSpace(str);
}

static void deparsePartitionSpec(StringInfo str, PartitionSpec *partition_spec)
{
	ListCell *lc;

	appendStringInfoString(str, "PARTITION BY ");
	appendStringInfoString(str, partition_spec->strategy);

	appendStringInfoChar(str, '(');
	foreach(lc, partition_spec->partParams)
	{
		deparsePartitionElem(str, castNode(PartitionElem, lfirst(lc)));
		if (lnext(partition_spec->partParams, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

static void deparsePartitionBoundSpec(StringInfo str, PartitionBoundSpec *partition_bound_spec)
{
	ListCell *lc;

	if (partition_bound_spec->is_default)
	{
		appendStringInfoString(str, "DEFAULT");
		return;
	}

	appendStringInfoString(str, "FOR VALUES ");

	switch (partition_bound_spec->strategy)
	{
		case PARTITION_STRATEGY_HASH:
			appendStringInfo(str, "WITH (MODULUS %d, REMAINDER %d)", partition_bound_spec->modulus, partition_bound_spec->remainder);
			break;
		case PARTITION_STRATEGY_LIST:
			appendStringInfoString(str, "IN (");
			deparseExprList(str, partition_bound_spec->listdatums);
			appendStringInfoChar(str, ')');
			break;
		case PARTITION_STRATEGY_RANGE:
			appendStringInfoString(str, "FROM (");
			deparseExprList(str, partition_bound_spec->lowerdatums);
			appendStringInfoString(str, ") TO (");
			deparseExprList(str, partition_bound_spec->upperdatums);
			appendStringInfoChar(str, ')');
			break;
		default:
			Assert(false);
			break;
	}
}

static void deparsePartitionCmd(StringInfo str, PartitionCmd *partition_cmd)
{
	deparseRangeVar(str, partition_cmd->name, DEPARSE_NODE_CONTEXT_NONE);

	if (partition_cmd->bound != NULL)
	{
		appendStringInfoChar(str, ' ');
		deparsePartitionBoundSpec(str, partition_cmd->bound);
	}
	if (partition_cmd->concurrent)
		appendStringInfoString(str, " CONCURRENTLY ");
}

// "TableElement" in gram.y
static void deparseTableElement(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_ColumnDef:
			deparseColumnDef(str, castNode(ColumnDef, node));
			break;
		case T_TableLikeClause:
			deparseTableLikeClause(str, castNode(TableLikeClause, node));
			break;
		case T_Constraint:
			deparseConstraint(str, castNode(Constraint, node));
			break;
		default:
			Assert(false);
	}
}

static void deparseCreateStmt(StringInfo str, CreateStmt *create_stmt, bool is_foreign_table)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	if (is_foreign_table)
		appendStringInfoString(str, "FOREIGN ");

	deparseOptTemp(str, create_stmt->relation->relpersistence);

	appendStringInfoString(str, "TABLE ");

	if (create_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	deparseRangeVar(str, create_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (create_stmt->ofTypename != NULL)
	{
		appendStringInfoString(str, "OF ");
		deparseTypeName(str, create_stmt->ofTypename);
		appendStringInfoChar(str, ' ');
	}

	if (create_stmt->partbound != NULL)
	{
		Assert(list_length(create_stmt->inhRelations) == 1);
		appendStringInfoString(str, "PARTITION OF ");
		deparseRangeVar(str, castNode(RangeVar, linitial(create_stmt->inhRelations)), DEPARSE_NODE_CONTEXT_NONE);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(create_stmt->tableElts) > 0)
	{
		// In raw parse output tableElts contains both columns and constraints
		// (and the constraints field is NIL)
		appendStringInfoChar(str, '(');
		foreach(lc, create_stmt->tableElts)
		{
			deparseTableElement(str, lfirst(lc));
			if (lnext(create_stmt->tableElts, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoString(str, ") ");
	}
	else if (create_stmt->partbound == NULL && create_stmt->ofTypename == NULL)
	{
		appendStringInfoString(str, "() ");
	}

	if (create_stmt->partbound != NULL)
	{
		deparsePartitionBoundSpec(str, create_stmt->partbound);
		appendStringInfoChar(str, ' ');
	}
	else
	{
		deparseOptInherit(str, create_stmt->inhRelations);
	}

	if (create_stmt->partspec != NULL)
	{
		deparsePartitionSpec(str, create_stmt->partspec);
		appendStringInfoChar(str, ' ');
	}

	if (create_stmt->accessMethod != NULL)
	{
		appendStringInfoString(str, "USING ");
		appendStringInfoString(str, quote_identifier(create_stmt->accessMethod));
	}

	deparseOptWith(str, create_stmt->options);

	switch (create_stmt->oncommit)
	{
		case ONCOMMIT_NOOP:
			// No ON COMMIT clause
			break;
		case ONCOMMIT_PRESERVE_ROWS:
			appendStringInfoString(str, "ON COMMIT PRESERVE ROWS ");
			break;
		case ONCOMMIT_DELETE_ROWS:
			appendStringInfoString(str, "ON COMMIT DELETE ROWS ");
			break;
		case ONCOMMIT_DROP:
			appendStringInfoString(str, "ON COMMIT DROP ");
			break;
	}

	if (create_stmt->tablespacename != NULL)
	{
		appendStringInfoString(str, "TABLESPACE ");
		appendStringInfoString(str, quote_identifier(create_stmt->tablespacename));
	}

	removeTrailingSpace(str);
}

static void deparseCreateFdwStmt(StringInfo str, CreateFdwStmt *create_fdw_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE FOREIGN DATA WRAPPER ");
	appendStringInfoString(str, quote_identifier(create_fdw_stmt->fdwname));
	appendStringInfoChar(str, ' ');

	if (list_length(create_fdw_stmt->func_options) > 0)
	{
		deparseFdwOptions(str, create_fdw_stmt->func_options);
		appendStringInfoChar(str, ' ');
	}

	deparseCreateGenericOptions(str, create_fdw_stmt->options);

	removeTrailingSpace(str);
}

static void deparseAlterFdwStmt(StringInfo str, AlterFdwStmt *alter_fdw_stmt)
{
	appendStringInfoString(str, "ALTER FOREIGN DATA WRAPPER ");
	appendStringInfoString(str, quote_identifier(alter_fdw_stmt->fdwname));
	appendStringInfoChar(str, ' ');

	if (list_length(alter_fdw_stmt->func_options) > 0)
	{
		deparseFdwOptions(str, alter_fdw_stmt->func_options);
		appendStringInfoChar(str, ' ');
	}

	if (list_length(alter_fdw_stmt->options) > 0)
		deparseAlterGenericOptions(str, alter_fdw_stmt->options);

	removeTrailingSpace(str);
}

static void deparseCreateForeignServerStmt(StringInfo str, CreateForeignServerStmt *create_foreign_server_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE SERVER ");
	if (create_foreign_server_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");
	appendStringInfoString(str, quote_identifier(create_foreign_server_stmt->servername));
	appendStringInfoChar(str, ' ');

	if (create_foreign_server_stmt->servertype != NULL)
	{
		appendStringInfoString(str, "TYPE ");
		deparseStringLiteral(str, create_foreign_server_stmt->servertype);
		appendStringInfoChar(str, ' ');
	}

	if (create_foreign_server_stmt->version != NULL)
	{
		appendStringInfoString(str, "VERSION ");
		deparseStringLiteral(str, create_foreign_server_stmt->version);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
	appendStringInfoString(str, quote_identifier(create_foreign_server_stmt->fdwname));
	appendStringInfoChar(str, ' ');

	deparseCreateGenericOptions(str, create_foreign_server_stmt->options);

	removeTrailingSpace(str);
}

static void deparseAlterForeignServerStmt(StringInfo str, AlterForeignServerStmt *alter_foreign_server_stmt)
{
	appendStringInfoString(str, "ALTER SERVER ");

	appendStringInfoString(str, quote_identifier(alter_foreign_server_stmt->servername));
	appendStringInfoChar(str, ' ');

	if (alter_foreign_server_stmt->has_version)
	{
		appendStringInfoString(str, "VERSION ");
		if (alter_foreign_server_stmt->version != NULL)
			deparseStringLiteral(str, alter_foreign_server_stmt->version);
		else
			appendStringInfoString(str, "NULL");
		appendStringInfoChar(str, ' ');
	}

	if (list_length(alter_foreign_server_stmt->options) > 0)
		deparseAlterGenericOptions(str, alter_foreign_server_stmt->options);

	removeTrailingSpace(str);
}

static void deparseCreateUserMappingStmt(StringInfo str, CreateUserMappingStmt *create_user_mapping_stmt)
{
	appendStringInfoString(str, "CREATE USER MAPPING ");
	if (create_user_mapping_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	appendStringInfoString(str, "FOR ");
	deparseRoleSpec(str, create_user_mapping_stmt->user);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "SERVER ");
	appendStringInfoString(str, quote_identifier(create_user_mapping_stmt->servername));
	appendStringInfoChar(str, ' ');

	deparseCreateGenericOptions(str, create_user_mapping_stmt->options);

	removeTrailingSpace(str);
}

static void deparseCreatedbStmt(StringInfo str, CreatedbStmt *createdb_stmt)
{
	appendStringInfoString(str, "CREATE DATABASE ");
	deparseColId(str, createdb_stmt->dbname);
	appendStringInfoChar(str, ' ');
	deparseCreatedbOptList(str, createdb_stmt->options);
	removeTrailingSpace(str);
}

static void deparseAlterUserMappingStmt(StringInfo str, AlterUserMappingStmt *alter_user_mapping_stmt)
{
	appendStringInfoString(str, "ALTER USER MAPPING FOR ");
	deparseRoleSpec(str, alter_user_mapping_stmt->user);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "SERVER ");
	appendStringInfoString(str, quote_identifier(alter_user_mapping_stmt->servername));
	appendStringInfoChar(str, ' ');

	deparseAlterGenericOptions(str, alter_user_mapping_stmt->options);

	removeTrailingSpace(str);
}

static void deparseDropUserMappingStmt(StringInfo str, DropUserMappingStmt *drop_user_mapping_stmt)
{
	appendStringInfoString(str, "DROP USER MAPPING ");

	if (drop_user_mapping_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	appendStringInfoString(str, "FOR ");
	deparseRoleSpec(str, drop_user_mapping_stmt->user);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "SERVER ");
	appendStringInfoString(str, quote_identifier(drop_user_mapping_stmt->servername));
}

static void deparseSecLabelStmt(StringInfo str, SecLabelStmt *sec_label_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "SECURITY LABEL ");

	if (sec_label_stmt->provider != NULL)
	{
		appendStringInfoString(str, "FOR ");
		appendStringInfoString(str, quote_identifier(sec_label_stmt->provider));
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "ON ");

	switch (sec_label_stmt->objtype)
	{
		case OBJECT_COLUMN:
			appendStringInfoString(str, "COLUMN ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			deparseAnyName(str, castNode(List, sec_label_stmt->object));
			break;
		case OBJECT_DATABASE:
			appendStringInfoString(str, "DATABASE ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_PUBLICATION:
			appendStringInfoString(str, "PUBLICATION ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_ROLE:
			appendStringInfoString(str, "ROLE ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_SUBSCRIPTION:
			appendStringInfoString(str, "SUBSCRIPTION ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, "TABLESPACE ");
			appendStringInfoString(str, quote_identifier(strVal(sec_label_stmt->object)));
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			deparseTypeName(str, castNode(TypeName, sec_label_stmt->object));
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			deparseTypeName(str, castNode(TypeName, sec_label_stmt->object));
			break;
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, sec_label_stmt->object));
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, sec_label_stmt->object));
			break;
		case OBJECT_LARGEOBJECT:
			appendStringInfoString(str, "LARGE OBJECT ");
			deparseValue(str, (union ValUnion *) sec_label_stmt->object, DEPARSE_NODE_CONTEXT_CONSTANT);
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, sec_label_stmt->object));
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, sec_label_stmt->object));
			break;
		default:
			// Not supported in the parser
			Assert(false);
			break;
	}

	appendStringInfoString(str, " IS ");

	if (sec_label_stmt->label != NULL)
		deparseStringLiteral(str, sec_label_stmt->label);
	else
		appendStringInfoString(str, "NULL");
}

static void deparseCreateForeignTableStmt(StringInfo str, CreateForeignTableStmt *create_foreign_table_stmt)
{
	ListCell *lc;

	deparseCreateStmt(str, &create_foreign_table_stmt->base, true);

	appendStringInfoString(str, " SERVER ");
	appendStringInfoString(str, quote_identifier(create_foreign_table_stmt->servername));
	appendStringInfoChar(str, ' ');

	if (list_length(create_foreign_table_stmt->options) > 0)
		deparseAlterGenericOptions(str, create_foreign_table_stmt->options);

	removeTrailingSpace(str);
}

static void deparseImportForeignSchemaStmt(StringInfo str, ImportForeignSchemaStmt *import_foreign_schema_stmt)
{
	appendStringInfoString(str, "IMPORT FOREIGN SCHEMA ");

	appendStringInfoString(str, import_foreign_schema_stmt->remote_schema);
	appendStringInfoChar(str, ' ');

	switch (import_foreign_schema_stmt->list_type)
	{
		case FDW_IMPORT_SCHEMA_ALL:
			// Default
			break;
		case FDW_IMPORT_SCHEMA_LIMIT_TO:
			appendStringInfoString(str, "LIMIT TO (");
			deparseRelationExprList(str, import_foreign_schema_stmt->table_list);
			appendStringInfoString(str, ") ");
			break;
		case FDW_IMPORT_SCHEMA_EXCEPT:
			appendStringInfoString(str, "EXCEPT (");
			deparseRelationExprList(str, import_foreign_schema_stmt->table_list);
			appendStringInfoString(str, ") ");
			break;
	}

	appendStringInfoString(str, "FROM SERVER ");
	appendStringInfoString(str, quote_identifier(import_foreign_schema_stmt->server_name));
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "INTO ");
	appendStringInfoString(str, quote_identifier(import_foreign_schema_stmt->local_schema));
	appendStringInfoChar(str, ' ');

	deparseCreateGenericOptions(str, import_foreign_schema_stmt->options);

	removeTrailingSpace(str);
}

static void deparseCreateTableAsStmt(StringInfo str, CreateTableAsStmt *create_table_as_stmt)
{
	ListCell *lc;
	appendStringInfoString(str, "CREATE ");

	deparseOptTemp(str, create_table_as_stmt->into->rel->relpersistence);

	switch (create_table_as_stmt->objtype)
	{
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		default:
			// Not supported here
			Assert(false);
			break;
	}

	if (create_table_as_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	deparseIntoClause(str, create_table_as_stmt->into);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "AS ");
	if (IsA(create_table_as_stmt->query, ExecuteStmt))
		deparseExecuteStmt(str, castNode(ExecuteStmt, create_table_as_stmt->query));
	else
		deparseSelectStmt(str, castNode(SelectStmt, create_table_as_stmt->query));
	appendStringInfoChar(str, ' ');

	if (create_table_as_stmt->into->skipData)
		appendStringInfoString(str, "WITH NO DATA ");

	removeTrailingSpace(str);
}

static void deparseViewStmt(StringInfo str, ViewStmt *view_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	if (view_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");

	deparseOptTemp(str, view_stmt->view->relpersistence);

	appendStringInfoString(str, "VIEW ");
	deparseRangeVar(str, view_stmt->view, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (list_length(view_stmt->aliases) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseColumnList(str, view_stmt->aliases);
		appendStringInfoString(str, ") ");
	}

	deparseOptWith(str, view_stmt->options);

	appendStringInfoString(str, "AS ");
	deparseSelectStmt(str, castNode(SelectStmt, view_stmt->query));
	appendStringInfoChar(str, ' ');

	switch (view_stmt->withCheckOption)
	{
		case NO_CHECK_OPTION:
			// Default
			break;
		case LOCAL_CHECK_OPTION:
			appendStringInfoString(str, "WITH LOCAL CHECK OPTION ");
			break;
		case CASCADED_CHECK_OPTION:
			appendStringInfoString(str, "WITH CHECK OPTION ");
			break;
	}

	removeTrailingSpace(str);
}

static void deparseDropStmt(StringInfo str, DropStmt *drop_stmt)
{
	ListCell *lc;
	List *l;

	appendStringInfoString(str, "DROP ");

	switch (drop_stmt->removeType)
	{
		case OBJECT_ACCESS_METHOD:
			appendStringInfoString(str, "ACCESS METHOD ");
			break;
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			break;
		case OBJECT_CAST:
			appendStringInfoString(str, "CAST ");
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			break;
		case OBJECT_EXTENSION:
			appendStringInfoString(str, "EXTENSION ");
			break;
		case OBJECT_FDW:
			appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
			break;
		case OBJECT_FOREIGN_SERVER:
			appendStringInfoString(str, "SERVER ");
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			break;
		case OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		case OBJECT_OPCLASS:
			appendStringInfoString(str, "OPERATOR CLASS ");
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			break;
		case OBJECT_OPFAMILY:
			appendStringInfoString(str, "OPERATOR FAMILY ");
			break;
		case OBJECT_POLICY:
			appendStringInfoString(str, "POLICY ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			break;
		case OBJECT_PUBLICATION:
			appendStringInfoString(str, "PUBLICATION ");
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			break;
		case OBJECT_RULE:
			appendStringInfoString(str, "RULE ");
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			break;
		case OBJECT_STATISTIC_EXT:
			appendStringInfoString(str, "STATISTICS ");
			break;
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_TRANSFORM:
			appendStringInfoString(str, "TRANSFORM ");
			break;
		case OBJECT_TRIGGER:
			appendStringInfoString(str, "TRIGGER ");
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			break;
		default:
			// Other object types are not supported here in the parser
			Assert(false);
	}

	if (drop_stmt->concurrent)
		appendStringInfoString(str, "CONCURRENTLY ");

	if (drop_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	switch (drop_stmt->removeType)
	{
		// drop_type_any_name
		case OBJECT_TABLE:
		case OBJECT_SEQUENCE:
		case OBJECT_VIEW:
		case OBJECT_MATVIEW:
		case OBJECT_INDEX:
		case OBJECT_FOREIGN_TABLE:
		case OBJECT_COLLATION:
		case OBJECT_CONVERSION:
		case OBJECT_STATISTIC_EXT:
		case OBJECT_TSPARSER:
		case OBJECT_TSDICTIONARY:
		case OBJECT_TSTEMPLATE:
		case OBJECT_TSCONFIGURATION:
			deparseAnyNameList(str, drop_stmt->objects);
			appendStringInfoChar(str, ' ');
			break;
		// drop_type_name
		case OBJECT_ACCESS_METHOD:
		case OBJECT_EVENT_TRIGGER:
		case OBJECT_EXTENSION:
		case OBJECT_FDW:
		case OBJECT_PUBLICATION:
		case OBJECT_SCHEMA:
		case OBJECT_FOREIGN_SERVER:
			deparseNameList(str, drop_stmt->objects);
			appendStringInfoChar(str, ' ');
			break;
		// drop_type_name_on_any_name
		case OBJECT_POLICY:
		case OBJECT_RULE:
		case OBJECT_TRIGGER:
			Assert(list_length(drop_stmt->objects) == 1);
			l = linitial(drop_stmt->objects);
			deparseColId(str, strVal(llast(l)));
			appendStringInfoString(str, " ON ");
			deparseAnyNameSkipLast(str, l);
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_CAST:
			Assert(list_length(drop_stmt->objects) == 1);
			l = linitial(drop_stmt->objects);
			Assert(list_length(l) == 2);
			appendStringInfoChar(str, '(');
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " AS ");
			deparseTypeName(str, castNode(TypeName, lsecond(l)));
			appendStringInfoChar(str, ')');
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_OPFAMILY:
		case OBJECT_OPCLASS:
			Assert(list_length(drop_stmt->objects) == 1);
			l = linitial(drop_stmt->objects);
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			deparseColId(str, strVal(linitial(l)));
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_TRANSFORM:
			Assert(list_length(drop_stmt->objects) == 1);
			l = linitial(drop_stmt->objects);
			appendStringInfoString(str, "FOR ");
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " LANGUAGE ");
			deparseColId(str, strVal(lsecond(l)));
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_LANGUAGE:
			deparseNameList(str, drop_stmt->objects);
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_TYPE:
		case OBJECT_DOMAIN:
			foreach(lc, drop_stmt->objects)
			{
				deparseTypeName(str, castNode(TypeName, lfirst(lc)));
				if (lnext(drop_stmt->objects, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_AGGREGATE:
			foreach(lc, drop_stmt->objects)
			{
				deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, lfirst(lc)));
				if (lnext(drop_stmt->objects, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_FUNCTION:
		case OBJECT_PROCEDURE:
		case OBJECT_ROUTINE:
			foreach(lc, drop_stmt->objects)
			{
				deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, lfirst(lc)));
				if (lnext(drop_stmt->objects, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_OPERATOR:
			foreach(lc, drop_stmt->objects)
			{
				deparseOperatorWithArgtypes(str, castNode(ObjectWithArgs, lfirst(lc)));
				if (lnext(drop_stmt->objects, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			break;
		default:
			Assert(false);
	}

	deparseOptDropBehavior(str, drop_stmt->behavior);

	removeTrailingSpace(str);
}

static void deparseGroupingSet(StringInfo str, GroupingSet *grouping_set)
{
	switch(grouping_set->kind)
	{
		case GROUPING_SET_EMPTY:
			appendStringInfoString(str, "()");
			break;
		case GROUPING_SET_SIMPLE:
			// Not present in raw parse trees
			Assert(false);
			break;
		case GROUPING_SET_ROLLUP:
			appendStringInfoString(str, "ROLLUP (");
			deparseExprList(str, grouping_set->content);
			appendStringInfoChar(str, ')');
			break;
		case GROUPING_SET_CUBE:
			appendStringInfoString(str, "CUBE (");
			deparseExprList(str, grouping_set->content);
			appendStringInfoChar(str, ')');
			break;
		case GROUPING_SET_SETS:
			appendStringInfoString(str, "GROUPING SETS (");
			deparseGroupByList(str, grouping_set->content);
			appendStringInfoChar(str, ')');
			break;
	}
}

static void deparseDropTableSpaceStmt(StringInfo str, DropTableSpaceStmt *drop_table_space_stmt)
{
	appendStringInfoString(str, "DROP TABLESPACE ");

	if (drop_table_space_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	appendStringInfoString(str, drop_table_space_stmt->tablespacename);
}

static void deparseAlterObjectDependsStmt(StringInfo str, AlterObjectDependsStmt *alter_object_depends_stmt)
{
	appendStringInfoString(str, "ALTER ");

	switch (alter_object_depends_stmt->objectType)
	{
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_depends_stmt->object));
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_depends_stmt->object));
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_depends_stmt->object));
			break;
		case OBJECT_TRIGGER:
			appendStringInfoString(str, "TRIGGER ");
			deparseColId(str, strVal(linitial(castNode(List, alter_object_depends_stmt->object))));
			appendStringInfoString(str, " ON ");
			deparseRangeVar(str, alter_object_depends_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			deparseRangeVar(str, alter_object_depends_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			deparseRangeVar(str, alter_object_depends_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		default:
			// No other object types supported here
			Assert(false);
	}
	appendStringInfoChar(str, ' ');

	if (alter_object_depends_stmt->remove)
		appendStringInfoString(str, "NO ");

	appendStringInfo(str, "DEPENDS ON EXTENSION %s", alter_object_depends_stmt->extname->sval);
}

static void deparseAlterObjectSchemaStmt(StringInfo str, AlterObjectSchemaStmt *alter_object_schema_stmt)
{
	List *l = NULL;
	ListCell *lc = NULL;

	appendStringInfoString(str, "ALTER ");

	switch (alter_object_schema_stmt->objectType)
	{
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, alter_object_schema_stmt->object));
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_EXTENSION:
			appendStringInfoString(str, "EXTENSION ");
			appendStringInfoString(str, quote_identifier(strVal(alter_object_schema_stmt->object)));
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_schema_stmt->object));
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			deparseOperatorWithArgtypes(str, castNode(ObjectWithArgs, alter_object_schema_stmt->object));
			break;
		case OBJECT_OPCLASS:
			l = castNode(List, alter_object_schema_stmt->object);
			appendStringInfoString(str, "OPERATOR CLASS ");
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			appendStringInfoString(str, quote_identifier(strVal(linitial(l))));
			break;
		case OBJECT_OPFAMILY:
			l = castNode(List, alter_object_schema_stmt->object);
			appendStringInfoString(str, "OPERATOR FAMILY ");
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			appendStringInfoString(str, quote_identifier(strVal(linitial(l))));
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_schema_stmt->object));
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_object_schema_stmt->object));
			break;
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			if (alter_object_schema_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			deparseRangeVar(str, alter_object_schema_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_STATISTIC_EXT:
			appendStringInfoString(str, "STATISTICS ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			if (alter_object_schema_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			deparseRangeVar(str, alter_object_schema_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			if (alter_object_schema_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			deparseRangeVar(str, alter_object_schema_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			if (alter_object_schema_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			deparseRangeVar(str, alter_object_schema_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			if (alter_object_schema_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			deparseRangeVar(str, alter_object_schema_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			deparseAnyName(str, castNode(List, alter_object_schema_stmt->object));
			break;
		default:
			Assert(false);
			break;
	}

	appendStringInfoString(str, " SET SCHEMA ");
	appendStringInfoString(str, quote_identifier(alter_object_schema_stmt->newschema));
}

static void deparseAlterTableCmd(StringInfo str, AlterTableCmd *alter_table_cmd, DeparseNodeContext context)
{
	ListCell *lc = NULL;
	const char *options = NULL;
	bool trailing_missing_ok = false;

	switch (alter_table_cmd->subtype)
	{
		case AT_AddColumn: /* add column */
			if (context == DEPARSE_NODE_CONTEXT_ALTER_TYPE)
				appendStringInfoString(str, "ADD ATTRIBUTE ");
			else
				appendStringInfoString(str, "ADD COLUMN ");
			break;
		case AT_AddColumnRecurse: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AddColumnToView: /* implicitly via CREATE OR REPLACE VIEW */
			// Not present in raw parser output
			Assert(false);
			break;
		case AT_ColumnDefault: /* alter column default */
			appendStringInfoString(str, "ALTER COLUMN ");
			if (alter_table_cmd->def != NULL)
				options = "SET DEFAULT";
			else
				options = "DROP DEFAULT";
			break;
		case AT_CookedColumnDefault: /* add a pre-cooked column default */
			// Not present in raw parser output
			Assert(false);
			break;
		case AT_DropNotNull: /* alter column drop not null */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "DROP NOT NULL";
			break;
		case AT_SetNotNull: /* alter column set not null */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "SET NOT NULL";
			break;
		case AT_DropExpression: /* alter column drop expression */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "DROP EXPRESSION";
			trailing_missing_ok = true;
			break;
		case AT_CheckNotNull: /* check column is already marked not null */
			// Not present in raw parser output
			Assert(false);
			break;
		case AT_SetStatistics: /* alter column set statistics */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "SET STATISTICS";
			break;
		case AT_SetOptions: /* alter column set ( options ) */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "SET";
			break;
		case AT_ResetOptions: /* alter column reset ( options ) */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "RESET";
			break;
		case AT_SetStorage: /* alter column set storage */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "SET STORAGE";
			break;
		case AT_SetCompression: /* alter column set compression */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "SET COMPRESSION";
			break;
		case AT_DropColumn: /* drop column */
			if (context == DEPARSE_NODE_CONTEXT_ALTER_TYPE)
				appendStringInfoString(str, "DROP ATTRIBUTE ");
			else
				appendStringInfoString(str, "DROP ");
			break;
		case AT_DropColumnRecurse: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AddIndex: /* add index */
			appendStringInfoString(str, "ADD INDEX ");
			break;
		case AT_ReAddIndex: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AddConstraint: /* add constraint */
			appendStringInfoString(str, "ADD ");
			break;
		case AT_AddConstraintRecurse: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_ReAddConstraint: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_ReAddDomainConstraint: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AlterConstraint: /* alter constraint */
			appendStringInfoString(str, "ALTER "); // CONSTRAINT keyword gets added by the Constraint itself (when deparsing def)
			break;
		case AT_ValidateConstraint: /* validate constraint */
			appendStringInfoString(str, "VALIDATE CONSTRAINT ");
			break;
		case AT_ValidateConstraintRecurse: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AddIndexConstraint: /* add constraint using existing index */
			// Not present in raw parser output
			Assert(false);
			break;
		case AT_DropConstraint: /* drop constraint */
			appendStringInfoString(str, "DROP CONSTRAINT ");
			break;
		case AT_DropConstraintRecurse: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_ReAddComment: /* internal to commands/tablecmds.c */
		case AT_ReAddStatistics: /* internal to commands/tablecmds.c */
			Assert(false);
			break;
		case AT_AlterColumnType: /* alter column type */
			if (context == DEPARSE_NODE_CONTEXT_ALTER_TYPE)
				appendStringInfoString(str, "ALTER ATTRIBUTE ");
			else
				appendStringInfoString(str, "ALTER COLUMN ");
			options = "TYPE";
			break;
		case AT_AlterColumnGenericOptions: /* alter column OPTIONS (...) */
			appendStringInfoString(str, "ALTER COLUMN ");
			// Handled via special case in def handling
			break;
		case AT_ChangeOwner: /* change owner */
			appendStringInfoString(str, "OWNER TO ");
			deparseRoleSpec(str, alter_table_cmd->newowner);
			break;
		case AT_ClusterOn: /* CLUSTER ON */
			appendStringInfoString(str, "CLUSTER ON ");
			break;
		case AT_DropCluster: /* SET WITHOUT CLUSTER */
			appendStringInfoString(str, "SET WITHOUT CLUSTER ");
			break;
		case AT_SetLogged: /* SET LOGGED */
			appendStringInfoString(str, "SET LOGGED ");
			break;
		case AT_SetUnLogged: /* SET UNLOGGED */
			appendStringInfoString(str, "SET UNLOGGED ");
			break;
		case AT_DropOids: /* SET WITHOUT OIDS */
			appendStringInfoString(str, "SET WITHOUT OIDS ");
			break;
		case AT_SetTableSpace: /* SET TABLESPACE */
			appendStringInfoString(str, "SET TABLESPACE ");
			break;
		case AT_SetRelOptions: /* SET (...) -- AM specific parameters */
			appendStringInfoString(str, "SET ");
			break;
		case AT_SetAccessMethod:
			appendStringInfo(str, "SET ACCESS METHOD ");
			break;
		case AT_ResetRelOptions: /* RESET (...) -- AM specific parameters */
			appendStringInfoString(str, "RESET ");
			break;
		case AT_ReplaceRelOptions: /* replace reloption list in its entirety */
			// Not present in raw parser output
			Assert(false);
			break;
		case AT_EnableTrig: /* ENABLE TRIGGER name */
			appendStringInfoString(str, "ENABLE TRIGGER ");
			break;
		case AT_EnableAlwaysTrig: /* ENABLE ALWAYS TRIGGER name */
			appendStringInfoString(str, "ENABLE ALWAYS TRIGGER ");
			break;
		case AT_EnableReplicaTrig: /* ENABLE REPLICA TRIGGER name */
			appendStringInfoString(str, "ENABLE REPLICA TRIGGER ");
			break;
		case AT_DisableTrig: /* DISABLE TRIGGER name */
			appendStringInfoString(str, "DISABLE TRIGGER ");
			break;
		case AT_EnableTrigAll: /* ENABLE TRIGGER ALL */
			appendStringInfoString(str, "ENABLE TRIGGER ");
			break;
		case AT_DisableTrigAll: /* DISABLE TRIGGER ALL */
			appendStringInfoString(str, "DISABLE TRIGGER ALL ");
			break;
		case AT_EnableTrigUser: /* ENABLE TRIGGER USER */
			appendStringInfoString(str, "ENABLE TRIGGER USER ");
			break;
		case AT_DisableTrigUser: /* DISABLE TRIGGER USER */
			appendStringInfoString(str, "DISABLE TRIGGER USER ");
			break;
		case AT_EnableRule: /* ENABLE RULE name */
			appendStringInfoString(str, "ENABLE RULE ");
			break;
		case AT_EnableAlwaysRule: /* ENABLE ALWAYS RULE name */
			appendStringInfoString(str, "ENABLE ALWAYS RULE ");
			break;
		case AT_EnableReplicaRule: /* ENABLE REPLICA RULE name */
			appendStringInfoString(str, "ENABLE REPLICA RULE ");
			break;
		case AT_DisableRule: /* DISABLE RULE name */
			appendStringInfoString(str, "DISABLE RULE ");
			break;
		case AT_AddInherit: /* INHERIT parent */
			appendStringInfoString(str, "INHERIT ");
			break;
		case AT_DropInherit: /* NO INHERIT parent */
			appendStringInfoString(str, "NO INHERIT ");
			break;
		case AT_AddOf: /* OF <type_name> */
			appendStringInfoString(str, "OF ");
			break;
		case AT_DropOf: /* NOT OF */
			appendStringInfoString(str, "NOT OF ");
			break;
		case AT_ReplicaIdentity: /* REPLICA IDENTITY */
			appendStringInfoString(str, "REPLICA IDENTITY ");
			break;
		case AT_EnableRowSecurity: /* ENABLE ROW SECURITY */
			appendStringInfoString(str, "ENABLE ROW LEVEL SECURITY ");
			break;
		case AT_DisableRowSecurity: /* DISABLE ROW SECURITY */
			appendStringInfoString(str, "DISABLE ROW LEVEL SECURITY ");
			break;
		case AT_ForceRowSecurity: /* FORCE ROW SECURITY */
			appendStringInfoString(str, "FORCE ROW LEVEL SECURITY ");
			break;
		case AT_NoForceRowSecurity: /* NO FORCE ROW SECURITY */
			appendStringInfoString(str, "NO FORCE ROW LEVEL SECURITY ");
			break;
		case AT_GenericOptions: /* OPTIONS (...) */
			// Handled in def field handling
			break;
		case AT_AttachPartition: /* ATTACH PARTITION */
			appendStringInfoString(str, "ATTACH PARTITION ");
			break;
		case AT_DetachPartition: /* DETACH PARTITION */
			appendStringInfoString(str, "DETACH PARTITION ");
			break;
		case AT_DetachPartitionFinalize: /* DETACH PARTITION FINALIZE */
			appendStringInfoString(str, "DETACH PARTITION ");
			break;
		case AT_AddIdentity: /* ADD IDENTITY */
			appendStringInfoString(str, "ALTER ");
			options = "ADD";
			// Other details are output via the constraint node (in def field)
			break;
		case AT_SetIdentity: /* SET identity column options */
			appendStringInfoString(str, "ALTER ");
			break;
		case AT_DropIdentity: /* DROP IDENTITY */
			appendStringInfoString(str, "ALTER COLUMN ");
			options = "DROP IDENTITY";
			trailing_missing_ok = true;
			break;
	}

	if (alter_table_cmd->missing_ok && !trailing_missing_ok)
	{
		if (alter_table_cmd->subtype == AT_AddColumn)
			appendStringInfoString(str, "IF NOT EXISTS ");
		else
			appendStringInfoString(str, "IF EXISTS ");
	}

	if (alter_table_cmd->name != NULL)
	{
		appendStringInfoString(str, quote_identifier(alter_table_cmd->name));
		appendStringInfoChar(str, ' ');
	}

	if (alter_table_cmd->num > 0)
		appendStringInfo(str, "%d ", alter_table_cmd->num);

	if (options != NULL)
	{
		appendStringInfoString(str, options);
		appendStringInfoChar(str, ' ');
	}

	if (alter_table_cmd->missing_ok && trailing_missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	switch (alter_table_cmd->subtype)
	{
		case AT_AttachPartition:
		case AT_DetachPartition:
			deparsePartitionCmd(str, castNode(PartitionCmd, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_DetachPartitionFinalize:
			deparsePartitionCmd(str, castNode(PartitionCmd, alter_table_cmd->def));
			appendStringInfoString(str, "FINALIZE ");
			break;
		case AT_AddColumn:
		case AT_AlterColumnType:
			deparseColumnDef(str, castNode(ColumnDef, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_ColumnDefault:
			if (alter_table_cmd->def != NULL)
			{
				deparseExpr(str, alter_table_cmd->def);
				appendStringInfoChar(str, ' ');
			}
			break;
		case AT_SetStatistics:
			deparseSignedIconst(str, alter_table_cmd->def);
			appendStringInfoChar(str, ' ');
			break;
		case AT_SetOptions:
		case AT_ResetOptions:
		case AT_SetRelOptions:
		case AT_ResetRelOptions:
			deparseRelOptions(str, castNode(List, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_SetStorage:
			deparseColId(str, strVal(alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_SetCompression:
			if (strcmp(strVal(alter_table_cmd->def), "default") == 0)
				appendStringInfoString(str, "DEFAULT");
			else
				deparseColId(str, strVal(alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_AddIdentity:
		case AT_AddConstraint:
		case AT_AlterConstraint:
			deparseConstraint(str, castNode(Constraint, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_SetIdentity:
			deparseAlterIdentityColumnOptionList(str, castNode(List, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_AlterColumnGenericOptions:
		case AT_GenericOptions:
			deparseAlterGenericOptions(str, castNode(List, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_AddInherit:
		case AT_DropInherit:
			deparseRangeVar(str, castNode(RangeVar, alter_table_cmd->def), DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoChar(str, ' ');
			break;
		case AT_AddOf:
			deparseTypeName(str, castNode(TypeName, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		case AT_ReplicaIdentity:
			deparseReplicaIdentityStmt(str, castNode(ReplicaIdentityStmt, alter_table_cmd->def));
			appendStringInfoChar(str, ' ');
			break;
		default:
			Assert(alter_table_cmd->def == NULL);
			break;
	}

	deparseOptDropBehavior(str, alter_table_cmd->behavior);

	removeTrailingSpace(str);
}

static DeparseNodeContext deparseAlterTableObjType(StringInfo str, ObjectType type)
{
	switch (type)
	{
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			break;
		case OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			return DEPARSE_NODE_CONTEXT_ALTER_TYPE;
			break;
		default:
			Assert(false);
			break;
	}

	return DEPARSE_NODE_CONTEXT_NONE;
}

static void deparseAlterTableMoveAllStmt(StringInfo str, AlterTableMoveAllStmt *move_all_stmt)
{
	appendStringInfoString(str, "ALTER ");
	deparseAlterTableObjType(str, move_all_stmt->objtype);

	appendStringInfoString(str, "ALL IN TABLESPACE ");
	appendStringInfoString(str, move_all_stmt->orig_tablespacename);
	appendStringInfoChar(str, ' ');

	if (move_all_stmt->roles)
	{
		appendStringInfoString(str, "OWNED BY ");
		deparseRoleList(str, move_all_stmt->roles);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "SET TABLESPACE ");
	appendStringInfoString(str, move_all_stmt->new_tablespacename);
	appendStringInfoChar(str, ' ');

	if (move_all_stmt->nowait)
	{
		appendStringInfoString(str, "NOWAIT");
	}
}

static void deparseAlterTableStmt(StringInfo str, AlterTableStmt *alter_table_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER ");
	DeparseNodeContext context = deparseAlterTableObjType(str, alter_table_stmt->objtype);

	if (alter_table_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	deparseRangeVar(str, alter_table_stmt->relation, context);
	appendStringInfoChar(str, ' ');

	foreach(lc, alter_table_stmt->cmds)
	{
		deparseAlterTableCmd(str, castNode(AlterTableCmd, lfirst(lc)), context);
		if (lnext(alter_table_stmt->cmds, lc))
			appendStringInfoString(str, ", ");
	}
}

static void deparseAlterTableSpaceOptionsStmt(StringInfo str, AlterTableSpaceOptionsStmt *alter_table_space_options_stmt)
{
	appendStringInfoString(str, "ALTER TABLESPACE ");
	deparseColId(str, alter_table_space_options_stmt->tablespacename);
	appendStringInfoChar(str, ' ');

	if (alter_table_space_options_stmt->isReset)
		appendStringInfoString(str, "RESET ");
	else
		appendStringInfoString(str, "SET ");

	deparseRelOptions(str, alter_table_space_options_stmt->options);
}

static void deparseAlterDomainStmt(StringInfo str, AlterDomainStmt *alter_domain_stmt)
{
	appendStringInfoString(str, "ALTER DOMAIN ");
	deparseAnyName(str, alter_domain_stmt->typeName);
	appendStringInfoChar(str, ' ');

	switch (alter_domain_stmt->subtype)
	{
		case 'T':
			if (alter_domain_stmt->def != NULL)
			{
				appendStringInfoString(str, "SET DEFAULT ");
				deparseExpr(str, alter_domain_stmt->def);
			}
			else
			{
				appendStringInfoString(str, "DROP DEFAULT");
			}
			break;
		case 'N':
			appendStringInfoString(str, "DROP NOT NULL");
			break;
		case 'O':
			appendStringInfoString(str, "SET NOT NULL");
			break;
		case 'C':
			appendStringInfoString(str, "ADD ");
			deparseConstraint(str, castNode(Constraint, alter_domain_stmt->def));
			break;
		case 'X':
			appendStringInfoString(str, "DROP CONSTRAINT ");
			if (alter_domain_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			appendStringInfoString(str, quote_identifier(alter_domain_stmt->name));
			if (alter_domain_stmt->behavior == DROP_CASCADE)
				appendStringInfoString(str, " CASCADE");
			break;
		case 'V':
			appendStringInfoString(str, "VALIDATE CONSTRAINT ");
			appendStringInfoString(str, quote_identifier(alter_domain_stmt->name));
			break;
		default:
			// No other subtypes supported by the parser
			Assert(false);
	}
}

static void deparseRenameStmt(StringInfo str, RenameStmt *rename_stmt)
{
	List *l = NULL;

	appendStringInfoString(str, "ALTER ");

	switch (rename_stmt->renameType)
	{
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			break;
		case OBJECT_DATABASE:
			appendStringInfoString(str, "DATABASE ");
			break;
		case OBJECT_DOMAIN:
		case OBJECT_DOMCONSTRAINT:
			appendStringInfoString(str, "DOMAIN ");
			break;
		case OBJECT_FDW:
			appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			break;
		case OBJECT_ROLE:
			appendStringInfoString(str, "ROLE ");
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			break;
		case OBJECT_OPCLASS:
			appendStringInfoString(str, "OPERATOR CLASS ");
			break;
		case OBJECT_OPFAMILY:
			appendStringInfoString(str, "OPERATOR FAMILY ");
			break;
		case OBJECT_POLICY:
			appendStringInfoString(str, "POLICY ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			break;
		case OBJECT_PUBLICATION:
			appendStringInfoString(str, "PUBLICATION ");
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			break;
		case OBJECT_FOREIGN_SERVER:
			appendStringInfoString(str, "SERVER ");
			break;
		case OBJECT_SUBSCRIPTION:
			appendStringInfoString(str, "SUBSCRIPTION ");
			break;
		case OBJECT_TABLE:
		case OBJECT_TABCONSTRAINT:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_COLUMN:
			switch (rename_stmt->relationType)
			{
				case OBJECT_TABLE:
					appendStringInfoString(str, "TABLE ");
					break;
				case OBJECT_FOREIGN_TABLE:
					appendStringInfoString(str, "FOREIGN TABLE ");
					break;
				case OBJECT_VIEW:
					appendStringInfoString(str, "VIEW ");
					break;
				case OBJECT_MATVIEW:
					appendStringInfoString(str, "MATERIALIZED VIEW ");
					break;
				default:
					Assert(false);
			}
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		case OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			break;
		case OBJECT_RULE:
			appendStringInfoString(str, "RULE ");
			break;
		case OBJECT_TRIGGER:
			appendStringInfoString(str, "TRIGGER ");
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			break;
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, "TABLESPACE ");
			break;
		case OBJECT_STATISTIC_EXT:
			appendStringInfoString(str, "STATISTICS ");
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			break;
		case OBJECT_TYPE:
		case OBJECT_ATTRIBUTE:
			appendStringInfoString(str, "TYPE ");
			break;
		default:
			Assert(false);
			break;
	}

	if (rename_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	switch (rename_stmt->renameType)
	{
		case OBJECT_AGGREGATE:
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, rename_stmt->object));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_DOMCONSTRAINT:
			deparseAnyName(str, castNode(List, rename_stmt->object));
			appendStringInfoString(str, " RENAME CONSTRAINT ");
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_OPCLASS:
		case OBJECT_OPFAMILY:
			l = castNode(List, rename_stmt->object);
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			appendStringInfoString(str, quote_identifier(strVal(linitial(l))));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_POLICY:
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoString(str, " ON ");
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_FUNCTION:
		case OBJECT_PROCEDURE:
		case OBJECT_ROUTINE:
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, rename_stmt->object));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_SUBSCRIPTION:
			deparseColId(str, strVal(rename_stmt->object));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_TABLE:
		case OBJECT_SEQUENCE:
		case OBJECT_VIEW:
		case OBJECT_MATVIEW:
		case OBJECT_INDEX:
		case OBJECT_FOREIGN_TABLE:
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_COLUMN:
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoString(str, " RENAME COLUMN ");
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_TABCONSTRAINT:
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoString(str, " RENAME CONSTRAINT ");
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoChar(str, ' ');
			break;
		case OBJECT_RULE:
		case OBJECT_TRIGGER:
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoString(str, " ON ");
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_FDW:
		case OBJECT_LANGUAGE:
		case OBJECT_PUBLICATION:
		case OBJECT_FOREIGN_SERVER:
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, quote_identifier(strVal(rename_stmt->object)));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_DATABASE:
		case OBJECT_ROLE:
		case OBJECT_SCHEMA:
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_COLLATION:
		case OBJECT_CONVERSION:
		case OBJECT_DOMAIN:
		case OBJECT_STATISTIC_EXT:
		case OBJECT_TSPARSER:
		case OBJECT_TSDICTIONARY:
		case OBJECT_TSTEMPLATE:
		case OBJECT_TSCONFIGURATION:
		case OBJECT_TYPE:
			deparseAnyName(str, castNode(List, rename_stmt->object));
			appendStringInfoString(str, " RENAME ");
			break;
		case OBJECT_ATTRIBUTE:
			deparseRangeVar(str, rename_stmt->relation, DEPARSE_NODE_CONTEXT_ALTER_TYPE);
			appendStringInfoString(str, " RENAME ATTRIBUTE ");
			appendStringInfoString(str, quote_identifier(rename_stmt->subname));
			appendStringInfoChar(str, ' ');
			break;
		default:
			Assert(false);
			break;
	}

	appendStringInfoString(str, "TO ");
	appendStringInfoString(str, quote_identifier(rename_stmt->newname));
	appendStringInfoChar(str, ' ');

	deparseOptDropBehavior(str, rename_stmt->behavior);

	removeTrailingSpace(str);
}

static void deparseTransactionStmt(StringInfo str, TransactionStmt *transaction_stmt)
{
	ListCell *lc;
	switch (transaction_stmt->kind)
	{
		case TRANS_STMT_BEGIN:
			appendStringInfoString(str, "BEGIN ");
			deparseTransactionModeList(str, transaction_stmt->options);
			break;
		case TRANS_STMT_START:
			appendStringInfoString(str, "START TRANSACTION ");
			deparseTransactionModeList(str, transaction_stmt->options);
			break;
		case TRANS_STMT_COMMIT:
			appendStringInfoString(str, "COMMIT ");
			if (transaction_stmt->chain)
				appendStringInfoString(str, "AND CHAIN ");
			break;
		case TRANS_STMT_ROLLBACK:
			appendStringInfoString(str, "ROLLBACK ");
			if (transaction_stmt->chain)
				appendStringInfoString(str, "AND CHAIN ");
			break;
		case TRANS_STMT_SAVEPOINT:
			appendStringInfoString(str, "SAVEPOINT ");
			appendStringInfoString(str, quote_identifier(transaction_stmt->savepoint_name));
			break;
		case TRANS_STMT_RELEASE:
			appendStringInfoString(str, "RELEASE ");
			appendStringInfoString(str, quote_identifier(transaction_stmt->savepoint_name));
			break;
		case TRANS_STMT_ROLLBACK_TO:
			appendStringInfoString(str, "ROLLBACK ");
			appendStringInfoString(str, "TO SAVEPOINT ");
			appendStringInfoString(str, quote_identifier(transaction_stmt->savepoint_name));
			break;
		case TRANS_STMT_PREPARE:
			appendStringInfoString(str, "PREPARE TRANSACTION ");
			deparseStringLiteral(str, transaction_stmt->gid);
			break;
		case TRANS_STMT_COMMIT_PREPARED:
			appendStringInfoString(str, "COMMIT PREPARED ");
			deparseStringLiteral(str, transaction_stmt->gid);
			break;
		case TRANS_STMT_ROLLBACK_PREPARED:
			appendStringInfoString(str, "ROLLBACK PREPARED ");
			deparseStringLiteral(str, transaction_stmt->gid);
			break;
	}

	removeTrailingSpace(str);
}

// Determine if we hit SET TIME ZONE INTERVAL, that has special syntax not
// supported for other SET statements
static bool isSetTimeZoneInterval(VariableSetStmt* stmt)
{
	if (!(strcmp(stmt->name, "timezone") == 0 &&
		  list_length(stmt->args) == 1 &&
		  IsA(linitial(stmt->args), TypeCast)))
		return false;

	TypeName* typeName = castNode(TypeCast, linitial(stmt->args))->typeName;

	return (list_length(typeName->names) == 2 &&
		strcmp(strVal(linitial(typeName->names)), "pg_catalog") == 0 &&
		strcmp(strVal(llast(typeName->names)), "interval") == 0);
}

static void deparseVariableSetStmt(StringInfo str, VariableSetStmt* variable_set_stmt)
{
	ListCell *lc;

	switch (variable_set_stmt->kind)
	{
		case VAR_SET_VALUE: /* SET var = value */
			appendStringInfoString(str, "SET ");
			if (variable_set_stmt->is_local)
				appendStringInfoString(str, "LOCAL ");
			if (isSetTimeZoneInterval(variable_set_stmt))
			{
				appendStringInfoString(str, "TIME ZONE ");
				deparseVarList(str, variable_set_stmt->args);
			}
			else
			{
				deparseVarName(str, variable_set_stmt->name);
				appendStringInfoString(str, " TO ");
				deparseVarList(str, variable_set_stmt->args);
			}
			break;
		case VAR_SET_DEFAULT: /* SET var TO DEFAULT */
			appendStringInfoString(str, "SET ");
			if (variable_set_stmt->is_local)
				appendStringInfoString(str, "LOCAL ");
			deparseVarName(str, variable_set_stmt->name);
			appendStringInfoString(str, " TO DEFAULT");
			break;
		case VAR_SET_CURRENT: /* SET var FROM CURRENT */
			appendStringInfoString(str, "SET ");
			if (variable_set_stmt->is_local)
				appendStringInfoString(str, "LOCAL ");
			deparseVarName(str, variable_set_stmt->name);
			appendStringInfoString(str, " FROM CURRENT");
			break;
		case VAR_SET_MULTI: /* special case for SET TRANSACTION ... */
			Assert(variable_set_stmt->name != NULL);
			appendStringInfoString(str, "SET ");
			if (variable_set_stmt->is_local)
				appendStringInfoString(str, "LOCAL ");
			if (strcmp(variable_set_stmt->name, "TRANSACTION") == 0)
			{
				appendStringInfoString(str, "TRANSACTION ");
				deparseTransactionModeList(str, variable_set_stmt->args);
			}
			else if (strcmp(variable_set_stmt->name, "SESSION CHARACTERISTICS") == 0)
			{
				appendStringInfoString(str, "SESSION CHARACTERISTICS AS TRANSACTION ");
				deparseTransactionModeList(str, variable_set_stmt->args);
			}
			else if (strcmp(variable_set_stmt->name, "TRANSACTION SNAPSHOT") == 0)
			{
				appendStringInfoString(str, "TRANSACTION SNAPSHOT ");
				deparseStringLiteral(str, strVal(&castNode(A_Const, linitial(variable_set_stmt->args))->val));
			}
			else
			{
				Assert(false);
			}
			break;
		case VAR_RESET: /* RESET var */
			appendStringInfoString(str, "RESET ");
			deparseVarName(str, variable_set_stmt->name);
			break;
		case VAR_RESET_ALL: /* RESET ALL */
			appendStringInfoString(str, "RESET ALL");
			break;
	}
}

static void deparseDropdbStmt(StringInfo str, DropdbStmt *dropdb_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "DROP DATABASE ");
	if (dropdb_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	appendStringInfoString(str, quote_identifier(dropdb_stmt->dbname));
	appendStringInfoChar(str, ' ');

	if (list_length(dropdb_stmt->options) > 0)
	{
		appendStringInfoChar(str, '(');
		foreach(lc, dropdb_stmt->options)
		{
			DefElem *def_elem = castNode(DefElem, lfirst(lc));
			if (strcmp(def_elem->defname, "force") == 0)
				appendStringInfoString(str, "FORCE");
			else
				Assert(false); // Currently there are other supported values

			if (lnext(dropdb_stmt->options, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ')');
	}

	removeTrailingSpace(str);
}

static void deparseVacuumStmt(StringInfo str, VacuumStmt *vacuum_stmt)
{
	ListCell *lc = NULL;
	ListCell *lc2 = NULL;

	if (vacuum_stmt->is_vacuumcmd)
		appendStringInfoString(str, "VACUUM ");
	else
		appendStringInfoString(str, "ANALYZE ");

        deparseUtilityOptionList(str, vacuum_stmt->options);

	foreach(lc, vacuum_stmt->rels)
	{
		Assert(IsA(lfirst(lc), VacuumRelation));
		VacuumRelation *rel = castNode(VacuumRelation, lfirst(lc));

		deparseRangeVar(str, rel->relation, DEPARSE_NODE_CONTEXT_NONE);
		if (list_length(rel->va_cols) > 0)
		{
			appendStringInfoChar(str, '(');
			foreach(lc2, rel->va_cols)
			{
				appendStringInfoString(str, quote_identifier(strVal(lfirst(lc2))));
				if (lnext(rel->va_cols, lc2))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ')');
		}

		if (lnext(vacuum_stmt->rels, lc))
			appendStringInfoString(str, ", ");
	}

	removeTrailingSpace(str);
}

static void deparseLoadStmt(StringInfo str, LoadStmt *load_stmt)
{
	appendStringInfoString(str, "LOAD ");
	deparseStringLiteral(str, load_stmt->filename);
}

static void deparseLockStmt(StringInfo str, LockStmt *lock_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "LOCK TABLE ");

	deparseRelationExprList(str, lock_stmt->relations);
	appendStringInfoChar(str, ' ');

	if (lock_stmt->mode != AccessExclusiveLock)
	{
		appendStringInfoString(str, "IN ");
		switch (lock_stmt->mode)
		{
			case AccessShareLock:
				appendStringInfoString(str, "ACCESS SHARE ");
				break;
			case RowShareLock:
				appendStringInfoString(str, "ROW SHARE ");
				break;
			case RowExclusiveLock:
				appendStringInfoString(str, "ROW EXCLUSIVE ");
				break;
			case ShareUpdateExclusiveLock:
				appendStringInfoString(str, "SHARE UPDATE EXCLUSIVE ");
				break;
			case ShareLock:
				appendStringInfoString(str, "SHARE ");
				break;
			case ShareRowExclusiveLock:
				appendStringInfoString(str, "SHARE ROW EXCLUSIVE ");
				break;
			case ExclusiveLock:
				appendStringInfoString(str, "EXCLUSIVE ");
				break;
			case AccessExclusiveLock:
				appendStringInfoString(str, "ACCESS EXCLUSIVE ");
				break;
			default:
				Assert(false);
				break;
		}
		appendStringInfoString(str, "MODE ");
	}

	if (lock_stmt->nowait)
		appendStringInfoString(str, "NOWAIT ");

	removeTrailingSpace(str);
}

static void deparseConstraintsSetStmt(StringInfo str, ConstraintsSetStmt *constraints_set_stmt)
{
	appendStringInfoString(str, "SET CONSTRAINTS ");

	if (list_length(constraints_set_stmt->constraints) > 0)
	{
		deparseQualifiedNameList(str, constraints_set_stmt->constraints);
		appendStringInfoChar(str, ' ');
	}
	else
	{
		appendStringInfoString(str, "ALL ");
	}

	if (constraints_set_stmt->deferred)
		appendStringInfoString(str, "DEFERRED");
	else
		appendStringInfoString(str, "IMMEDIATE");
}

static void deparseExplainStmt(StringInfo str, ExplainStmt *explain_stmt)
{
	ListCell *lc = NULL;
	char *defname = NULL;

	appendStringInfoString(str, "EXPLAIN ");

        deparseUtilityOptionList(str, explain_stmt->options);

	deparseExplainableStmt(str, explain_stmt->query);
}

static void deparseCopyStmt(StringInfo str, CopyStmt *copy_stmt)
{
	ListCell *lc = NULL;
	ListCell *lc2 = NULL;

	appendStringInfoString(str, "COPY ");

	if (copy_stmt->relation != NULL)
	{
		deparseRangeVar(str, copy_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
		if (list_length(copy_stmt->attlist) > 0)
		{
			appendStringInfoChar(str, '(');
			deparseColumnList(str, copy_stmt->attlist);
			appendStringInfoChar(str, ')');
		}
		appendStringInfoChar(str, ' ');
	}

	if (copy_stmt->query != NULL)
	{
		appendStringInfoChar(str, '(');
		deparsePreparableStmt(str, copy_stmt->query);
		appendStringInfoString(str, ") ");
	}

	if (copy_stmt->is_from)
		appendStringInfoString(str, "FROM ");
	else
		appendStringInfoString(str, "TO ");

	if (copy_stmt->is_program)
		appendStringInfoString(str, "PROGRAM ");

	if (copy_stmt->filename != NULL)
	{
		deparseStringLiteral(str, copy_stmt->filename);
		appendStringInfoChar(str, ' ');
	}
	else
	{
		if (copy_stmt->is_from)
			appendStringInfoString(str, "STDIN ");
		else
			appendStringInfoString(str, "STDOUT ");
	}

	if (list_length(copy_stmt->options) > 0)
	{
		// In some cases, equivalent expressions may have slightly different parse trees for `COPY`
		// statements. For example the following two statements result in different (but equivalent) parse
		// trees:
		//
		//   - COPY foo FROM STDIN CSV FREEZE
		//   - COPY foo FROM STDIN WITH (FORMAT CSV, FREEZE)
		//
		// In order to make sure we deparse to the "correct" version, we always try to deparse to the older
		// compact syntax first.
		//
		// The old syntax can be seen here in the Postgres 8.4 Reference:
		//     https://www.postgresql.org/docs/8.4/sql-copy.html

		bool old_fmt = true;

		// Loop over the options to see if any require the new `WITH (...)` syntax.
		foreach(lc, copy_stmt->options)
		{
			DefElem *def_elem = castNode(DefElem, lfirst(lc));

			if (strcmp(def_elem->defname, "freeze") == 0 && optBooleanValue(def_elem->arg))
			{}
			else if (strcmp(def_elem->defname, "header") == 0 && def_elem->arg && optBooleanValue(def_elem->arg))
			{}
			else if (strcmp(def_elem->defname, "format") == 0 && strcmp(strVal(def_elem->arg), "csv") == 0)
			{}
			else if (strcmp(def_elem->defname, "force_quote") == 0 && def_elem->arg && nodeTag(def_elem->arg) == T_List)
			{}
			else
			{
				old_fmt = false;
				break;
			}
		}

		// Branch to differing output modes, depending on if we can use the old syntax.
		if (old_fmt) {
			foreach(lc, copy_stmt->options)
			{
				DefElem *def_elem = castNode(DefElem, lfirst(lc));

				if (strcmp(def_elem->defname, "freeze") == 0 && optBooleanValue(def_elem->arg))
				{
					appendStringInfoString(str, "FREEZE ");
				}
				else if (strcmp(def_elem->defname, "header") == 0 && def_elem->arg && optBooleanValue(def_elem->arg))
				{
					appendStringInfoString(str, "HEADER ");
				}
				else if (strcmp(def_elem->defname, "format") == 0 && strcmp(strVal(def_elem->arg), "csv") == 0)
				{
					appendStringInfoString(str, "CSV ");
				}
				else if (strcmp(def_elem->defname, "force_quote") == 0 && def_elem->arg && nodeTag(def_elem->arg) == T_List)
				{
					appendStringInfoString(str, "FORCE QUOTE ");
					deparseColumnList(str, castNode(List, def_elem->arg));
				}
				else
				{
					// This isn't reachable, the conditions here are exactly the same as the first loop above.
					Assert(false);
				}
			}
		} else {
			appendStringInfoString(str, "WITH (");
			foreach(lc, copy_stmt->options)
			{
				DefElem *def_elem = castNode(DefElem, lfirst(lc));

				if (strcmp(def_elem->defname, "format") == 0)
				{
					appendStringInfoString(str, "FORMAT ");

					char *format = strVal(def_elem->arg);
					if (strcmp(format, "binary") == 0)
						appendStringInfoString(str, "BINARY");
					else if (strcmp(format, "csv") == 0)
						appendStringInfoString(str, "CSV");
					else
						Assert(false);
				}
				else if (strcmp(def_elem->defname, "freeze") == 0)
				{
					appendStringInfoString(str, "FREEZE");
					deparseOptBoolean(str, def_elem->arg);
				}
				else if (strcmp(def_elem->defname, "delimiter") == 0)
				{
					appendStringInfoString(str, "DELIMITER ");
					deparseStringLiteral(str, strVal(def_elem->arg));
				}
				else if (strcmp(def_elem->defname, "null") == 0)
				{
					appendStringInfoString(str, "NULL ");
					deparseStringLiteral(str, strVal(def_elem->arg));
				}
				else if (strcmp(def_elem->defname, "header") == 0)
				{
					appendStringInfoString(str, "HEADER");
					deparseOptBoolean(str, def_elem->arg);
				}
				else if (strcmp(def_elem->defname, "quote") == 0)
				{
					appendStringInfoString(str, "QUOTE ");
					deparseStringLiteral(str, strVal(def_elem->arg));
				}
				else if (strcmp(def_elem->defname, "escape") == 0)
				{
					appendStringInfoString(str, "ESCAPE ");
					deparseStringLiteral(str, strVal(def_elem->arg));
				}
				else if (strcmp(def_elem->defname, "force_quote") == 0)
				{
					appendStringInfoString(str, "FORCE_QUOTE ");
					if (IsA(def_elem->arg, A_Star))
					{
						appendStringInfoChar(str, '*');
					}
					else if (IsA(def_elem->arg, List))
					{
						appendStringInfoChar(str, '(');
						deparseColumnList(str, castNode(List, def_elem->arg));
						appendStringInfoChar(str, ')');
					}
					else
					{
						Assert(false);
					}
				}
				else if (strcmp(def_elem->defname, "force_not_null") == 0)
				{
					appendStringInfoString(str, "FORCE_NOT_NULL (");
					deparseColumnList(str, castNode(List, def_elem->arg));
					appendStringInfoChar(str, ')');
				}
				else if (strcmp(def_elem->defname, "force_null") == 0)
				{
					appendStringInfoString(str, "FORCE_NULL (");
					deparseColumnList(str, castNode(List, def_elem->arg));
					appendStringInfoChar(str, ')');
				}
				else if (strcmp(def_elem->defname, "encoding") == 0)
				{
					appendStringInfoString(str, "ENCODING ");
					deparseStringLiteral(str, strVal(def_elem->arg));
				}
				else
				{
					appendStringInfoString(str, quote_identifier(def_elem->defname));
					if (def_elem->arg != NULL)
						appendStringInfoChar(str, ' ');
					
					if (def_elem->arg == NULL)
					{
						// Nothing
					}
					else if (IsA(def_elem->arg, String))
					{
						deparseOptBooleanOrString(str, strVal(def_elem->arg));
					}
					else if (IsA(def_elem->arg, Integer) || IsA(def_elem->arg, Float))
					{
						deparseNumericOnly(str, (union ValUnion *) def_elem->arg);
					}
					else if (IsA(def_elem->arg, A_Star))
					{
						deparseAStar(str, castNode(A_Star, def_elem->arg));
					}
					else if (IsA(def_elem->arg, List))
					{
						List *l = castNode(List, def_elem->arg);
						appendStringInfoChar(str, '(');
						foreach(lc2, l)
						{
							deparseOptBooleanOrString(str, strVal(lfirst(lc2)));
							if (lnext(l, lc2))
								appendStringInfoString(str, ", ");
						}
						appendStringInfoChar(str, ')');
					}
				}

				if (lnext(copy_stmt->options, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoString(str, ") ");
		}
	}

	deparseWhereClause(str, copy_stmt->whereClause);

	removeTrailingSpace(str);
}

static void deparseDoStmt(StringInfo str, DoStmt *do_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "DO ");

	foreach (lc, do_stmt->args)
	{
		DefElem *defel = castNode(DefElem, lfirst(lc));
		if (strcmp(defel->defname, "language") == 0)
		{
			appendStringInfoString(str, "LANGUAGE ");
			appendStringInfoString(str, quote_identifier(strVal(defel->arg)));
			appendStringInfoChar(str, ' ');
		}
		else if (strcmp(defel->defname, "as") == 0)
		{
			char *strval = strVal(defel->arg);
			const char *delim = "$$";
			if (strstr(strval, "$$") != NULL)
				delim = "$outer$";
			appendStringInfoString(str, delim);
			appendStringInfoString(str, strval);
			appendStringInfoString(str, delim);
			appendStringInfoChar(str, ' ');
		}
	}

	removeTrailingSpace(str);
}

static void deparseDiscardStmt(StringInfo str, DiscardStmt *discard_stmt)
{
	appendStringInfoString(str, "DISCARD ");
	switch (discard_stmt->target)
	{
		case DISCARD_ALL:
			appendStringInfoString(str, "ALL");
			break;
		case DISCARD_PLANS:
			appendStringInfoString(str, "PLANS");
			break;
		case DISCARD_SEQUENCES:
			appendStringInfoString(str, "SEQUENCES");
			break;
		case DISCARD_TEMP:
			appendStringInfoString(str, "TEMP");
			break;
	}
}

static void deparseDefineStmt(StringInfo str, DefineStmt *define_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	if (define_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");

	switch (define_stmt->kind)
	{
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			break;
		default:
			// This shouldn't happen
			Assert(false);
			break;
	}

	if (define_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	switch (define_stmt->kind)
	{
		case OBJECT_AGGREGATE:
			deparseFuncName(str, define_stmt->defnames);
			break;
		case OBJECT_OPERATOR:
			deparseAnyOperator(str, define_stmt->defnames);
			break;
		case OBJECT_TYPE:
		case OBJECT_TSPARSER:
		case OBJECT_TSDICTIONARY:
		case OBJECT_TSTEMPLATE:
		case OBJECT_TSCONFIGURATION:
		case OBJECT_COLLATION:
			deparseAnyName(str, define_stmt->defnames);
			break;
		default:
			Assert(false);
	}
	appendStringInfoChar(str, ' ');

	if (!define_stmt->oldstyle && define_stmt->kind == OBJECT_AGGREGATE)
	{
		deparseAggrArgs(str, define_stmt->args);
		appendStringInfoChar(str, ' ');
	}

	if (define_stmt->kind == OBJECT_COLLATION &&
		list_length(define_stmt->definition) == 1 &&
		strcmp(castNode(DefElem, linitial(define_stmt->definition))->defname, "from") == 0)
	{
		appendStringInfoString(str, "FROM ");
		deparseAnyName(str, castNode(List, castNode(DefElem, linitial(define_stmt->definition))->arg));
	}
	else if (list_length(define_stmt->definition) > 0)
	{
		deparseDefinition(str, define_stmt->definition);
	}

	removeTrailingSpace(str);
}

static void deparseCompositeTypeStmt(StringInfo str, CompositeTypeStmt *composite_type_stmt)
{
	ListCell *lc;
	RangeVar *typevar;

	appendStringInfoString(str, "CREATE TYPE ");
	deparseRangeVar(str, composite_type_stmt->typevar, DEPARSE_NODE_CONTEXT_CREATE_TYPE);

	appendStringInfoString(str, " AS (");
	foreach(lc, composite_type_stmt->coldeflist)
	{
		deparseColumnDef(str, castNode(ColumnDef, lfirst(lc)));
		if (lnext(composite_type_stmt->coldeflist, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

static void deparseCreateEnumStmt(StringInfo str, CreateEnumStmt *create_enum_stmt)
{
	ListCell *lc;
	appendStringInfoString(str, "CREATE TYPE ");

	deparseAnyName(str, create_enum_stmt->typeName);
	appendStringInfoString(str, " AS ENUM (");
	foreach(lc, create_enum_stmt->vals)
	{
		deparseStringLiteral(str, strVal(lfirst(lc)));
		if (lnext(create_enum_stmt->vals, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

static void deparseCreateRangeStmt(StringInfo str, CreateRangeStmt *create_range_stmt)
{
	appendStringInfoString(str, "CREATE TYPE ");
	deparseAnyName(str, create_range_stmt->typeName);
	appendStringInfoString(str, " AS RANGE ");
	deparseDefinition(str, create_range_stmt->params);
}

static void deparseAlterEnumStmt(StringInfo str, AlterEnumStmt *alter_enum_stmt)
{
	appendStringInfoString(str, "ALTER TYPE ");
	deparseAnyName(str, alter_enum_stmt->typeName);
	appendStringInfoChar(str, ' ');

	if (alter_enum_stmt->oldVal == NULL)
	{
		appendStringInfoString(str, "ADD VALUE ");
		if (alter_enum_stmt->skipIfNewValExists)
			appendStringInfoString(str, "IF NOT EXISTS ");

		deparseStringLiteral(str, alter_enum_stmt->newVal);
		appendStringInfoChar(str, ' ');

		if (alter_enum_stmt->newValNeighbor)
		{
			if (alter_enum_stmt->newValIsAfter)
				appendStringInfoString(str, "AFTER ");
			else
				appendStringInfoString(str, "BEFORE ");
			deparseStringLiteral(str, alter_enum_stmt->newValNeighbor);
		}
	}
	else
	{
		appendStringInfoString(str, "RENAME VALUE ");
		deparseStringLiteral(str, alter_enum_stmt->oldVal);
		appendStringInfoString(str, " TO ");
		deparseStringLiteral(str, alter_enum_stmt->newVal);
	}

	removeTrailingSpace(str);
}

static void deparseAlterExtensionStmt(StringInfo str, AlterExtensionStmt *alter_extension_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "ALTER EXTENSION ");
	deparseColId(str, alter_extension_stmt->extname);
	appendStringInfoString(str, " UPDATE ");
	foreach (lc, alter_extension_stmt->options)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		if (strcmp(def_elem->defname, "new_version") == 0)
		{
			appendStringInfoString(str, "TO ");
			deparseNonReservedWordOrSconst(str, strVal(def_elem->arg));
		}
		else
		{
			Assert(false);
		}
		appendStringInfoChar(str, ' ');
	}
	removeTrailingSpace(str);
}

static void deparseAlterExtensionContentsStmt(StringInfo str, AlterExtensionContentsStmt *alter_extension_contents_stmt)
{
	List *l = NULL;

	appendStringInfoString(str, "ALTER EXTENSION ");
	deparseColId(str, alter_extension_contents_stmt->extname);
	appendStringInfoChar(str, ' ');

	if (alter_extension_contents_stmt->action == 1)
		appendStringInfoString(str, "ADD ");
	else if (alter_extension_contents_stmt->action == -1)
		appendStringInfoString(str, "DROP ");
	else
		Assert(false);

	switch (alter_extension_contents_stmt->objtype)
	{
		case OBJECT_ACCESS_METHOD:
			appendStringInfoString(str, "ACCESS METHOD ");
			break;
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			break;
		case OBJECT_CAST:
			appendStringInfoString(str, "CAST ");
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			break;
		case OBJECT_OPCLASS:
			appendStringInfoString(str, "OPERATOR CLASS ");
			break;
		case OBJECT_OPFAMILY:
			appendStringInfoString(str, "OPERATOR FAMILY ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			break;
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			break;
		case OBJECT_FDW:
			appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
			break;
		case OBJECT_FOREIGN_SERVER:
			appendStringInfoString(str, "SERVER ");
			break;
		case OBJECT_TRANSFORM:
			appendStringInfoString(str, "TRANSFORM ");
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			break;
		default:
			// No other object types are supported here in the parser
			Assert(false);
			break;
	}

	switch (alter_extension_contents_stmt->objtype)
	{
		// any_name
		case OBJECT_COLLATION:
		case OBJECT_CONVERSION:
		case OBJECT_TABLE:
		case OBJECT_TSPARSER:
		case OBJECT_TSDICTIONARY:
		case OBJECT_TSTEMPLATE:
		case OBJECT_TSCONFIGURATION:
		case OBJECT_SEQUENCE:
		case OBJECT_VIEW:
		case OBJECT_MATVIEW:
		case OBJECT_FOREIGN_TABLE:
			deparseAnyName(str, castNode(List, alter_extension_contents_stmt->object));
			break;
		// name
		case OBJECT_ACCESS_METHOD:
		case OBJECT_LANGUAGE:
		case OBJECT_SCHEMA:
		case OBJECT_EVENT_TRIGGER:
		case OBJECT_FDW:
		case OBJECT_FOREIGN_SERVER:
			deparseColId(str, strVal(alter_extension_contents_stmt->object));
			break;
		case OBJECT_AGGREGATE:
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, alter_extension_contents_stmt->object));
			break;
		case OBJECT_CAST:
			l = castNode(List, alter_extension_contents_stmt->object);
			Assert(list_length(l) == 2);
			appendStringInfoChar(str, '(');
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " AS ");
			deparseTypeName(str, castNode(TypeName, lsecond(l)));
			appendStringInfoChar(str, ')');
			break;
		case OBJECT_DOMAIN:
		case OBJECT_TYPE:
			deparseTypeName(str, castNode(TypeName, alter_extension_contents_stmt->object));
			break;
		case OBJECT_FUNCTION:
		case OBJECT_PROCEDURE:
		case OBJECT_ROUTINE:
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_extension_contents_stmt->object));
			break;
		case OBJECT_OPERATOR:
			deparseOperatorWithArgtypes(str, castNode(ObjectWithArgs, alter_extension_contents_stmt->object));
			break;
		case OBJECT_OPFAMILY:
		case OBJECT_OPCLASS:
			l = castNode(List, alter_extension_contents_stmt->object);
			Assert(list_length(l) == 2);
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			deparseColId(str, strVal(linitial(l)));
			break;
		case OBJECT_TRANSFORM:
			l = castNode(List, alter_extension_contents_stmt->object);
			appendStringInfoString(str, "FOR ");
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " LANGUAGE ");
			deparseColId(str, strVal(lsecond(l)));
			break;
		default:
			Assert(false);
			break;
	}
}

static void deparseAccessPriv(StringInfo str, AccessPriv *access_priv)
{
	ListCell *lc;

	if (access_priv->priv_name != NULL)
	{
		if (strcmp(access_priv->priv_name, "select") == 0)
			appendStringInfoString(str, "select");
		else if (strcmp(access_priv->priv_name, "references") == 0)
			appendStringInfoString(str, "references");
		else if (strcmp(access_priv->priv_name, "create") == 0)
			appendStringInfoString(str, "create");
		else
			appendStringInfoString(str, quote_identifier(access_priv->priv_name));
	}
	else
	{
		appendStringInfoString(str, "ALL");
	}
	appendStringInfoChar(str, ' ');

	if (list_length(access_priv->cols) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseColumnList(str, access_priv->cols);
		appendStringInfoChar(str, ')');
	}

	removeTrailingSpace(str);
}

static void deparseGrantStmt(StringInfo str, GrantStmt *grant_stmt)
{
	ListCell *lc;
	if (grant_stmt->is_grant)
		appendStringInfoString(str, "GRANT ");
	else
		appendStringInfoString(str, "REVOKE ");

	if (!grant_stmt->is_grant && grant_stmt->grant_option)
		appendStringInfoString(str, "GRANT OPTION FOR ");

	if (list_length(grant_stmt->privileges) > 0)
	{
		foreach(lc, grant_stmt->privileges)
		{
			deparseAccessPriv(str, castNode(AccessPriv, lfirst(lc)));
			if (lnext(grant_stmt->privileges, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoChar(str, ' ');
	}
	else
	{
		appendStringInfoString(str, "ALL ");
	}
	
	appendStringInfoString(str, "ON ");

	deparsePrivilegeTarget(str, grant_stmt->targtype, grant_stmt->objtype, grant_stmt->objects);
	appendStringInfoChar(str, ' ');

	if (grant_stmt->is_grant)
		appendStringInfoString(str, "TO ");
	else
		appendStringInfoString(str, "FROM ");

	foreach(lc, grant_stmt->grantees)
	{
		deparseRoleSpec(str, castNode(RoleSpec, lfirst(lc)));
		if (lnext(grant_stmt->grantees, lc))
			appendStringInfoChar(str, ',');
		appendStringInfoChar(str, ' ');
	}

	if (grant_stmt->is_grant && grant_stmt->grant_option)
		appendStringInfoString(str, "WITH GRANT OPTION ");

	deparseOptDropBehavior(str, grant_stmt->behavior);

	if (grant_stmt->grantor)
	{
		appendStringInfoString(str, "GRANTED BY ");
		deparseRoleSpec(str, castNode(RoleSpec, grant_stmt->grantor));
	}

	removeTrailingSpace(str);
}

static void deparseGrantRoleStmt(StringInfo str, GrantRoleStmt *grant_role_stmt)
{
	ListCell *lc;

	if (grant_role_stmt->is_grant)
		appendStringInfoString(str, "GRANT ");
	else
		appendStringInfoString(str, "REVOKE ");

	if (!grant_role_stmt->is_grant && grant_role_stmt->admin_opt)
		appendStringInfoString(str, "ADMIN OPTION FOR ");

	foreach(lc, grant_role_stmt->granted_roles)
	{
		deparseAccessPriv(str, castNode(AccessPriv, lfirst(lc)));
		if (lnext(grant_role_stmt->granted_roles, lc))
			appendStringInfoChar(str, ',');
		appendStringInfoChar(str, ' ');
	}

	if (grant_role_stmt->is_grant)
		appendStringInfoString(str, "TO ");
	else
		appendStringInfoString(str, "FROM ");

	deparseRoleList(str, grant_role_stmt->grantee_roles);
	appendStringInfoChar(str, ' ');

	if (grant_role_stmt->is_grant && grant_role_stmt->admin_opt)
		appendStringInfoString(str, "WITH ADMIN OPTION ");

	if (grant_role_stmt->grantor)
	{
		appendStringInfoString(str, "GRANTED BY ");
		deparseRoleSpec(str, castNode(RoleSpec, grant_role_stmt->grantor));
	}

	removeTrailingSpace(str);
}

static void deparseDropRoleStmt(StringInfo str, DropRoleStmt *drop_role_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "DROP ROLE ");

	if (drop_role_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	deparseRoleList(str, drop_role_stmt->roles);
}

static void deparseIndexStmt(StringInfo str, IndexStmt *index_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	if (index_stmt->unique)
		appendStringInfoString(str, "UNIQUE ");

	appendStringInfoString(str, "INDEX ");

	if (index_stmt->concurrent)
		appendStringInfoString(str, "CONCURRENTLY ");

	if (index_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	if (index_stmt->idxname != NULL)
	{
		appendStringInfoString(str, quote_identifier(index_stmt->idxname));
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "ON ");
	deparseRangeVar(str, index_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (index_stmt->accessMethod != NULL)
	{
		appendStringInfoString(str, "USING ");
		appendStringInfoString(str, quote_identifier(index_stmt->accessMethod));
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoChar(str, '(');
	foreach (lc, index_stmt->indexParams)
	{
		deparseIndexElem(str, castNode(IndexElem, lfirst(lc)));
		if (lnext(index_stmt->indexParams, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoString(str, ") ");

	if (list_length(index_stmt->indexIncludingParams) > 0)
	{
		appendStringInfoString(str, "INCLUDE (");
		foreach (lc, index_stmt->indexIncludingParams)
		{
			deparseIndexElem(str, castNode(IndexElem, lfirst(lc)));
			if (lnext(index_stmt->indexIncludingParams, lc))
				appendStringInfoString(str, ", ");
		}
		appendStringInfoString(str, ") ");
	}

	if (index_stmt->nulls_not_distinct)
	{
		appendStringInfoString(str, "NULLS NOT DISTINCT ");
	}

	deparseOptWith(str, index_stmt->options);

	if (index_stmt->tableSpace != NULL)
	{
		appendStringInfoString(str, "TABLESPACE ");
		appendStringInfoString(str, quote_identifier(index_stmt->tableSpace));
		appendStringInfoChar(str, ' ');
	}

	deparseWhereClause(str, index_stmt->whereClause);

	removeTrailingSpace(str);
}

static void deparseAlterOpFamilyStmt(StringInfo str, AlterOpFamilyStmt *alter_op_family_stmt)
{
	appendStringInfoString(str, "ALTER OPERATOR FAMILY ");
	deparseAnyName(str, alter_op_family_stmt->opfamilyname);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "USING ");
	appendStringInfoString(str, quote_identifier(alter_op_family_stmt->amname));
	appendStringInfoChar(str, ' ');

	if (alter_op_family_stmt->isDrop)
		appendStringInfoString(str, "DROP ");
	else
		appendStringInfoString(str, "ADD ");

	deparseOpclassItemList(str, alter_op_family_stmt->items);
}

static void deparsePrepareStmt(StringInfo str, PrepareStmt *prepare_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "PREPARE ");
	deparseColId(str, prepare_stmt->name);
	if (list_length(prepare_stmt->argtypes) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseTypeList(str, prepare_stmt->argtypes);
		appendStringInfoChar(str, ')');
	}
	appendStringInfoString(str, " AS ");
	deparsePreparableStmt(str, prepare_stmt->query);
}

static void deparseExecuteStmt(StringInfo str, ExecuteStmt *execute_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "EXECUTE ");
	appendStringInfoString(str, quote_identifier(execute_stmt->name));
	if (list_length(execute_stmt->params) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseExprList(str, execute_stmt->params);
		appendStringInfoChar(str, ')');
	}
}

static void deparseDeallocateStmt(StringInfo str, DeallocateStmt *deallocate_stmt)
{
	appendStringInfoString(str, "DEALLOCATE ");
	if (deallocate_stmt->name != NULL)
		appendStringInfoString(str, quote_identifier(deallocate_stmt->name));
	else
		appendStringInfoString(str, "ALL");
}

// "AlterOptRoleElem" in gram.y
static void deparseAlterRoleElem(StringInfo str, DefElem *def_elem)
{
	if (strcmp(def_elem->defname, "password") == 0)
	{
		appendStringInfoString(str, "PASSWORD ");
		if (def_elem->arg == NULL)
		{
			appendStringInfoString(str, "NULL");
		}
		else if (IsA(def_elem->arg, ParamRef))
		{
			deparseParamRef(str, castNode(ParamRef, def_elem->arg));
		}
		else if (IsA(def_elem->arg, String))
		{
			deparseStringLiteral(str, strVal(def_elem->arg));
		}
		else
		{
			Assert(false);
		}
	}
	else if (strcmp(def_elem->defname, "connectionlimit") == 0)
	{
		appendStringInfo(str, "CONNECTION LIMIT %d", intVal(def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "validUntil") == 0)
	{
		appendStringInfoString(str, "VALID UNTIL ");
		deparseStringLiteral(str, strVal(def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "superuser") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "SUPERUSER");
	}
	else if (strcmp(def_elem->defname, "superuser") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOSUPERUSER");
	}
	else if (strcmp(def_elem->defname, "createrole") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "CREATEROLE");
	}
	else if (strcmp(def_elem->defname, "createrole") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOCREATEROLE");
	}
	else if (strcmp(def_elem->defname, "isreplication") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "REPLICATION");
	}
	else if (strcmp(def_elem->defname, "isreplication") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOREPLICATION");
	}
	else if (strcmp(def_elem->defname, "createdb") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "CREATEDB");
	}
	else if (strcmp(def_elem->defname, "createdb") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOCREATEDB");
	}
	else if (strcmp(def_elem->defname, "canlogin") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "LOGIN");
	}
	else if (strcmp(def_elem->defname, "canlogin") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOLOGIN");
	}
	else if (strcmp(def_elem->defname, "bypassrls") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "BYPASSRLS");
	}
	else if (strcmp(def_elem->defname, "bypassrls") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOBYPASSRLS");
	}
	else if (strcmp(def_elem->defname, "inherit") == 0 && boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "INHERIT");
	}
	else if (strcmp(def_elem->defname, "inherit") == 0 && !boolVal(def_elem->arg))
	{
		appendStringInfoString(str, "NOINHERIT");
	}
	else
	{
		Assert(false);
	}
}

// "CreateOptRoleElem" in gram.y
static void deparseCreateRoleElem(StringInfo str, DefElem *def_elem)
{
	if (strcmp(def_elem->defname, "sysid") == 0)
	{
		appendStringInfo(str, "SYSID %d", intVal(def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "adminmembers") == 0)
	{
		appendStringInfoString(str, "ADMIN ");
		deparseRoleList(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "rolemembers") == 0)
	{
		appendStringInfoString(str, "ROLE ");
		deparseRoleList(str, castNode(List, def_elem->arg));
	}
	else if (strcmp(def_elem->defname, "addroleto") == 0)
	{
		appendStringInfoString(str, "IN ROLE ");
		deparseRoleList(str, castNode(List, def_elem->arg));
	}
	else
	{
		deparseAlterRoleElem(str, def_elem);
	}
}

static void deparseCreatePLangStmt(StringInfo str, CreatePLangStmt *create_p_lang_stmt)
{
	appendStringInfoString(str, "CREATE ");

	if (create_p_lang_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");

	if (create_p_lang_stmt->pltrusted)
		appendStringInfoString(str, "TRUSTED ");

	appendStringInfoString(str, "LANGUAGE ");
	deparseNonReservedWordOrSconst(str, create_p_lang_stmt->plname);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "HANDLER ");
	deparseHandlerName(str, create_p_lang_stmt->plhandler);
	appendStringInfoChar(str, ' ');

	if (create_p_lang_stmt->plinline)
	{
		appendStringInfoString(str, "INLINE ");
		deparseHandlerName(str, create_p_lang_stmt->plinline);
		appendStringInfoChar(str, ' ');
	}

	if (create_p_lang_stmt->plvalidator)
	{
		appendStringInfoString(str, "VALIDATOR ");
		deparseHandlerName(str, create_p_lang_stmt->plvalidator);
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseCreateRoleStmt(StringInfo str, CreateRoleStmt *create_role_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	switch (create_role_stmt->stmt_type)
	{
		case ROLESTMT_ROLE:
			appendStringInfoString(str, "ROLE ");
			break;
		case ROLESTMT_USER:
			appendStringInfoString(str, "USER ");
			break;
		case ROLESTMT_GROUP:
			appendStringInfoString(str, "GROUP ");
			break;
	}

	appendStringInfoString(str, quote_identifier(create_role_stmt->role));
	appendStringInfoChar(str, ' ');

	if (create_role_stmt->options != NULL)
	{
		appendStringInfoString(str, "WITH ");
		foreach (lc, create_role_stmt->options)
		{
			deparseCreateRoleElem(str, castNode(DefElem, lfirst(lc)));
			appendStringInfoChar(str, ' ');
		}
	}

	removeTrailingSpace(str);
}

static void deparseAlterRoleStmt(StringInfo str, AlterRoleStmt *alter_role_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER ");

	if (list_length(alter_role_stmt->options) == 1 && strcmp(castNode(DefElem, linitial(alter_role_stmt->options))->defname, "rolemembers") == 0)
	{
		appendStringInfoString(str, "GROUP ");
		deparseRoleSpec(str, alter_role_stmt->role);
		appendStringInfoChar(str, ' ');

		if (alter_role_stmt->action == 1)
		{
			appendStringInfoString(str, "ADD USER ");
		}
		else if (alter_role_stmt->action == -1)
		{
			appendStringInfoString(str, "DROP USER ");
		}
		else
		{
			Assert(false);
		}

		deparseRoleList(str, castNode(List, castNode(DefElem, linitial(alter_role_stmt->options))->arg));
	}
	else
	{
		appendStringInfoString(str, "ROLE ");
		deparseRoleSpec(str, alter_role_stmt->role);
		appendStringInfoChar(str, ' ');

		appendStringInfoString(str, "WITH ");
		foreach (lc, alter_role_stmt->options)
		{
			deparseAlterRoleElem(str, castNode(DefElem, lfirst(lc)));
			appendStringInfoChar(str, ' ');
		}
	}

	removeTrailingSpace(str);
}

static void deparseDeclareCursorStmt(StringInfo str, DeclareCursorStmt *declare_cursor_stmt)
{
	appendStringInfoString(str, "DECLARE ");
	appendStringInfoString(str, quote_identifier(declare_cursor_stmt->portalname));
	appendStringInfoChar(str, ' ');

	if (declare_cursor_stmt->options & CURSOR_OPT_BINARY)
		appendStringInfoString(str, "BINARY ");

	if (declare_cursor_stmt->options & CURSOR_OPT_SCROLL)
		appendStringInfoString(str, "SCROLL ");

	if (declare_cursor_stmt->options & CURSOR_OPT_NO_SCROLL)
		appendStringInfoString(str, "NO SCROLL ");

	if (declare_cursor_stmt->options & CURSOR_OPT_INSENSITIVE)
		appendStringInfoString(str, "INSENSITIVE ");

	appendStringInfoString(str, "CURSOR ");

	if (declare_cursor_stmt->options & CURSOR_OPT_HOLD)
		appendStringInfoString(str, "WITH HOLD ");

	appendStringInfoString(str, "FOR ");

	deparseSelectStmt(str, castNode(SelectStmt, declare_cursor_stmt->query));
}

static void deparseFetchStmt(StringInfo str, FetchStmt *fetch_stmt)
{
	if (fetch_stmt->ismove)
		appendStringInfoString(str, "MOVE ");
	else
		appendStringInfoString(str, "FETCH ");

	switch (fetch_stmt->direction)
	{
		case FETCH_FORWARD:
			if (fetch_stmt->howMany == 1)
			{
				// Default
			}
			else if (fetch_stmt->howMany == FETCH_ALL)
			{
				appendStringInfoString(str, "ALL ");
			}
			else
			{
				appendStringInfo(str, "FORWARD %ld ", fetch_stmt->howMany);
			}
			break;
		case FETCH_BACKWARD:
			if (fetch_stmt->howMany == 1)
			{
				appendStringInfoString(str, "PRIOR ");
			}
			else if (fetch_stmt->howMany == FETCH_ALL)
			{
				appendStringInfoString(str, "BACKWARD ALL ");
			}
			else
			{
				appendStringInfo(str, "BACKWARD %ld ", fetch_stmt->howMany);
			}
			break;
		case FETCH_ABSOLUTE:
			if (fetch_stmt->howMany == 1)
			{
				appendStringInfoString(str, "FIRST ");
			}
			else if (fetch_stmt->howMany == -1)
			{
				appendStringInfoString(str, "LAST ");
			}
			else
			{
				appendStringInfo(str, "ABSOLUTE %ld ", fetch_stmt->howMany);
			}
			break;
		case FETCH_RELATIVE:
			appendStringInfo(str, "RELATIVE %ld ", fetch_stmt->howMany);
	}

	appendStringInfoString(str, fetch_stmt->portalname);
}

static void deparseAlterDefaultPrivilegesStmt(StringInfo str, AlterDefaultPrivilegesStmt *alter_default_privileges_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER DEFAULT PRIVILEGES ");

	foreach (lc, alter_default_privileges_stmt->options)
	{
		DefElem *defelem = castNode(DefElem, lfirst(lc));
		if (strcmp(defelem->defname, "schemas") == 0)
		{
			appendStringInfoString(str, "IN SCHEMA ");
			deparseNameList(str, castNode(List, defelem->arg));
			appendStringInfoChar(str, ' ');
		}
		else if (strcmp(defelem->defname, "roles") == 0)
		{
			appendStringInfoString(str, "FOR ROLE ");
			deparseRoleList(str, castNode(List, defelem->arg));
			appendStringInfoChar(str, ' ');
		}
		else
		{
			// No other DefElems are supported
			Assert(false);
		}
	}

	deparseGrantStmt(str, alter_default_privileges_stmt->action);
}

static void deparseReindexStmt(StringInfo str, ReindexStmt *reindex_stmt)
{
	appendStringInfoString(str, "REINDEX ");

        deparseUtilityOptionList(str, reindex_stmt->params);

	switch (reindex_stmt->kind)
	{
		case REINDEX_OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case REINDEX_OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case REINDEX_OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			break;
		case REINDEX_OBJECT_SYSTEM:
			appendStringInfoString(str, "SYSTEM ");
			break;
		case REINDEX_OBJECT_DATABASE:
			appendStringInfoString(str, "DATABASE ");
			break;
	}

	if (reindex_stmt->relation != NULL)
	{
		deparseRangeVar(str, reindex_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	}
	else if (reindex_stmt->name != NULL)
	{
		appendStringInfoString(str, quote_identifier(reindex_stmt->name));
	}
}

static void deparseRuleStmt(StringInfo str, RuleStmt* rule_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	if (rule_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");

	appendStringInfoString(str, "RULE ");
	appendStringInfoString(str, quote_identifier(rule_stmt->rulename));
	appendStringInfoString(str, " AS ON ");

	switch (rule_stmt->event)
	{
		case CMD_UNKNOWN:
		case CMD_UTILITY:
		case CMD_NOTHING:
			// Not supported here
			Assert(false);
			break;
		case CMD_SELECT:
			appendStringInfoString(str, "SELECT ");
			break;
		case CMD_UPDATE:
			appendStringInfoString(str, "UPDATE ");
			break;
		case CMD_INSERT:
			appendStringInfoString(str, "INSERT ");
			break;
		case CMD_DELETE:
			appendStringInfoString(str, "DELETE ");
			break;
		case CMD_MERGE:
			appendStringInfoString(str, "MERGE ");
			break;
	}

	appendStringInfoString(str, "TO ");
	deparseRangeVar(str, rule_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	deparseWhereClause(str, rule_stmt->whereClause);

	appendStringInfoString(str, "DO ");

	if (rule_stmt->instead)
		appendStringInfoString(str, "INSTEAD ");

	if (list_length(rule_stmt->actions) == 0)
	{
		appendStringInfoString(str, "NOTHING");
	}
	else if (list_length(rule_stmt->actions) == 1)
	{
		deparseRuleActionStmt(str, linitial(rule_stmt->actions));
	}
	else
	{
		appendStringInfoChar(str, '(');
		foreach (lc, rule_stmt->actions)
		{
			deparseRuleActionStmt(str, lfirst(lc));
			if (lnext(rule_stmt->actions, lc))
				appendStringInfoString(str, "; ");
		}
		appendStringInfoChar(str, ')');
	}
}

static void deparseNotifyStmt(StringInfo str, NotifyStmt *notify_stmt)
{
	appendStringInfoString(str, "NOTIFY ");
	appendStringInfoString(str, quote_identifier(notify_stmt->conditionname));

	if (notify_stmt->payload != NULL)
	{
		appendStringInfoString(str, ", ");
		deparseStringLiteral(str, notify_stmt->payload);
	}
}

static void deparseListenStmt(StringInfo str, ListenStmt *listen_stmt)
{
	appendStringInfoString(str, "LISTEN ");
	appendStringInfoString(str, quote_identifier(listen_stmt->conditionname));
}

static void deparseUnlistenStmt(StringInfo str, UnlistenStmt *unlisten_stmt)
{
	appendStringInfoString(str, "UNLISTEN ");
	if (unlisten_stmt->conditionname == NULL)
		appendStringInfoString(str, "*");
	else
		appendStringInfoString(str, quote_identifier(unlisten_stmt->conditionname));
}

static void deparseCreateSeqStmt(StringInfo str, CreateSeqStmt *create_seq_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE ");

	deparseOptTemp(str, create_seq_stmt->sequence->relpersistence);

	appendStringInfoString(str, "SEQUENCE ");

	if (create_seq_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	deparseRangeVar(str, create_seq_stmt->sequence, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	deparseOptSeqOptList(str, create_seq_stmt->options);

	removeTrailingSpace(str);
}

static void deparseAlterFunctionStmt(StringInfo str, AlterFunctionStmt *alter_function_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER ");

	switch (alter_function_stmt->objtype)
	{
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			break;
		default:
			// Not supported here
			Assert(false);
			break;
	}

	deparseFunctionWithArgtypes(str, alter_function_stmt->func);
	appendStringInfoChar(str, ' ');

	foreach (lc, alter_function_stmt->actions)
	{
		deparseCommonFuncOptItem(str, castNode(DefElem, lfirst(lc)));
		if (lnext(alter_function_stmt->actions, lc))
			appendStringInfoChar(str, ' ');
	}
}

static void deparseTruncateStmt(StringInfo str, TruncateStmt *truncate_stmt)
{
	appendStringInfoString(str, "TRUNCATE ");

	deparseRelationExprList(str, truncate_stmt->relations);
	appendStringInfoChar(str, ' ');

	if (truncate_stmt->restart_seqs)
		appendStringInfoString(str, "RESTART IDENTITY ");

	deparseOptDropBehavior(str, truncate_stmt->behavior);

	removeTrailingSpace(str);
}

static void deparseCreateEventTrigStmt(StringInfo str, CreateEventTrigStmt *create_event_trig_stmt)
{
	ListCell *lc = NULL;
	ListCell *lc2 = NULL;

	appendStringInfoString(str, "CREATE EVENT TRIGGER ");
	appendStringInfoString(str, quote_identifier(create_event_trig_stmt->trigname));
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "ON ");
	appendStringInfoString(str, quote_identifier(create_event_trig_stmt->eventname));
	appendStringInfoChar(str, ' ');

	if (create_event_trig_stmt->whenclause)
	{
		appendStringInfoString(str, "WHEN ");

		foreach (lc, create_event_trig_stmt->whenclause)
		{
			DefElem *def_elem = castNode(DefElem, lfirst(lc));
			List *l = castNode(List, def_elem->arg);
			appendStringInfoString(str, quote_identifier(def_elem->defname));
			appendStringInfoString(str, " IN (");
			foreach (lc2, l)
			{
				deparseStringLiteral(str, strVal(lfirst(lc2)));
				if (lnext(l, lc2))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ')');
			if (lnext(create_event_trig_stmt->whenclause, lc))
				appendStringInfoString(str, " AND ");
		}

		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "EXECUTE FUNCTION ");
	deparseFuncName(str, create_event_trig_stmt->funcname);
	appendStringInfoString(str, "()");
}

static void deparseAlterEventTrigStmt(StringInfo str, AlterEventTrigStmt *alter_event_trig_stmt)
{
	appendStringInfoString(str, "ALTER EVENT TRIGGER ");
	appendStringInfoString(str, quote_identifier(alter_event_trig_stmt->trigname));
	appendStringInfoChar(str, ' ');

	switch (alter_event_trig_stmt->tgenabled)
	{
		case TRIGGER_FIRES_ON_ORIGIN:
			appendStringInfoString(str, "ENABLE");
			break;
		case TRIGGER_FIRES_ON_REPLICA:
			appendStringInfoString(str, "ENABLE REPLICA");
			break;
		case TRIGGER_FIRES_ALWAYS:
			appendStringInfoString(str, "ENABLE ALWAYS");
			break;
		case TRIGGER_DISABLED:
			appendStringInfoString(str, "DISABLE");
			break;
	}
}

static void deparseRefreshMatViewStmt(StringInfo str, RefreshMatViewStmt *refresh_mat_view_stmt)
{
	appendStringInfoString(str, "REFRESH MATERIALIZED VIEW ");

	if (refresh_mat_view_stmt->concurrent)
		appendStringInfoString(str, "CONCURRENTLY ");

	deparseRangeVar(str, refresh_mat_view_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (refresh_mat_view_stmt->skipData)
		appendStringInfoString(str, "WITH NO DATA ");

	removeTrailingSpace(str);
}

static void deparseReplicaIdentityStmt(StringInfo str, ReplicaIdentityStmt *replica_identity_stmt)
{
	switch (replica_identity_stmt->identity_type)
	{
		case REPLICA_IDENTITY_NOTHING:
			appendStringInfoString(str, "NOTHING ");
			break;
		case REPLICA_IDENTITY_FULL:
			appendStringInfoString(str, "FULL ");
			break;
		case REPLICA_IDENTITY_DEFAULT:
			appendStringInfoString(str, "DEFAULT ");
			break;
		case REPLICA_IDENTITY_INDEX:
			Assert(replica_identity_stmt->name != NULL);
			appendStringInfoString(str, "USING INDEX ");
			appendStringInfoString(str, quote_identifier(replica_identity_stmt->name));
			break;
	}
}

static void deparseCreatePolicyStmt(StringInfo str, CreatePolicyStmt *create_policy_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "CREATE POLICY ");
	deparseColId(str, create_policy_stmt->policy_name);
	appendStringInfoString(str, " ON ");
	deparseRangeVar(str, create_policy_stmt->table, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (!create_policy_stmt->permissive)
		appendStringInfoString(str, "AS RESTRICTIVE ");

	if (strcmp(create_policy_stmt->cmd_name, "all") == 0)
		Assert(true); // Default
	else if (strcmp(create_policy_stmt->cmd_name, "select") == 0)
		appendStringInfoString(str, "FOR SELECT ");
	else if (strcmp(create_policy_stmt->cmd_name, "insert") == 0)
		appendStringInfoString(str, "FOR INSERT ");
	else if (strcmp(create_policy_stmt->cmd_name, "update") == 0)
		appendStringInfoString(str, "FOR UPDATE ");
	else if (strcmp(create_policy_stmt->cmd_name, "delete") == 0)
		appendStringInfoString(str, "FOR DELETE ");
	else
		Assert(false);

	appendStringInfoString(str, "TO ");
	deparseRoleList(str, create_policy_stmt->roles);
	appendStringInfoChar(str, ' ');

	if (create_policy_stmt->qual != NULL)
	{
		appendStringInfoString(str, "USING (");
		deparseExpr(str, create_policy_stmt->qual);
		appendStringInfoString(str, ") ");
	}

	if (create_policy_stmt->with_check != NULL)
	{
		appendStringInfoString(str, "WITH CHECK (");
		deparseExpr(str, create_policy_stmt->with_check);
		appendStringInfoString(str, ") ");
	}
}

static void deparseAlterPolicyStmt(StringInfo str, AlterPolicyStmt *alter_policy_stmt)
{
	appendStringInfoString(str, "ALTER POLICY ");
	appendStringInfoString(str, quote_identifier(alter_policy_stmt->policy_name));
	appendStringInfoString(str, " ON ");
	deparseRangeVar(str, alter_policy_stmt->table, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (list_length(alter_policy_stmt->roles) > 0)
	{
		appendStringInfoString(str, "TO ");
		deparseRoleList(str, alter_policy_stmt->roles);
		appendStringInfoChar(str, ' ');
	}
	
	if (alter_policy_stmt->qual != NULL)
	{
		appendStringInfoString(str, "USING (");
		deparseExpr(str, alter_policy_stmt->qual);
		appendStringInfoString(str, ") ");
	}

	if (alter_policy_stmt->with_check != NULL)
	{
		appendStringInfoString(str, "WITH CHECK (");
		deparseExpr(str, alter_policy_stmt->with_check);
		appendStringInfoString(str, ") ");
	}
}

static void deparseCreateTableSpaceStmt(StringInfo str, CreateTableSpaceStmt *create_table_space_stmt)
{
	appendStringInfoString(str, "CREATE TABLESPACE ");
	deparseColId(str, create_table_space_stmt->tablespacename);
	appendStringInfoChar(str, ' ');

	if (create_table_space_stmt->owner != NULL)
	{
		appendStringInfoString(str, "OWNER ");
		deparseRoleSpec(str, create_table_space_stmt->owner);
		appendStringInfoChar(str, ' ');
	}

	appendStringInfoString(str, "LOCATION ");

	if (create_table_space_stmt->location != NULL)
		deparseStringLiteral(str, create_table_space_stmt->location);
	else
		appendStringInfoString(str, "''");

	appendStringInfoChar(str, ' ');

	deparseOptWith(str, create_table_space_stmt->options);

	removeTrailingSpace(str);
}

static void deparseCreateTransformStmt(StringInfo str, CreateTransformStmt *create_transform_stmt)
{
	appendStringInfoString(str, "CREATE ");
	if (create_transform_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");

	appendStringInfoString(str, "TRANSFORM FOR ");
	deparseTypeName(str, create_transform_stmt->type_name);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "LANGUAGE ");
	appendStringInfoString(str, quote_identifier(create_transform_stmt->lang));
	appendStringInfoChar(str, ' ');

	appendStringInfoChar(str, '(');

	if (create_transform_stmt->fromsql)
	{
		appendStringInfoString(str, "FROM SQL WITH FUNCTION ");
		deparseFunctionWithArgtypes(str, create_transform_stmt->fromsql);
	}

	if (create_transform_stmt->fromsql && create_transform_stmt->tosql)
		appendStringInfoString(str, ", ");

	if (create_transform_stmt->tosql)
	{
		appendStringInfoString(str, "TO SQL WITH FUNCTION ");
		deparseFunctionWithArgtypes(str, create_transform_stmt->tosql);
	}

	appendStringInfoChar(str, ')');
}

static void deparseCreateAmStmt(StringInfo str, CreateAmStmt *create_am_stmt)
{
	appendStringInfoString(str, "CREATE ACCESS METHOD ");
	appendStringInfoString(str, quote_identifier(create_am_stmt->amname));
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "TYPE ");
	switch (create_am_stmt->amtype)
	{
		case AMTYPE_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case AMTYPE_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
	}

	appendStringInfoString(str, "HANDLER ");
	deparseHandlerName(str, create_am_stmt->handler_name);
}

static void deparsePublicationObjectList(StringInfo str, List *pubobjects) {
	const ListCell *lc;
	foreach(lc, pubobjects) {
		PublicationObjSpec *obj = lfirst(lc);

		switch (obj->pubobjtype) {
			case PUBLICATIONOBJ_TABLE:
				appendStringInfoString(str, "TABLE ");
				deparseRangeVar(str, obj->pubtable->relation, DEPARSE_NODE_CONTEXT_NONE);
				
				if (obj->pubtable->columns)
				{
					appendStringInfoChar(str, '(');
					deparseColumnList(str, obj->pubtable->columns);
					appendStringInfoChar(str, ')');
				}

				if (obj->pubtable->whereClause)
				{
					appendStringInfoString(str, " WHERE (");
					deparseExpr(str, obj->pubtable->whereClause);
					appendStringInfoString(str, ")");
				}

				break;
			case PUBLICATIONOBJ_TABLES_IN_SCHEMA:
				appendStringInfoString(str, "TABLES IN SCHEMA ");
				appendStringInfoString(str, quote_identifier(obj->name));
				break;
			case PUBLICATIONOBJ_TABLES_IN_CUR_SCHEMA:
				appendStringInfoString(str, "TABLES IN SCHEMA CURRENT_SCHEMA");
				break;
			case PUBLICATIONOBJ_CONTINUATION:
				// This should be unreachable, the parser merges these before we can even get here.
				Assert(false);
				break;
		}
		
		if (lnext(pubobjects, lc)) {
			appendStringInfoString(str, ", ");
		}
	}
}

static void deparseCreatePublicationStmt(StringInfo str, CreatePublicationStmt *create_publication_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "CREATE PUBLICATION ");
	appendStringInfoString(str, quote_identifier(create_publication_stmt->pubname));
	appendStringInfoChar(str, ' ');

	if (list_length(create_publication_stmt->pubobjects) > 0)
	{
		appendStringInfoString(str, "FOR ");
		deparsePublicationObjectList(str, create_publication_stmt->pubobjects);
		appendStringInfoChar(str, ' ');
	}
	else if (create_publication_stmt->for_all_tables)
	{
		appendStringInfoString(str, "FOR ALL TABLES ");
	}

	deparseOptDefinition(str, create_publication_stmt->options);
	removeTrailingSpace(str);
}

static void deparseAlterPublicationStmt(StringInfo str, AlterPublicationStmt *alter_publication_stmt)
{
	appendStringInfoString(str, "ALTER PUBLICATION ");
	deparseColId(str, alter_publication_stmt->pubname);
	appendStringInfoChar(str, ' ');

	if (list_length(alter_publication_stmt->pubobjects) > 0)
	{
		switch (alter_publication_stmt->action)
		{
			case AP_SetObjects:
				appendStringInfoString(str, "SET ");
				break;
			case AP_AddObjects:
				appendStringInfoString(str, "ADD ");
				break;
			case AP_DropObjects:
				appendStringInfoString(str, "DROP ");
				break;
		}

		deparsePublicationObjectList(str, alter_publication_stmt->pubobjects);
	}
	else if (list_length(alter_publication_stmt->options) > 0)
	{
		appendStringInfoString(str, "SET ");
		deparseDefinition(str, alter_publication_stmt->options);
	}
	else
	{
		Assert(false);
	}
}

static void deparseAlterSeqStmt(StringInfo str, AlterSeqStmt *alter_seq_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER SEQUENCE ");

	if (alter_seq_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	deparseRangeVar(str, alter_seq_stmt->sequence, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	deparseSeqOptList(str, alter_seq_stmt->options);

	removeTrailingSpace(str);
}

static void deparseAlterSystemStmt(StringInfo str, AlterSystemStmt *alter_system_stmt)
{
	appendStringInfoString(str, "ALTER SYSTEM ");
	deparseVariableSetStmt(str, alter_system_stmt->setstmt);
}

static void deparseCommentStmt(StringInfo str, CommentStmt *comment_stmt)
{
	ListCell *lc;
	List *l;

	appendStringInfoString(str, "COMMENT ON ");

	switch (comment_stmt->objtype)
	{
		case OBJECT_COLUMN:
			appendStringInfoString(str, "COLUMN ");
			break;
		case OBJECT_INDEX:
			appendStringInfoString(str, "INDEX ");
			break;
		case OBJECT_SEQUENCE:
			appendStringInfoString(str, "SEQUENCE ");
			break;
		case OBJECT_STATISTIC_EXT:
			appendStringInfoString(str, "STATISTICS ");
			break;
		case OBJECT_TABLE:
			appendStringInfoString(str, "TABLE ");
			break;
		case OBJECT_VIEW:
			appendStringInfoString(str, "VIEW ");
			break;
		case OBJECT_MATVIEW:
			appendStringInfoString(str, "MATERIALIZED VIEW ");
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			break;
		case OBJECT_FOREIGN_TABLE:
			appendStringInfoString(str, "FOREIGN TABLE ");
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			break;
		case OBJECT_TSPARSER:
			appendStringInfoString(str, "TEXT SEARCH PARSER ");
			break;
		case OBJECT_TSTEMPLATE:
			appendStringInfoString(str, "TEXT SEARCH TEMPLATE ");
			break;
		case OBJECT_ACCESS_METHOD:
			appendStringInfoString(str, "ACCESS METHOD ");
			break;
		case OBJECT_DATABASE:
			appendStringInfoString(str, "DATABASE ");
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			break;
		case OBJECT_EXTENSION:
			appendStringInfoString(str, "EXTENSION ");
			break;
		case OBJECT_FDW:
			appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			break;
		case OBJECT_PUBLICATION:
			appendStringInfoString(str, "PUBLICATION ");
			break;
		case OBJECT_ROLE:
			appendStringInfoString(str, "ROLE ");
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			break;
		case OBJECT_FOREIGN_SERVER:
			appendStringInfoString(str, "SERVER ");
			break;
		case OBJECT_SUBSCRIPTION:
			appendStringInfoString(str, "SUBSCRIPTION ");
			break;
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, "TABLESPACE ");
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			break;
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			break;
		case OBJECT_TABCONSTRAINT:
			appendStringInfoString(str, "CONSTRAINT ");
			break;
		case OBJECT_DOMCONSTRAINT:
			appendStringInfoString(str, "CONSTRAINT ");
			break;
		case OBJECT_POLICY:
			appendStringInfoString(str, "POLICY ");
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			break;
		case OBJECT_RULE:
			appendStringInfoString(str, "RULE ");
			break;
		case OBJECT_TRANSFORM:
			appendStringInfoString(str, "TRANSFORM ");
			break;
		case OBJECT_TRIGGER:
			appendStringInfoString(str, "TRIGGER ");
			break;
		case OBJECT_OPCLASS:
			appendStringInfoString(str, "OPERATOR CLASS ");
			break;
		case OBJECT_OPFAMILY:
			appendStringInfoString(str, "OPERATOR FAMILY ");
			break;
		case OBJECT_LARGEOBJECT:
			appendStringInfoString(str, "LARGE OBJECT ");
			break;
		case OBJECT_CAST:
			appendStringInfoString(str, "CAST ");
			break;
		default:
			// No other cases are supported in the parser
			Assert(false);
			break;
	}

	switch (comment_stmt->objtype)
	{
		case OBJECT_COLUMN:
		case OBJECT_INDEX:
		case OBJECT_SEQUENCE:
		case OBJECT_STATISTIC_EXT:
		case OBJECT_TABLE:
		case OBJECT_VIEW:
		case OBJECT_MATVIEW:
		case OBJECT_COLLATION:
		case OBJECT_CONVERSION:
		case OBJECT_FOREIGN_TABLE:
		case OBJECT_TSCONFIGURATION:
		case OBJECT_TSDICTIONARY:
		case OBJECT_TSPARSER:
		case OBJECT_TSTEMPLATE:
			deparseAnyName(str, castNode(List, comment_stmt->object));
			break;
		case OBJECT_ACCESS_METHOD:
		case OBJECT_DATABASE:
		case OBJECT_EVENT_TRIGGER:
		case OBJECT_EXTENSION:
		case OBJECT_FDW:
		case OBJECT_LANGUAGE:
		case OBJECT_PUBLICATION:
		case OBJECT_ROLE:
		case OBJECT_SCHEMA:
		case OBJECT_FOREIGN_SERVER:
		case OBJECT_SUBSCRIPTION:
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, quote_identifier(strVal(comment_stmt->object)));
			break;
		case OBJECT_TYPE:
		case OBJECT_DOMAIN:
			deparseTypeName(str, castNode(TypeName, comment_stmt->object));
			break;
		case OBJECT_AGGREGATE:
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, comment_stmt->object));
			break;
		case OBJECT_FUNCTION:
		case OBJECT_PROCEDURE:
		case OBJECT_ROUTINE:
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, comment_stmt->object));
			break;
		case OBJECT_OPERATOR:
			deparseOperatorWithArgtypes(str, castNode(ObjectWithArgs, comment_stmt->object));
			break;
		case OBJECT_TABCONSTRAINT:
		case OBJECT_POLICY:
		case OBJECT_RULE:
		case OBJECT_TRIGGER:
			l = castNode(List, comment_stmt->object);
			appendStringInfoString(str, quote_identifier(strVal(llast(l))));
			appendStringInfoString(str, " ON ");
			deparseAnyNameSkipLast(str, l);
			break;
		case OBJECT_DOMCONSTRAINT:
			l = castNode(List, comment_stmt->object);
			appendStringInfoString(str, quote_identifier(strVal(llast(l))));
			appendStringInfoString(str, " ON DOMAIN ");
			deparseTypeName(str, linitial(l));
			break;
		case OBJECT_TRANSFORM:
			l = castNode(List, comment_stmt->object);
			appendStringInfoString(str, "FOR ");
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " LANGUAGE ");
			appendStringInfoString(str, quote_identifier(strVal(lsecond(l))));
			break;
		case OBJECT_OPCLASS:
		case OBJECT_OPFAMILY:
			l = castNode(List, comment_stmt->object);
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			appendStringInfoString(str, quote_identifier(strVal(linitial(l))));
			break;
		case OBJECT_LARGEOBJECT:
			deparseValue(str, (union ValUnion *) comment_stmt->object, DEPARSE_NODE_CONTEXT_NONE);
			break;
		case OBJECT_CAST:
			l = castNode(List, comment_stmt->object);
			appendStringInfoChar(str, '(');
			deparseTypeName(str, castNode(TypeName, linitial(l)));
			appendStringInfoString(str, " AS ");
			deparseTypeName(str, castNode(TypeName, lsecond(l)));
			appendStringInfoChar(str, ')');
			break;
		default:
			// No other cases are supported in the parser
			Assert(false);
			break;
	}

	appendStringInfoString(str, " IS ");

	if (comment_stmt->comment != NULL)
		deparseStringLiteral(str, comment_stmt->comment);
	else
		appendStringInfoString(str, "NULL");
}

static void deparseStatsElem(StringInfo str, StatsElem *stats_elem)
{
	// only one of stats_elem->name or stats_elem->expr can be non-null
	if (stats_elem->name)
		appendStringInfoString(str, stats_elem->name);
	else if (stats_elem->expr)
	{
		appendStringInfoChar(str, '(');
		deparseExpr(str, stats_elem->expr);
		appendStringInfoChar(str, ')');
	}
}

static void deparseCreateStatsStmt(StringInfo str, CreateStatsStmt *create_stats_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE STATISTICS ");

	if (create_stats_stmt->if_not_exists)
		appendStringInfoString(str, "IF NOT EXISTS ");

	deparseAnyName(str, create_stats_stmt->defnames);
	appendStringInfoChar(str, ' ');

	if (list_length(create_stats_stmt->stat_types) > 0)
	{
		appendStringInfoChar(str, '(');
		deparseNameList(str, create_stats_stmt->stat_types);
		appendStringInfoString(str, ") ");
	}

	appendStringInfoString(str, "ON ");
	foreach (lc, create_stats_stmt->exprs)
	{
		deparseStatsElem(str, lfirst(lc));
		if (lnext(create_stats_stmt->exprs, lc))
			appendStringInfoString(str, ", ");
	}

	appendStringInfoString(str, " FROM ");
	deparseFromList(str, create_stats_stmt->relations);
}

static void deparseAlterCollationStmt(StringInfo str, AlterCollationStmt *alter_collation_stmt)
{
	appendStringInfoString(str, "ALTER COLLATION ");
	deparseAnyName(str, alter_collation_stmt->collname);
	appendStringInfoString(str, " REFRESH VERSION");
}

static void deparseAlterDatabaseStmt(StringInfo str, AlterDatabaseStmt *alter_database_stmt)
{
	appendStringInfoString(str, "ALTER DATABASE ");
	deparseColId(str, alter_database_stmt->dbname);
	appendStringInfoChar(str, ' ');
	deparseCreatedbOptList(str, alter_database_stmt->options);
	removeTrailingSpace(str);
}

static void deparseAlterDatabaseSetStmt(StringInfo str, AlterDatabaseSetStmt *alter_database_set_stmt)
{
	appendStringInfoString(str, "ALTER DATABASE ");
	deparseColId(str, alter_database_set_stmt->dbname);
	appendStringInfoChar(str, ' ');
	deparseVariableSetStmt(str, alter_database_set_stmt->setstmt);
}

static void deparseAlterStatsStmt(StringInfo str, AlterStatsStmt *alter_stats_stmt)
{
	appendStringInfoString(str, "ALTER STATISTICS ");

	if (alter_stats_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	deparseAnyName(str, alter_stats_stmt->defnames);
	appendStringInfoChar(str, ' ');

	appendStringInfo(str, "SET STATISTICS %d", alter_stats_stmt->stxstattarget);
}

static void deparseAlterTSDictionaryStmt(StringInfo str, AlterTSDictionaryStmt *alter_ts_dictionary_stmt)
{
	appendStringInfoString(str, "ALTER TEXT SEARCH DICTIONARY ");

	deparseAnyName(str, alter_ts_dictionary_stmt->dictname);
	appendStringInfoChar(str, ' ');

	deparseDefinition(str, alter_ts_dictionary_stmt->options);
}

static void deparseAlterTSConfigurationStmt(StringInfo str, AlterTSConfigurationStmt *alter_ts_configuration_stmt)
{
	ListCell *lc = NULL;

	appendStringInfoString(str, "ALTER TEXT SEARCH CONFIGURATION ");
	deparseAnyName(str, alter_ts_configuration_stmt->cfgname);
	appendStringInfoChar(str, ' ');

	switch (alter_ts_configuration_stmt->kind)
	{
		case ALTER_TSCONFIG_ADD_MAPPING:
			appendStringInfoString(str, "ADD MAPPING FOR ");
			deparseNameList(str, alter_ts_configuration_stmt->tokentype);
			appendStringInfoString(str, " WITH ");
			deparseAnyNameList(str, alter_ts_configuration_stmt->dicts);
			break;
		case ALTER_TSCONFIG_ALTER_MAPPING_FOR_TOKEN:
			appendStringInfoString(str, "ALTER MAPPING FOR ");
			deparseNameList(str, alter_ts_configuration_stmt->tokentype);
			appendStringInfoString(str, " WITH ");
			deparseAnyNameList(str, alter_ts_configuration_stmt->dicts);
			break;
		case ALTER_TSCONFIG_REPLACE_DICT:
			appendStringInfoString(str, "ALTER MAPPING REPLACE ");
			deparseAnyName(str, linitial(alter_ts_configuration_stmt->dicts));
			appendStringInfoString(str, " WITH ");
			deparseAnyName(str, lsecond(alter_ts_configuration_stmt->dicts));
			break;
		case ALTER_TSCONFIG_REPLACE_DICT_FOR_TOKEN:
			appendStringInfoString(str, "ALTER MAPPING FOR ");
			deparseNameList(str, alter_ts_configuration_stmt->tokentype);
			appendStringInfoString(str, " REPLACE ");
			deparseAnyName(str, linitial(alter_ts_configuration_stmt->dicts));
			appendStringInfoString(str, " WITH ");
			deparseAnyName(str, lsecond(alter_ts_configuration_stmt->dicts));
			break;
		case ALTER_TSCONFIG_DROP_MAPPING:
			appendStringInfoString(str, "DROP MAPPING ");
			if (alter_ts_configuration_stmt->missing_ok)
				appendStringInfoString(str, "IF EXISTS ");
			appendStringInfoString(str, "FOR ");
			deparseNameList(str, alter_ts_configuration_stmt->tokentype);
			break;
	}
}

static void deparseVariableShowStmt(StringInfo str, VariableShowStmt *variable_show_stmt)
{
	appendStringInfoString(str, "SHOW ");

	if (strcmp(variable_show_stmt->name, "timezone") == 0)
		appendStringInfoString(str, "TIME ZONE");
	else if (strcmp(variable_show_stmt->name, "transaction_isolation") == 0)
		appendStringInfoString(str, "TRANSACTION ISOLATION LEVEL");
	else if (strcmp(variable_show_stmt->name, "session_authorization") == 0)
		appendStringInfoString(str, "SESSION AUTHORIZATION");
	else if (strcmp(variable_show_stmt->name, "all") == 0)
		appendStringInfoString(str, "ALL");
	else
		appendStringInfoString(str, quote_identifier(variable_show_stmt->name));
}

static void deparseRangeTableSample(StringInfo str, RangeTableSample *range_table_sample)
{
	deparseRangeVar(str, castNode(RangeVar, range_table_sample->relation), DEPARSE_NODE_CONTEXT_NONE);

	appendStringInfoString(str, " TABLESAMPLE ");

	deparseFuncName(str, range_table_sample->method);
	appendStringInfoChar(str, '(');
	deparseExprList(str, range_table_sample->args);
	appendStringInfoString(str, ") ");

	if (range_table_sample->repeatable != NULL)
	{
		appendStringInfoString(str, "REPEATABLE (");
		deparseExpr(str, range_table_sample->repeatable);
		appendStringInfoString(str, ") ");
	}

	removeTrailingSpace(str);
}

static void deparseCreateSubscriptionStmt(StringInfo str, CreateSubscriptionStmt *create_subscription_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "CREATE SUBSCRIPTION ");
	appendStringInfoString(str, quote_identifier(create_subscription_stmt->subname));

	appendStringInfoString(str, " CONNECTION ");
	if (create_subscription_stmt->conninfo != NULL)
		deparseStringLiteral(str, create_subscription_stmt->conninfo);
	else
		appendStringInfoString(str, "''");

	appendStringInfoString(str, " PUBLICATION ");

	foreach(lc, create_subscription_stmt->publication)
	{
		deparseColLabel(str, strVal(lfirst(lc)));
		if (lnext(create_subscription_stmt->publication, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ' ');

	deparseOptDefinition(str, create_subscription_stmt->options);
	removeTrailingSpace(str);
}

static void deparseAlterSubscriptionStmt(StringInfo str, AlterSubscriptionStmt *alter_subscription_stmt)
{
	ListCell *lc;

	appendStringInfoString(str, "ALTER SUBSCRIPTION ");
	appendStringInfoString(str, quote_identifier(alter_subscription_stmt->subname));
	appendStringInfoChar(str, ' ');

	switch (alter_subscription_stmt->kind)
	{
		case ALTER_SUBSCRIPTION_OPTIONS:
			appendStringInfoString(str, "SET ");
			deparseDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_SKIP:
			appendStringInfoString(str, "SKIP ");
			deparseDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_CONNECTION:
			appendStringInfoString(str, "CONNECTION ");
			deparseStringLiteral(str, alter_subscription_stmt->conninfo);
			appendStringInfoChar(str, ' ');
			break;
		case ALTER_SUBSCRIPTION_REFRESH:
			appendStringInfoString(str, "REFRESH PUBLICATION ");
			deparseOptDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_ADD_PUBLICATION:
			appendStringInfoString(str, "ADD PUBLICATION ");
			foreach(lc, alter_subscription_stmt->publication)
			{
				deparseColLabel(str, strVal(lfirst(lc)));
				if (lnext(alter_subscription_stmt->publication, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			deparseOptDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_DROP_PUBLICATION:
			appendStringInfoString(str, "DROP PUBLICATION ");
			foreach(lc, alter_subscription_stmt->publication)
			{
				deparseColLabel(str, strVal(lfirst(lc)));
				if (lnext(alter_subscription_stmt->publication, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			deparseOptDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_SET_PUBLICATION:
			appendStringInfoString(str, "SET PUBLICATION ");
			foreach(lc, alter_subscription_stmt->publication)
			{
				deparseColLabel(str, strVal(lfirst(lc)));
				if (lnext(alter_subscription_stmt->publication, lc))
					appendStringInfoString(str, ", ");
			}
			appendStringInfoChar(str, ' ');
			deparseOptDefinition(str, alter_subscription_stmt->options);
			break;
		case ALTER_SUBSCRIPTION_ENABLED:
			Assert(list_length(alter_subscription_stmt->options) == 1);
			DefElem *defelem = castNode(DefElem, linitial(alter_subscription_stmt->options));
			Assert(strcmp(defelem->defname, "enabled") == 0);
			if (optBooleanValue(defelem->arg))
			{
				appendStringInfoString(str, " ENABLE ");
			}
			else
			{
				appendStringInfoString(str, " DISABLE ");
			}
			break;
	}
	
	removeTrailingSpace(str);
}

static void deparseDropSubscriptionStmt(StringInfo str, DropSubscriptionStmt *drop_subscription_stmt)
{
	appendStringInfoString(str, "DROP SUBSCRIPTION ");

	if (drop_subscription_stmt->missing_ok)
		appendStringInfoString(str, "IF EXISTS ");

	appendStringInfoString(str, drop_subscription_stmt->subname);
}

static void deparseCallStmt(StringInfo str, CallStmt *call_stmt)
{
	appendStringInfoString(str, "CALL ");
	deparseFuncCall(str, call_stmt->funccall);
}

static void deparseAlterOwnerStmt(StringInfo str, AlterOwnerStmt *alter_owner_stmt)
{
	List *l = NULL;

	appendStringInfoString(str, "ALTER ");

	switch (alter_owner_stmt->objectType)
	{
		case OBJECT_AGGREGATE:
			appendStringInfoString(str, "AGGREGATE ");
			deparseAggregateWithArgtypes(str, castNode(ObjectWithArgs, alter_owner_stmt->object));
			break;
		case OBJECT_COLLATION:
			appendStringInfoString(str, "COLLATION ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_CONVERSION:
			appendStringInfoString(str, "CONVERSION ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_DATABASE:
			appendStringInfoString(str, "DATABASE ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_DOMAIN:
			appendStringInfoString(str, "DOMAIN ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_FUNCTION:
			appendStringInfoString(str, "FUNCTION ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_owner_stmt->object));
			break;
		case OBJECT_LANGUAGE:
			appendStringInfoString(str, "LANGUAGE ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_LARGEOBJECT:
			appendStringInfoString(str, "LARGE OBJECT ");
			deparseNumericOnly(str, (union ValUnion *) alter_owner_stmt->object);
			break;
		case OBJECT_OPERATOR:
			appendStringInfoString(str, "OPERATOR ");
			deparseOperatorWithArgtypes(str, castNode(ObjectWithArgs, alter_owner_stmt->object));
			break;
		case OBJECT_OPCLASS:
			l = castNode(List, alter_owner_stmt->object);
			appendStringInfoString(str, "OPERATOR CLASS ");
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			deparseColId(str, strVal(linitial(l)));
			break;
		case OBJECT_OPFAMILY:
			l = castNode(List, alter_owner_stmt->object);
			appendStringInfoString(str, "OPERATOR FAMILY ");
			deparseAnyNameSkipFirst(str, l);
			appendStringInfoString(str, " USING ");
			deparseColId(str, strVal(linitial(l)));
			break;
		case OBJECT_PROCEDURE:
			appendStringInfoString(str, "PROCEDURE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_owner_stmt->object));
			break;
		case OBJECT_ROUTINE:
			appendStringInfoString(str, "ROUTINE ");
			deparseFunctionWithArgtypes(str, castNode(ObjectWithArgs, alter_owner_stmt->object));
			break;
		case OBJECT_SCHEMA:
			appendStringInfoString(str, "SCHEMA ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_TYPE:
			appendStringInfoString(str, "TYPE ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_TABLESPACE:
			appendStringInfoString(str, "TABLESPACE ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_STATISTIC_EXT:
			appendStringInfoString(str, "STATISTICS ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_TSDICTIONARY:
			appendStringInfoString(str, "TEXT SEARCH DICTIONARY ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_TSCONFIGURATION:
			appendStringInfoString(str, "TEXT SEARCH CONFIGURATION ");
			deparseAnyName(str, castNode(List, alter_owner_stmt->object));
			break;
		case OBJECT_FDW:
			appendStringInfoString(str, "FOREIGN DATA WRAPPER ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_FOREIGN_SERVER:
			appendStringInfoString(str, "SERVER ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_EVENT_TRIGGER:
			appendStringInfoString(str, "EVENT TRIGGER ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_PUBLICATION:
			appendStringInfoString(str, "PUBLICATION ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		case OBJECT_SUBSCRIPTION:
			appendStringInfoString(str, "SUBSCRIPTION ");
			deparseColId(str, strVal(alter_owner_stmt->object));
			break;
		default:
			Assert(false);
	}

	appendStringInfoString(str, " OWNER TO ");
	deparseRoleSpec(str, alter_owner_stmt->newowner);
}

// "operator_def_list" in gram.y
static void deparseOperatorDefList(StringInfo str, List *defs)
{
	ListCell *lc = NULL;

	foreach (lc, defs)
	{
		DefElem *def_elem = castNode(DefElem, lfirst(lc));
		appendStringInfoString(str, quote_identifier(def_elem->defname));
		appendStringInfoString(str, " = ");
		if (def_elem->arg != NULL)
			deparseDefArg(str, def_elem->arg, true);
		else
			appendStringInfoString(str, "NONE");

		if (lnext(defs, lc))
			appendStringInfoString(str, ", ");
	}
}

static void deparseAlterOperatorStmt(StringInfo str, AlterOperatorStmt *alter_operator_stmt)
{
	appendStringInfoString(str, "ALTER OPERATOR ");
	deparseOperatorWithArgtypes(str, alter_operator_stmt->opername);
	appendStringInfoString(str, " SET (");
	deparseOperatorDefList(str, alter_operator_stmt->options);
	appendStringInfoChar(str, ')');
}

static void deparseAlterTypeStmt(StringInfo str, AlterTypeStmt *alter_type_stmt)
{
	appendStringInfoString(str, "ALTER TYPE ");
	deparseAnyName(str, alter_type_stmt->typeName);
	appendStringInfoString(str, " SET (");
	deparseOperatorDefList(str, alter_type_stmt->options);
	appendStringInfoChar(str, ')');
}

static void deparseDropOwnedStmt(StringInfo str, DropOwnedStmt *drop_owned_stmt)
{
	appendStringInfoString(str, "DROP OWNED BY ");
	deparseRoleList(str, drop_owned_stmt->roles);
	appendStringInfoChar(str, ' ');
	deparseOptDropBehavior(str, drop_owned_stmt->behavior);
	removeTrailingSpace(str);
}

static void deparseReassignOwnedStmt(StringInfo str, ReassignOwnedStmt *reassigned_owned_stmt)
{
	appendStringInfoString(str, "REASSIGN OWNED BY ");

	deparseRoleList(str, reassigned_owned_stmt->roles);
	appendStringInfoChar(str, ' ');

	appendStringInfoString(str, "TO ");
	deparseRoleSpec(str, reassigned_owned_stmt->newrole);
}

static void deparseClosePortalStmt(StringInfo str, ClosePortalStmt *close_portal_stmt)
{
	appendStringInfoString(str, "CLOSE ");
	if (close_portal_stmt->portalname != NULL)
	{
		appendStringInfoString(str, quote_identifier(close_portal_stmt->portalname));
	}
	else
	{
		appendStringInfoString(str, "ALL");
	}
}

static void deparseCurrentOfExpr(StringInfo str, CurrentOfExpr *current_of_expr)
{
	appendStringInfoString(str, "CURRENT OF ");
	appendStringInfoString(str, quote_identifier(current_of_expr->cursor_name));
}

static void deparseCreateTrigStmt(StringInfo str, CreateTrigStmt *create_trig_stmt)
{
	ListCell *lc;
	bool skip_events_or = true;

	appendStringInfoString(str, "CREATE ");
	if (create_trig_stmt->replace)
		appendStringInfoString(str, "OR REPLACE ");
	if (create_trig_stmt->isconstraint)
		appendStringInfoString(str, "CONSTRAINT ");
	appendStringInfoString(str, "TRIGGER ");

	appendStringInfoString(str, quote_identifier(create_trig_stmt->trigname));
	appendStringInfoChar(str, ' ');

	switch (create_trig_stmt->timing)
	{
		case TRIGGER_TYPE_BEFORE:
			appendStringInfoString(str, "BEFORE ");
			break;
		case TRIGGER_TYPE_AFTER:
			appendStringInfoString(str, "AFTER ");
			break;
		case TRIGGER_TYPE_INSTEAD:
			appendStringInfoString(str, "INSTEAD OF ");
			break;
		default:
			Assert(false);
	}

	if (TRIGGER_FOR_INSERT(create_trig_stmt->events))
	{
		appendStringInfoString(str, "INSERT ");
		skip_events_or = false;
	}
	if (TRIGGER_FOR_DELETE(create_trig_stmt->events))
	{
		if (!skip_events_or)
			appendStringInfoString(str, "OR ");
		appendStringInfoString(str, "DELETE ");
		skip_events_or = false;
	}
	if (TRIGGER_FOR_UPDATE(create_trig_stmt->events))
	{
		if (!skip_events_or)
			appendStringInfoString(str, "OR ");
		appendStringInfoString(str, "UPDATE ");
		if (list_length(create_trig_stmt->columns) > 0)
		{
			appendStringInfoString(str, "OF ");
			deparseColumnList(str, create_trig_stmt->columns);
			appendStringInfoChar(str, ' ');
		}
		skip_events_or = false;
	}
	if (TRIGGER_FOR_TRUNCATE(create_trig_stmt->events))
	{
		if (!skip_events_or)
			appendStringInfoString(str, "OR ");
		appendStringInfoString(str, "TRUNCATE ");
	}

	appendStringInfoString(str, "ON ");
	deparseRangeVar(str, create_trig_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
	appendStringInfoChar(str, ' ');

	if (create_trig_stmt->transitionRels != NULL)
	{
		appendStringInfoString(str, "REFERENCING ");
		foreach(lc, create_trig_stmt->transitionRels)
		{
			deparseTriggerTransition(str, castNode(TriggerTransition, lfirst(lc)));
			appendStringInfoChar(str, ' ');
		}
	}

	if (create_trig_stmt->constrrel != NULL)
	{
		appendStringInfoString(str, "FROM ");
		deparseRangeVar(str, create_trig_stmt->constrrel, DEPARSE_NODE_CONTEXT_NONE);
		appendStringInfoChar(str, ' ');
	}
	
	if (create_trig_stmt->deferrable)
		appendStringInfoString(str, "DEFERRABLE ");

	if (create_trig_stmt->initdeferred)
		appendStringInfoString(str, "INITIALLY DEFERRED ");

	if (create_trig_stmt->row)
		appendStringInfoString(str, "FOR EACH ROW ");

	if (create_trig_stmt->whenClause)
	{
		appendStringInfoString(str, "WHEN (");
		deparseExpr(str, create_trig_stmt->whenClause);
		appendStringInfoString(str, ") ");
	}

	appendStringInfoString(str, "EXECUTE FUNCTION ");
	deparseFuncName(str, create_trig_stmt->funcname);
	appendStringInfoChar(str, '(');
	foreach(lc, create_trig_stmt->args)
	{
		deparseStringLiteral(str, strVal(lfirst(lc)));
		if (lnext(create_trig_stmt->args, lc))
			appendStringInfoString(str, ", ");
	}
	appendStringInfoChar(str, ')');
}

static void deparseTriggerTransition(StringInfo str, TriggerTransition *trigger_transition)
{
	if (trigger_transition->isNew)
		appendStringInfoString(str, "NEW ");
	else
		appendStringInfoString(str, "OLD ");

	if (trigger_transition->isTable)
		appendStringInfoString(str, "TABLE ");
	else
		appendStringInfoString(str, "ROW ");

	appendStringInfoString(str, quote_identifier(trigger_transition->name));
}

static void deparseXmlExpr(StringInfo str, XmlExpr* xml_expr)
{
	switch (xml_expr->op)
	{
		case IS_XMLCONCAT: /* XMLCONCAT(args) */
			appendStringInfoString(str, "xmlconcat(");
			deparseExprList(str, xml_expr->args);
			appendStringInfoChar(str, ')');
			break;
		case IS_XMLELEMENT: /* XMLELEMENT(name, xml_attributes, args) */
			appendStringInfoString(str, "xmlelement(name ");
			appendStringInfoString(str, quote_identifier(xml_expr->name));
			if (xml_expr->named_args != NULL)
			{
				appendStringInfoString(str, ", xmlattributes(");
				deparseXmlAttributeList(str, xml_expr->named_args);
				appendStringInfoString(str, ")");
			}
			if (xml_expr->args != NULL)
			{
				appendStringInfoString(str, ", ");
				deparseExprList(str, xml_expr->args);
			}
			appendStringInfoString(str, ")");
			break;
		case IS_XMLFOREST: /* XMLFOREST(xml_attributes) */
			appendStringInfoString(str, "xmlforest(");
			deparseXmlAttributeList(str, xml_expr->named_args);
			appendStringInfoChar(str, ')');
			break;
		case IS_XMLPARSE: /* XMLPARSE(text, is_doc, preserve_ws) */
			Assert(list_length(xml_expr->args) == 2);
			appendStringInfoString(str, "xmlparse(");
			switch (xml_expr->xmloption)
			{
				case XMLOPTION_DOCUMENT:
					appendStringInfoString(str, "document ");
					break;
				case XMLOPTION_CONTENT:
					appendStringInfoString(str, "content ");
					break;
				default:
					Assert(false);
			}
			deparseExpr(str, linitial(xml_expr->args));
			appendStringInfoChar(str, ')');
			break;
		case IS_XMLPI: /* XMLPI(name [, args]) */
			appendStringInfoString(str, "xmlpi(name ");
			appendStringInfoString(str, quote_identifier(xml_expr->name));
			if (xml_expr->args != NULL)
			{
				appendStringInfoString(str, ", ");
				deparseExpr(str, linitial(xml_expr->args));
			}
			appendStringInfoChar(str, ')');
			break;
		case IS_XMLROOT: /* XMLROOT(xml, version, standalone) */
			appendStringInfoString(str, "xmlroot(");
			deparseExpr(str, linitial(xml_expr->args));
			appendStringInfoString(str, ", version ");
			if (castNode(A_Const, lsecond(xml_expr->args))->isnull)
				appendStringInfoString(str, "NO VALUE");
			else
				deparseExpr(str, lsecond(xml_expr->args));
			if (intVal(&castNode(A_Const, lthird(xml_expr->args))->val) == XML_STANDALONE_YES)
				appendStringInfoString(str, ", STANDALONE YES");
			else if (intVal(&castNode(A_Const, lthird(xml_expr->args))->val) == XML_STANDALONE_NO)
				appendStringInfoString(str, ", STANDALONE NO");
			else if (intVal(&castNode(A_Const, lthird(xml_expr->args))->val) == XML_STANDALONE_NO_VALUE)
				appendStringInfoString(str, ", STANDALONE NO VALUE");
			appendStringInfoChar(str, ')');
			break;
		case IS_XMLSERIALIZE: /* XMLSERIALIZE(is_document, xmlval) */
			// These are represented as XmlSerialize in raw parse trees
			Assert(false);
			break;
		case IS_DOCUMENT: /* xmlval IS DOCUMENT */
			Assert(list_length(xml_expr->args) == 1);
			deparseExpr(str, linitial(xml_expr->args));
			appendStringInfoString(str, " IS DOCUMENT");
			break;
	}
}

static void deparseRangeTableFuncCol(StringInfo str, RangeTableFuncCol* range_table_func_col)
{
	appendStringInfoString(str, quote_identifier(range_table_func_col->colname));
	appendStringInfoChar(str, ' ');

	if (range_table_func_col->for_ordinality)
	{
		appendStringInfoString(str, "FOR ORDINALITY ");
	}
	else
	{
		deparseTypeName(str, range_table_func_col->typeName);
		appendStringInfoChar(str, ' ');

		if (range_table_func_col->colexpr)
		{
			appendStringInfoString(str, "PATH ");
			deparseExpr(str, range_table_func_col->colexpr);
			appendStringInfoChar(str, ' ');
		}

		if (range_table_func_col->coldefexpr)
		{
			appendStringInfoString(str, "DEFAULT ");
			deparseExpr(str, range_table_func_col->coldefexpr);
			appendStringInfoChar(str, ' ');
		}

		if (range_table_func_col->is_not_null)
			appendStringInfoString(str, "NOT NULL ");
	}

	removeTrailingSpace(str);
}

static void deparseRangeTableFunc(StringInfo str, RangeTableFunc* range_table_func)
{
	ListCell *lc;

	if (range_table_func->lateral)
		appendStringInfoString(str, "LATERAL ");
	
	appendStringInfoString(str, "xmltable(");
	if (range_table_func->namespaces)
	{
		appendStringInfoString(str, "xmlnamespaces(");
		deparseXmlNamespaceList(str, range_table_func->namespaces);
		appendStringInfoString(str, "), ");
	}

	appendStringInfoChar(str, '(');
	deparseExpr(str, range_table_func->rowexpr);
	appendStringInfoChar(str, ')');

	appendStringInfoString(str, " PASSING ");
	deparseExpr(str, range_table_func->docexpr);

	appendStringInfoString(str, " COLUMNS ");
	foreach(lc, range_table_func->columns)
	{
		deparseRangeTableFuncCol(str, castNode(RangeTableFuncCol, lfirst(lc)));
		if (lnext(range_table_func->columns, lc))
			appendStringInfoString(str, ", ");
	}

	appendStringInfoString(str, ") ");

	if (range_table_func->alias)
	{
		appendStringInfoString(str, "AS ");
		deparseAlias(str, range_table_func->alias);
	}

	removeTrailingSpace(str);
}

static void deparseXmlSerialize(StringInfo str, XmlSerialize *xml_serialize)
{
	appendStringInfoString(str, "xmlserialize(");
	switch (xml_serialize->xmloption)
	{
		case XMLOPTION_DOCUMENT:
			appendStringInfoString(str, "document ");
			break;
		case XMLOPTION_CONTENT:
			appendStringInfoString(str, "content ");
			break;
		default:
			Assert(false);
	}
	deparseExpr(str, xml_serialize->expr);
	appendStringInfoString(str, " AS ");
	deparseTypeName(str, xml_serialize->typeName);
	appendStringInfoString(str, ")");
}

static void deparseGroupingFunc(StringInfo str, GroupingFunc *grouping_func)
{
	appendStringInfoString(str, "GROUPING(");
	deparseExprList(str, grouping_func->args);
	appendStringInfoChar(str, ')');
}

static void deparseClusterStmt(StringInfo str, ClusterStmt *cluster_stmt)
{
	appendStringInfoString(str, "CLUSTER ");

        deparseUtilityOptionList(str, cluster_stmt->params);

	if (cluster_stmt->relation != NULL)
	{
		deparseRangeVar(str, cluster_stmt->relation, DEPARSE_NODE_CONTEXT_NONE);
		appendStringInfoChar(str, ' ');
	}

	if (cluster_stmt->indexname != NULL)
	{
		appendStringInfoString(str, "USING ");
		appendStringInfoString(str, quote_identifier(cluster_stmt->indexname));
		appendStringInfoChar(str, ' ');
	}

	removeTrailingSpace(str);
}

static void deparseValue(StringInfo str, union ValUnion *value, DeparseNodeContext context)
{
	if (!value) {
		appendStringInfoString(str, "NULL");
		return;
	}

	switch (nodeTag(value))
	{
		case T_Integer:
		case T_Float:
			deparseNumericOnly(str, value);
			break;
		case T_Boolean:
			appendStringInfoString(str, value->boolval.boolval ? "true" : "false");
			break;
		case T_String:
			if (context == DEPARSE_NODE_CONTEXT_IDENTIFIER) {
				appendStringInfoString(str, quote_identifier(value->sval.sval));
			} else if (context == DEPARSE_NODE_CONTEXT_CONSTANT) {
				deparseStringLiteral(str, value->sval.sval);
			} else {
				appendStringInfoString(str, value->sval.sval);
			}
			break;
		case T_BitString:
			if (strlen(value->sval.sval) >= 1 && value->sval.sval[0] == 'x')
			{
				appendStringInfoChar(str, 'x');
				deparseStringLiteral(str, value->sval.sval + 1);
			}
			else if (strlen(value->sval.sval) >= 1 && value->sval.sval[0] == 'b')
			{
				appendStringInfoChar(str, 'b');
				deparseStringLiteral(str, value->sval.sval + 1);
			}
			else
			{
				Assert(false);
			}
			break;
		default:
			elog(ERROR, "deparse: unrecognized value node type: %d",
				 (int) nodeTag(value));
			break;
	}
}

// "PrepareableStmt" in gram.y
static void deparsePreparableStmt(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_SelectStmt:
			deparseSelectStmt(str, castNode(SelectStmt, node));
			break;
		case T_InsertStmt:
			deparseInsertStmt(str, castNode(InsertStmt, node));
			break;
		case T_UpdateStmt:
			deparseUpdateStmt(str, castNode(UpdateStmt, node));
			break;
		case T_DeleteStmt:
			deparseDeleteStmt(str, castNode(DeleteStmt, node));
			break;
		case T_MergeStmt:
			deparseMergeStmt(str, castNode(MergeStmt, node));
			break;
		default:
			Assert(false);
	}
}

// "RuleActionStmt" in gram.y
static void deparseRuleActionStmt(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_SelectStmt:
			deparseSelectStmt(str, castNode(SelectStmt, node));
			break;
		case T_InsertStmt:
			deparseInsertStmt(str, castNode(InsertStmt, node));
			break;
		case T_UpdateStmt:
			deparseUpdateStmt(str, castNode(UpdateStmt, node));
			break;
		case T_DeleteStmt:
			deparseDeleteStmt(str, castNode(DeleteStmt, node));
			break;
		case T_NotifyStmt:
			deparseNotifyStmt(str, castNode(NotifyStmt, node));
			break;
		default:
			Assert(false);
	}
}

// "ExplainableStmt" in gram.y
static void deparseExplainableStmt(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_SelectStmt:
			deparseSelectStmt(str, castNode(SelectStmt, node));
			break;
		case T_InsertStmt:
			deparseInsertStmt(str, castNode(InsertStmt, node));
			break;
		case T_UpdateStmt:
			deparseUpdateStmt(str, castNode(UpdateStmt, node));
			break;
		case T_DeleteStmt:
			deparseDeleteStmt(str, castNode(DeleteStmt, node));
			break;
		case T_DeclareCursorStmt:
			deparseDeclareCursorStmt(str, castNode(DeclareCursorStmt, node));
			break;
		case T_CreateTableAsStmt:
			deparseCreateTableAsStmt(str, castNode(CreateTableAsStmt, node));
			break;
		case T_RefreshMatViewStmt:
			deparseRefreshMatViewStmt(str, castNode(RefreshMatViewStmt, node));
			break;
		case T_ExecuteStmt:
			deparseExecuteStmt(str, castNode(ExecuteStmt, node));
			break;
		case T_MergeStmt:
			deparseMergeStmt(str, castNode(MergeStmt, node));
			break;
		default:
			Assert(false);
	}
}

// "schema_stmt" in gram.y
static void deparseSchemaStmt(StringInfo str, Node *node)
{
	switch (nodeTag(node))
	{
		case T_CreateStmt:
			deparseCreateStmt(str, castNode(CreateStmt, node), false);
			break;
		case T_IndexStmt:
			deparseIndexStmt(str, castNode(IndexStmt, node));
			break;
		case T_CreateSeqStmt:
			deparseCreateSeqStmt(str, castNode(CreateSeqStmt, node));
			break;
		case T_CreateTrigStmt:
			deparseCreateTrigStmt(str, castNode(CreateTrigStmt, node));
			break;
		case T_GrantStmt:
			deparseGrantStmt(str, castNode(GrantStmt, node));
			break;
		case T_ViewStmt:
			deparseViewStmt(str, castNode(ViewStmt, node));
			break;
		default:
			Assert(false);
	}
}

// "stmt" in gram.y
static void deparseStmt(StringInfo str, Node *node)
{
	// Note the following grammar names are missing in the list, because they
	// get mapped to other node types:
	//
	// - AlterForeignTableStmt (=> AlterTableStmt)
	// - AlterGroupStmt (=> AlterRoleStmt)
	// - AlterCompositeTypeStmt (=> AlterTableStmt)
	// - AnalyzeStmt (=> VacuumStmt)
	// - CreateGroupStmt (=> CreateRoleStmt)
	// - CreateMatViewStmt (=> CreateTableAsStmt)
	// - CreateUserStmt (=> CreateRoleStmt)
	// - DropCastStmt (=> DropStmt)
	// - DropOpClassStmt (=> DropStmt)
	// - DropOpFamilyStmt (=> DropStmt)
	// - DropPLangStmt (=> DropPLangStmt)
	// - DropTransformStmt (=> DropStmt)
	// - RemoveAggrStmt (=> DropStmt)
	// - RemoveFuncStmt (=> DropStmt)
	// - RemoveOperStmt (=> DropStmt)
	// - RevokeStmt (=> GrantStmt)
	// - RevokeRoleStmt (=> GrantRoleStmt)
	// - VariableResetStmt (=> VariableSetStmt)
	//
	// And the following grammar names error out in the parser:
	// - CreateAssertionStmt (not supported yet)
	switch (nodeTag(node))
	{
		case T_AlterEventTrigStmt:
			deparseAlterEventTrigStmt(str, castNode(AlterEventTrigStmt, node));
			break;
		case T_AlterCollationStmt:
			deparseAlterCollationStmt(str, castNode(AlterCollationStmt, node));
			break;
		case T_AlterDatabaseStmt:
			deparseAlterDatabaseStmt(str, castNode(AlterDatabaseStmt, node));
			break;
		case T_AlterDatabaseSetStmt:
			deparseAlterDatabaseSetStmt(str, castNode(AlterDatabaseSetStmt, node));
			break;
		case T_AlterDefaultPrivilegesStmt:
			deparseAlterDefaultPrivilegesStmt(str, castNode(AlterDefaultPrivilegesStmt, node));
			break;
		case T_AlterDomainStmt:
			deparseAlterDomainStmt(str, castNode(AlterDomainStmt, node));
			break;
		case T_AlterEnumStmt:
			deparseAlterEnumStmt(str, castNode(AlterEnumStmt, node));
			break;
		case T_AlterExtensionStmt:
			deparseAlterExtensionStmt(str, castNode(AlterExtensionStmt, node));
			break;
		case T_AlterExtensionContentsStmt:
			deparseAlterExtensionContentsStmt(str, castNode(AlterExtensionContentsStmt, node));
			break;
		case T_AlterFdwStmt:
			deparseAlterFdwStmt(str, castNode(AlterFdwStmt, node));
			break;
		case T_AlterForeignServerStmt:
			deparseAlterForeignServerStmt(str, castNode(AlterForeignServerStmt, node));
			break;
		case T_AlterFunctionStmt:
			deparseAlterFunctionStmt(str, castNode(AlterFunctionStmt, node));
			break;
		case T_AlterObjectDependsStmt:
			deparseAlterObjectDependsStmt(str, castNode(AlterObjectDependsStmt, node));
			break;
		case T_AlterObjectSchemaStmt:
			deparseAlterObjectSchemaStmt(str, castNode(AlterObjectSchemaStmt, node));
			break;
		case T_AlterOwnerStmt:
			deparseAlterOwnerStmt(str, castNode(AlterOwnerStmt, node));
			break;
		case T_AlterOperatorStmt:
			deparseAlterOperatorStmt(str, castNode(AlterOperatorStmt, node));
			break;
		case T_AlterTypeStmt:
			deparseAlterTypeStmt(str, castNode(AlterTypeStmt, node));
			break;
		case T_AlterPolicyStmt:
			deparseAlterPolicyStmt(str, castNode(AlterPolicyStmt, node));
			break;
		case T_AlterSeqStmt:
			deparseAlterSeqStmt(str, castNode(AlterSeqStmt, node));
			break;
		case T_AlterSystemStmt:
			deparseAlterSystemStmt(str, castNode(AlterSystemStmt, node));
			break;
		case T_AlterTableMoveAllStmt:
			deparseAlterTableMoveAllStmt(str, castNode(AlterTableMoveAllStmt, node));
			break;
		case T_AlterTableStmt:
			deparseAlterTableStmt(str, castNode(AlterTableStmt, node));
			break;
		case T_AlterTableSpaceOptionsStmt: // "AlterTblSpcStmt" in gram.y
			deparseAlterTableSpaceOptionsStmt(str, castNode(AlterTableSpaceOptionsStmt, node));
			break;
		case T_AlterPublicationStmt:
			deparseAlterPublicationStmt(str, castNode(AlterPublicationStmt, node));
			break;
		case T_AlterRoleSetStmt:
			deparseAlterRoleSetStmt(str, castNode(AlterRoleSetStmt, node));
			break;
		case T_AlterRoleStmt:
			deparseAlterRoleStmt(str, castNode(AlterRoleStmt, node));
			break;
		case T_AlterSubscriptionStmt:
			deparseAlterSubscriptionStmt(str, castNode(AlterSubscriptionStmt, node));
			break;
		case T_AlterStatsStmt:
			deparseAlterStatsStmt(str, castNode(AlterStatsStmt, node));
			break;
		case T_AlterTSConfigurationStmt:
			deparseAlterTSConfigurationStmt(str, castNode(AlterTSConfigurationStmt, node));
			break;
		case T_AlterTSDictionaryStmt:
			deparseAlterTSDictionaryStmt(str, castNode(AlterTSDictionaryStmt, node));
			break;
		case T_AlterUserMappingStmt:
			deparseAlterUserMappingStmt(str, castNode(AlterUserMappingStmt, node));
			break;
		case T_CallStmt:
			deparseCallStmt(str, castNode(CallStmt, node));
			break;
		case T_CheckPointStmt:
			deparseCheckPointStmt(str, castNode(CheckPointStmt, node));
			break;
		case T_ClosePortalStmt:
			deparseClosePortalStmt(str, castNode(ClosePortalStmt, node));
			break;
		case T_ClusterStmt:
			deparseClusterStmt(str, castNode(ClusterStmt, node));
			break;
		case T_CommentStmt:
			deparseCommentStmt(str, castNode(CommentStmt, node));
			break;
		case T_ConstraintsSetStmt:
			deparseConstraintsSetStmt(str, castNode(ConstraintsSetStmt, node));
			break;
		case T_CopyStmt:
			deparseCopyStmt(str, castNode(CopyStmt, node));
			break;
		case T_CreateAmStmt:
			deparseCreateAmStmt(str, castNode(CreateAmStmt, node));
			break;
		case T_CreateTableAsStmt: // "CreateAsStmt" in gram.y
			deparseCreateTableAsStmt(str, castNode(CreateTableAsStmt, node));
			break;
		case T_CreateCastStmt:
			deparseCreateCastStmt(str, castNode(CreateCastStmt, node));
			break;
		case T_CreateConversionStmt:
			deparseCreateConversionStmt(str, castNode(CreateConversionStmt, node));
			break;
		case T_CreateDomainStmt:
			deparseCreateDomainStmt(str, castNode(CreateDomainStmt, node));
			break;
		case T_CreateExtensionStmt:
			deparseCreateExtensionStmt(str, castNode(CreateExtensionStmt, node));
			break;
		case T_CreateFdwStmt:
			deparseCreateFdwStmt(str, castNode(CreateFdwStmt, node));
			break;
		case T_CreateForeignServerStmt:
			deparseCreateForeignServerStmt(str, castNode(CreateForeignServerStmt, node));
			break;
		case T_CreateForeignTableStmt:
			deparseCreateForeignTableStmt(str, castNode(CreateForeignTableStmt, node));
			break;
		case T_CreateFunctionStmt:
			deparseCreateFunctionStmt(str, castNode(CreateFunctionStmt, node));
			break;
		case T_CreateOpClassStmt:
			deparseCreateOpClassStmt(str, castNode(CreateOpClassStmt, node));
			break;
		case T_CreateOpFamilyStmt:
			deparseCreateOpFamilyStmt(str, castNode(CreateOpFamilyStmt, node));
			break;
		case T_CreatePublicationStmt:
			deparseCreatePublicationStmt(str, castNode(CreatePublicationStmt, node));
			break;
		case T_AlterOpFamilyStmt:
			deparseAlterOpFamilyStmt(str, castNode(AlterOpFamilyStmt, node));
			break;
		case T_CreatePolicyStmt:
			deparseCreatePolicyStmt(str, castNode(CreatePolicyStmt, node));
			break;
		case T_CreatePLangStmt:
			deparseCreatePLangStmt(str, castNode(CreatePLangStmt, node));
			break;
		case T_CreateSchemaStmt:
			deparseCreateSchemaStmt(str, castNode(CreateSchemaStmt, node));
			break;
		case T_CreateSeqStmt:
			deparseCreateSeqStmt(str, castNode(CreateSeqStmt, node));
			break;
		case T_CreateStmt:
			deparseCreateStmt(str, castNode(CreateStmt, node), false);
			break;
		case T_CreateSubscriptionStmt:
			deparseCreateSubscriptionStmt(str, castNode(CreateSubscriptionStmt, node));
			break;
		case T_CreateStatsStmt:
			deparseCreateStatsStmt(str, castNode(CreateStatsStmt, node));
			break;
		case T_CreateTableSpaceStmt:
			deparseCreateTableSpaceStmt(str, castNode(CreateTableSpaceStmt, node));
			break;
		case T_CreateTransformStmt:
			deparseCreateTransformStmt(str, castNode(CreateTransformStmt, node));
			break;
		case T_CreateTrigStmt:
			deparseCreateTrigStmt(str, castNode(CreateTrigStmt, node));
			break;
		case T_CreateEventTrigStmt:
			deparseCreateEventTrigStmt(str, castNode(CreateEventTrigStmt, node));
			break;
		case T_CreateRoleStmt:
			deparseCreateRoleStmt(str, castNode(CreateRoleStmt, node));
			break;
		case T_CreateUserMappingStmt:
			deparseCreateUserMappingStmt(str, castNode(CreateUserMappingStmt, node));
			break;
		case T_CreatedbStmt:
			deparseCreatedbStmt(str, castNode(CreatedbStmt, node));
			break;
		case T_DeallocateStmt:
			deparseDeallocateStmt(str, castNode(DeallocateStmt, node));
			break;
		case T_DeclareCursorStmt:
			deparseDeclareCursorStmt(str, castNode(DeclareCursorStmt, node));
			break;
		case T_DefineStmt:
			deparseDefineStmt(str, castNode(DefineStmt, node));
			break;
		case T_DeleteStmt:
			deparseDeleteStmt(str, castNode(DeleteStmt, node));
			break;
		case T_DiscardStmt:
			deparseDiscardStmt(str, castNode(DiscardStmt, node));
			break;
		case T_DoStmt:
			deparseDoStmt(str, castNode(DoStmt, node));
			break;
		case T_DropOwnedStmt:
			deparseDropOwnedStmt(str, castNode(DropOwnedStmt, node));
			break;
		case T_DropStmt:
			deparseDropStmt(str, castNode(DropStmt, node));
			break;
		case T_DropSubscriptionStmt:
			deparseDropSubscriptionStmt(str, castNode(DropSubscriptionStmt, node));
			break;
		case T_DropTableSpaceStmt:
			deparseDropTableSpaceStmt(str, castNode(DropTableSpaceStmt, node));
			break;
		case T_DropRoleStmt:
			deparseDropRoleStmt(str, castNode(DropRoleStmt, node));
			break;
		case T_DropUserMappingStmt:
			deparseDropUserMappingStmt(str, castNode(DropUserMappingStmt, node));
			break;
		case T_DropdbStmt:
			deparseDropdbStmt(str, castNode(DropdbStmt, node));
			break;
		case T_ExecuteStmt:
			deparseExecuteStmt(str, castNode(ExecuteStmt, node));
			break;
		case T_ExplainStmt:
			deparseExplainStmt(str, castNode(ExplainStmt, node));
			break;
		case T_FetchStmt:
			deparseFetchStmt(str, castNode(FetchStmt, node));
			break;
		case T_GrantStmt:
			deparseGrantStmt(str, castNode(GrantStmt, node));
			break;
		case T_GrantRoleStmt:
			deparseGrantRoleStmt(str, castNode(GrantRoleStmt, node));
			break;
		case T_ImportForeignSchemaStmt:
			deparseImportForeignSchemaStmt(str, castNode(ImportForeignSchemaStmt, node));
			break;
		case T_IndexStmt:
			deparseIndexStmt(str, castNode(IndexStmt, node));
			break;
		case T_InsertStmt:
			deparseInsertStmt(str, castNode(InsertStmt, node));
			break;
		case T_ListenStmt:
			deparseListenStmt(str, castNode(ListenStmt, node));
			break;
		case T_RefreshMatViewStmt:
			deparseRefreshMatViewStmt(str, castNode(RefreshMatViewStmt, node));
			break;
		case T_LoadStmt:
			deparseLoadStmt(str, castNode(LoadStmt, node));
			break;
		case T_LockStmt:
			deparseLockStmt(str, castNode(LockStmt, node));
			break;
		case T_MergeStmt:
			deparseMergeStmt(str, castNode(MergeStmt, node));
			break;
		case T_NotifyStmt:
			deparseNotifyStmt(str, castNode(NotifyStmt, node));
			break;
		case T_PrepareStmt:
			deparsePrepareStmt(str, castNode(PrepareStmt, node));
			break;
		case T_ReassignOwnedStmt:
			deparseReassignOwnedStmt(str, castNode(ReassignOwnedStmt, node));
			break;
		case T_ReindexStmt:
			deparseReindexStmt(str, castNode(ReindexStmt, node));
			break;
		case T_RenameStmt:
			deparseRenameStmt(str, castNode(RenameStmt, node));
			break;
		case T_RuleStmt:
			deparseRuleStmt(str, castNode(RuleStmt, node));
			break;
		case T_SecLabelStmt:
			deparseSecLabelStmt(str, castNode(SecLabelStmt, node));
			break;
		case T_SelectStmt:
			deparseSelectStmt(str, castNode(SelectStmt, node));
			break;
		case T_TransactionStmt:
			deparseTransactionStmt(str, castNode(TransactionStmt, node));
			break;
		case T_TruncateStmt:
			deparseTruncateStmt(str, castNode(TruncateStmt, node));
			break;
		case T_UnlistenStmt:
			deparseUnlistenStmt(str, castNode(UnlistenStmt, node));
			break;
		case T_UpdateStmt:
			deparseUpdateStmt(str, castNode(UpdateStmt, node));
			break;
		case T_VacuumStmt:
			deparseVacuumStmt(str, castNode(VacuumStmt, node));
			break;
		case T_VariableSetStmt:
			deparseVariableSetStmt(str, castNode(VariableSetStmt, node));
			break;
		case T_VariableShowStmt:
			deparseVariableShowStmt(str, castNode(VariableShowStmt, node));
			break;
		case T_ViewStmt:
			deparseViewStmt(str, castNode(ViewStmt, node));
			break;
		// These node types are created by DefineStmt grammar for CREATE TYPE in some cases
		case T_CompositeTypeStmt:
			deparseCompositeTypeStmt(str, castNode(CompositeTypeStmt, node));
			break;
		case T_CreateEnumStmt:
			deparseCreateEnumStmt(str, castNode(CreateEnumStmt, node));
			break;
		case T_CreateRangeStmt:
			deparseCreateRangeStmt(str, castNode(CreateRangeStmt, node));
			break;
		default:
			elog(ERROR, "deparse: unsupported top-level node type: %u", nodeTag(node));
	}
}
