#include "pg_query.h"
#include "pg_query_json_plpgsql.h"

#include "pg_query_json_helper.c"

/* Write the label for the node type */
#define WRITE_NODE_TYPE(nodelabel) \
	appendStringInfoString(out, "\"" nodelabel "\":{")

/* Write an integer field */
#define WRITE_INT_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%d,", node->fldname); \
	}

/* Write a long-integer field */
#define WRITE_LONG_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%ld,", node->fldname); \
	}

/* Write an enumerated-type field as an integer code */
#define WRITE_ENUM_FIELD(outname, outname_json, fldname) \
	appendStringInfo(out, "\"" CppAsString(outname_json) "\":%d,", \
					 (int) node->fldname)

/* Write a boolean field */
#define WRITE_BOOL_FIELD(outname, outname_json, fldname) \
	if (node->fldname) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%s,", \
						booltostr(node->fldname)); \
	}

/* Write a character-string (possibly NULL) field */
#define WRITE_STRING_FIELD(outname, outname_json, fldname) \
	if (node->fldname != NULL) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":"); \
		_outToken(out, node->fldname); \
		appendStringInfo(out, ","); \
	}

#define WRITE_INT_VALUE(fldname, value) \
	if (value != 0) { \
		appendStringInfo(out, "\"" CppAsString(fldname) "\":%d,", value); \
	}

#define WRITE_STRING_VALUE(fldname, value) \
	if (true) { \
		appendStringInfo(out, "\"" CppAsString(fldname) "\":"); \
		_outToken(out, value); \
		appendStringInfo(out, ","); \
	}

#define WRITE_OBJ_FIELD(fldname, outfunc) \
	if (node->fldname != NULL) { \
		 appendStringInfo(out, "\"" CppAsString(fldname) "\":{"); \
		 outfunc(out, node->fldname); \
		 removeTrailingDelimiter(out); \
		 appendStringInfo(out, "}},"); \
	}

#define WRITE_LIST_FIELD(fldname, fldtype, outfunc) \
	if (node->fldname != NULL) { \
		ListCell *lc; \
		appendStringInfo(out, "\"" CppAsString(fldname) "\":["); \
		foreach(lc, node->fldname) { \
			appendStringInfoString(out, "{"); \
			outfunc(out, (fldtype *) lfirst(lc)); \
			removeTrailingDelimiter(out); \
			appendStringInfoString(out, "}},"); \
		} \
		removeTrailingDelimiter(out); \
		appendStringInfoString(out, "],"); \
  }

  #define WRITE_STATEMENTS_FIELD(fldname) \
	if (node->fldname != NULL) { \
		ListCell *lc; \
		appendStringInfo(out, "\"" CppAsString(fldname) "\":["); \
		foreach(lc, node->fldname) { \
			dump_stmt(out, (PLpgSQL_stmt *) lfirst(lc)); \
		} \
		removeTrailingDelimiter(out); \
		appendStringInfoString(out, "],"); \
	}

#define WRITE_EXPR_FIELD(fldname)   WRITE_OBJ_FIELD(fldname, dump_expr)
#define WRITE_BLOCK_FIELD(fldname)  WRITE_OBJ_FIELD(fldname, dump_block)
#define WRITE_RECORD_FIELD(fldname) WRITE_OBJ_FIELD(fldname, dump_record)
#define WRITE_ROW_FIELD(fldname)    WRITE_OBJ_FIELD(fldname, dump_row)
#define WRITE_VAR_FIELD(fldname)    WRITE_OBJ_FIELD(fldname, dump_var)
#define WRITE_VARIABLE_FIELD(fldname) WRITE_OBJ_FIELD(fldname, dump_variable);

static void dump_record(StringInfo out, PLpgSQL_rec *stmt);
static void dump_row(StringInfo out, PLpgSQL_row *stmt);
static void dump_var(StringInfo out, PLpgSQL_var *stmt);
static void dump_variable(StringInfo out, PLpgSQL_variable *stmt);
static void dump_record_field(StringInfo out, PLpgSQL_recfield *node);
static void dump_stmt(StringInfo out, PLpgSQL_stmt *stmt);
static void dump_block(StringInfo out, PLpgSQL_stmt_block *block);
static void dump_exception_block(StringInfo out, PLpgSQL_exception_block *node);
static void dump_assign(StringInfo out, PLpgSQL_stmt_assign *stmt);
static void dump_if(StringInfo out, PLpgSQL_stmt_if *stmt);
static void dump_if_elsif(StringInfo out, PLpgSQL_if_elsif *node);
static void dump_case(StringInfo out, PLpgSQL_stmt_case *stmt);
static void dump_case_when(StringInfo out, PLpgSQL_case_when *node);
static void dump_loop(StringInfo out, PLpgSQL_stmt_loop *stmt);
static void dump_while(StringInfo out, PLpgSQL_stmt_while *stmt);
static void dump_fori(StringInfo out, PLpgSQL_stmt_fori *stmt);
static void dump_fors(StringInfo out, PLpgSQL_stmt_fors *stmt);
static void dump_forc(StringInfo out, PLpgSQL_stmt_forc *stmt);
static void dump_foreach_a(StringInfo out, PLpgSQL_stmt_foreach_a *stmt);
static void dump_exit(StringInfo out, PLpgSQL_stmt_exit *stmt);
static void dump_return(StringInfo out, PLpgSQL_stmt_return *stmt);
static void dump_return_next(StringInfo out, PLpgSQL_stmt_return_next *stmt);
static void dump_return_query(StringInfo out, PLpgSQL_stmt_return_query *stmt);
static void dump_raise(StringInfo out, PLpgSQL_stmt_raise *stmt);
static void dump_raise_option(StringInfo out, PLpgSQL_raise_option *node);
static void dump_assert(StringInfo out, PLpgSQL_stmt_assert *stmt);
static void dump_execsql(StringInfo out, PLpgSQL_stmt_execsql *stmt);
static void dump_dynexecute(StringInfo out, PLpgSQL_stmt_dynexecute *stmt);
static void dump_dynfors(StringInfo out, PLpgSQL_stmt_dynfors *stmt);
static void dump_getdiag(StringInfo out, PLpgSQL_stmt_getdiag *stmt);
static void dump_getdiag_item(StringInfo out, PLpgSQL_diag_item *node);
static void dump_open(StringInfo out, PLpgSQL_stmt_open *stmt);
static void dump_fetch(StringInfo out, PLpgSQL_stmt_fetch *stmt);
static void dump_close(StringInfo out, PLpgSQL_stmt_close *stmt);
static void dump_perform(StringInfo out, PLpgSQL_stmt_perform *stmt);
static void dump_call(StringInfo out, PLpgSQL_stmt_call *stmt);
static void dump_commit(StringInfo out, PLpgSQL_stmt_commit *stmt);
static void dump_rollback(StringInfo out, PLpgSQL_stmt_rollback *stmt);
static void dump_expr(StringInfo out, PLpgSQL_expr *expr);
static void dump_function(StringInfo out, PLpgSQL_function *func);
static void dump_exception(StringInfo out, PLpgSQL_exception *node);
static void dump_condition(StringInfo out, PLpgSQL_condition *node);
static void dump_type(StringInfo out, PLpgSQL_type *node);

static void
dump_stmt(StringInfo out, PLpgSQL_stmt *node)
{
	appendStringInfoChar(out, '{');
	switch (node->cmd_type)
	{
		case PLPGSQL_STMT_BLOCK:
			dump_block(out, (PLpgSQL_stmt_block *) node);
			break;
		case PLPGSQL_STMT_ASSIGN:
			dump_assign(out, (PLpgSQL_stmt_assign *) node);
			break;
		case PLPGSQL_STMT_IF:
			dump_if(out, (PLpgSQL_stmt_if *) node);
			break;
		case PLPGSQL_STMT_CASE:
			dump_case(out, (PLpgSQL_stmt_case *) node);
			break;
		case PLPGSQL_STMT_LOOP:
			dump_loop(out, (PLpgSQL_stmt_loop *) node);
			break;
		case PLPGSQL_STMT_WHILE:
			dump_while(out, (PLpgSQL_stmt_while *) node);
			break;
		case PLPGSQL_STMT_FORI:
			dump_fori(out, (PLpgSQL_stmt_fori *) node);
			break;
		case PLPGSQL_STMT_FORS:
			dump_fors(out, (PLpgSQL_stmt_fors *) node);
			break;
		case PLPGSQL_STMT_FORC:
			dump_forc(out, (PLpgSQL_stmt_forc *) node);
			break;
		case PLPGSQL_STMT_FOREACH_A:
			dump_foreach_a(out, (PLpgSQL_stmt_foreach_a *) node);
			break;
		case PLPGSQL_STMT_EXIT:
			dump_exit(out, (PLpgSQL_stmt_exit *) node);
			break;
		case PLPGSQL_STMT_RETURN:
			dump_return(out, (PLpgSQL_stmt_return *) node);
			break;
		case PLPGSQL_STMT_RETURN_NEXT:
			dump_return_next(out, (PLpgSQL_stmt_return_next *) node);
			break;
		case PLPGSQL_STMT_RETURN_QUERY:
			dump_return_query(out, (PLpgSQL_stmt_return_query *) node);
			break;
		case PLPGSQL_STMT_RAISE:
			dump_raise(out, (PLpgSQL_stmt_raise *) node);
			break;
		case PLPGSQL_STMT_ASSERT:
			dump_assert(out, (PLpgSQL_stmt_assert *) node);
			break;
		case PLPGSQL_STMT_EXECSQL:
			dump_execsql(out, (PLpgSQL_stmt_execsql *) node);
			break;
		case PLPGSQL_STMT_DYNEXECUTE:
			dump_dynexecute(out, (PLpgSQL_stmt_dynexecute *) node);
			break;
		case PLPGSQL_STMT_DYNFORS:
			dump_dynfors(out, (PLpgSQL_stmt_dynfors *) node);
			break;
		case PLPGSQL_STMT_GETDIAG:
			dump_getdiag(out, (PLpgSQL_stmt_getdiag *) node);
			break;
		case PLPGSQL_STMT_OPEN:
			dump_open(out, (PLpgSQL_stmt_open *) node);
			break;
		case PLPGSQL_STMT_FETCH:
			dump_fetch(out, (PLpgSQL_stmt_fetch *) node);
			break;
		case PLPGSQL_STMT_CLOSE:
			dump_close(out, (PLpgSQL_stmt_close *) node);
			break;
		case PLPGSQL_STMT_PERFORM:
			dump_perform(out, (PLpgSQL_stmt_perform *) node);
			break;
		case PLPGSQL_STMT_CALL:
			dump_call(out, (PLpgSQL_stmt_call *) node);
			break;
		case PLPGSQL_STMT_COMMIT:
			dump_commit(out, (PLpgSQL_stmt_commit *) node);
			break;
		case PLPGSQL_STMT_ROLLBACK:
			dump_rollback(out, (PLpgSQL_stmt_rollback *) node);
			break;
		default:
			elog(ERROR, "unrecognized cmd_type: %d", node->cmd_type);
			break;
	}
	removeTrailingDelimiter(out);
	appendStringInfoString(out, "}},");
}

static void
dump_block(StringInfo out, PLpgSQL_stmt_block *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_block");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_STATEMENTS_FIELD(body);
	WRITE_OBJ_FIELD(exceptions, dump_exception_block);

	removeTrailingDelimiter(out);
}

static void
dump_exception_block(StringInfo out, PLpgSQL_exception_block *node)
{
	WRITE_NODE_TYPE("PLpgSQL_exception_block");

	WRITE_LIST_FIELD(exc_list, PLpgSQL_exception, dump_exception);
}

static void
dump_exception(StringInfo out, PLpgSQL_exception *node)
{
	PLpgSQL_condition *cond;

	WRITE_NODE_TYPE("PLpgSQL_exception");

	appendStringInfo(out, "\"conditions\":[");
	for (cond = node->conditions; cond; cond = cond->next)
	{
		appendStringInfoString(out, "{");
		dump_condition(out, cond);
		removeTrailingDelimiter(out);
		appendStringInfoString(out, "}},");
	}
	removeTrailingDelimiter(out);
	appendStringInfoString(out, "],");

	WRITE_STATEMENTS_FIELD(action);
}

static void
dump_condition(StringInfo out, PLpgSQL_condition *node)
{
	WRITE_NODE_TYPE("PLpgSQL_condition");

	WRITE_STRING_FIELD(condname, condname, condname);
}

static void
dump_assign(StringInfo out, PLpgSQL_stmt_assign *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_assign");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_INT_FIELD(varno, varno, varno);
	WRITE_EXPR_FIELD(expr);
}

static void
dump_if(StringInfo out, PLpgSQL_stmt_if *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_if");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(cond);
	WRITE_STATEMENTS_FIELD(then_body);
	WRITE_LIST_FIELD(elsif_list, PLpgSQL_if_elsif, dump_if_elsif);
	WRITE_STATEMENTS_FIELD(else_body);
}

static void
dump_if_elsif(StringInfo out, PLpgSQL_if_elsif *node)
{
	WRITE_NODE_TYPE("PLpgSQL_if_elsif");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(cond);
	WRITE_STATEMENTS_FIELD(stmts);
}

static void
dump_case(StringInfo out, PLpgSQL_stmt_case *node)
{
	ListCell   *l;

	WRITE_NODE_TYPE("PLpgSQL_stmt_case");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(t_expr);
	WRITE_INT_FIELD(t_varno, t_varno, t_varno);
	WRITE_LIST_FIELD(case_when_list, PLpgSQL_case_when, dump_case_when);
	WRITE_BOOL_FIELD(have_else, have_else, have_else);
	WRITE_STATEMENTS_FIELD(else_stmts);
}

static void
dump_case_when(StringInfo out, PLpgSQL_case_when *node)
{
	WRITE_NODE_TYPE("PLpgSQL_case_when");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(expr);
	WRITE_STATEMENTS_FIELD(stmts);
}

static void
dump_loop(StringInfo out, PLpgSQL_stmt_loop *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_loop");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_STATEMENTS_FIELD(body);
}

static void
dump_while(StringInfo out, PLpgSQL_stmt_while *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_while");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_EXPR_FIELD(cond);
	WRITE_STATEMENTS_FIELD(body);
}

/* FOR statement with integer loopvar	*/
static void
dump_fori(StringInfo out, PLpgSQL_stmt_fori *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_fori");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_VAR_FIELD(var);
	WRITE_EXPR_FIELD(lower);
	WRITE_EXPR_FIELD(upper);
	WRITE_EXPR_FIELD(step);
	WRITE_BOOL_FIELD(reverse, reverse, reverse);
	WRITE_STATEMENTS_FIELD(body);
}

static void
dump_fors(StringInfo out, PLpgSQL_stmt_fors *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_fors");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_VARIABLE_FIELD(var);
	WRITE_STATEMENTS_FIELD(body);
	WRITE_EXPR_FIELD(query);
}

static void
dump_forc(StringInfo out, PLpgSQL_stmt_forc *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_forc");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_VARIABLE_FIELD(var);
	WRITE_STATEMENTS_FIELD(body);
	WRITE_INT_FIELD(curvar, curvar, curvar);
	WRITE_EXPR_FIELD(argquery);
}

static void
dump_foreach_a(StringInfo out, PLpgSQL_stmt_foreach_a *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_foreach_a");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_INT_FIELD(varno, varno, varno);
	WRITE_INT_FIELD(slice, slice, slice);
	WRITE_EXPR_FIELD(expr);
	WRITE_STATEMENTS_FIELD(body);
}

static void
dump_open(StringInfo out, PLpgSQL_stmt_open *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_open");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_INT_FIELD(curvar, curvar, curvar);
	WRITE_INT_FIELD(cursor_options, cursor_options, cursor_options);
	WRITE_EXPR_FIELD(argquery);
	WRITE_EXPR_FIELD(query);
	WRITE_EXPR_FIELD(dynquery);
	WRITE_LIST_FIELD(params, PLpgSQL_expr, dump_expr);
}

static void
dump_fetch(StringInfo out, PLpgSQL_stmt_fetch *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_fetch");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_VARIABLE_FIELD(target);
	WRITE_INT_FIELD(curvar, curvar, curvar);
	WRITE_ENUM_FIELD(direction, direction, direction);
	WRITE_LONG_FIELD(how_many, how_many, how_many);
	WRITE_EXPR_FIELD(expr);
	WRITE_BOOL_FIELD(is_move, is_move, is_move);
	WRITE_BOOL_FIELD(returns_multiple_rows, returns_multiple_rows, returns_multiple_rows);
}

static void
dump_close(StringInfo out, PLpgSQL_stmt_close *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_close");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_INT_FIELD(curvar, curvar, curvar);
}

static void
dump_perform(StringInfo out, PLpgSQL_stmt_perform *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_perform");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(expr);
}

static void
dump_call(StringInfo out, PLpgSQL_stmt_call *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_call");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(expr);
	WRITE_BOOL_FIELD(is_call, is_call, is_call);
	WRITE_VARIABLE_FIELD(target);
}

static void
dump_commit(StringInfo out, PLpgSQL_stmt_commit *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_commit");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_BOOL_FIELD(chain, chain, chain);
}

static void
dump_rollback(StringInfo out, PLpgSQL_stmt_rollback *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_rollback");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_BOOL_FIELD(chain, chain, chain);
}

static void
dump_exit(StringInfo out, PLpgSQL_stmt_exit *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_exit");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_BOOL_FIELD(is_exit, is_exit, is_exit);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_EXPR_FIELD(cond);
}

static void
dump_return(StringInfo out, PLpgSQL_stmt_return *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_return");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(expr);
	//WRITE_INT_FIELD(retvarno);
}

static void
dump_return_next(StringInfo out, PLpgSQL_stmt_return_next *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_return_next");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(expr);
	//WRITE_INT_FIELD(retvarno);
}

static void
dump_return_query(StringInfo out, PLpgSQL_stmt_return_query *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_return_query");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(query);
	WRITE_EXPR_FIELD(dynquery);
	WRITE_LIST_FIELD(params, PLpgSQL_expr, dump_expr);
}

static void
dump_raise(StringInfo out, PLpgSQL_stmt_raise *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_raise");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_INT_FIELD(elog_level, elog_level, elog_level);
	WRITE_STRING_FIELD(condname, condname, condname);
	WRITE_STRING_FIELD(message, message, message);
	WRITE_LIST_FIELD(params, PLpgSQL_expr, dump_expr);
	WRITE_LIST_FIELD(options, PLpgSQL_raise_option, dump_raise_option);
}

static void
dump_raise_option(StringInfo out, PLpgSQL_raise_option *node)
{
	WRITE_NODE_TYPE("PLpgSQL_raise_option");

	WRITE_ENUM_FIELD(opt_type, opt_type, opt_type);
	WRITE_EXPR_FIELD(expr);
}

static void
dump_assert(StringInfo out, PLpgSQL_stmt_assert *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_assert");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(cond);
	WRITE_EXPR_FIELD(message);
}

static void
dump_execsql(StringInfo out, PLpgSQL_stmt_execsql *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_execsql");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(sqlstmt);
	//WRITE_BOOL_FIELD(mod_stmt); // This is only populated when executing the function
	WRITE_BOOL_FIELD(into, into, into);
	WRITE_BOOL_FIELD(strict, strict, strict);
	WRITE_VARIABLE_FIELD(target);
}

static void
dump_dynexecute(StringInfo out, PLpgSQL_stmt_dynexecute *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_dynexecute");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_EXPR_FIELD(query);
	WRITE_BOOL_FIELD(into, into, into);
	WRITE_BOOL_FIELD(strict, strict, strict);
	WRITE_VARIABLE_FIELD(target);
	WRITE_LIST_FIELD(params, PLpgSQL_expr, dump_expr);
}

static void
dump_dynfors(StringInfo out, PLpgSQL_stmt_dynfors *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_dynfors");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_STRING_FIELD(label, label, label);
	WRITE_VARIABLE_FIELD(var);
	WRITE_STATEMENTS_FIELD(body);
	WRITE_EXPR_FIELD(query);
	WRITE_LIST_FIELD(params, PLpgSQL_expr, dump_expr);
}

static void
dump_getdiag(StringInfo out, PLpgSQL_stmt_getdiag *node)
{
	WRITE_NODE_TYPE("PLpgSQL_stmt_getdiag");

	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_BOOL_FIELD(is_stacked, is_stacked, is_stacked);
	WRITE_LIST_FIELD(diag_items, PLpgSQL_diag_item, dump_getdiag_item);
}

static void
dump_getdiag_item(StringInfo out, PLpgSQL_diag_item *node)
{
	WRITE_NODE_TYPE("PLpgSQL_diag_item");

	WRITE_STRING_VALUE(kind, plpgsql_getdiag_kindname(node->kind));
	WRITE_INT_FIELD(target, target, target);
}

static void
dump_expr(StringInfo out, PLpgSQL_expr *node)
{
	WRITE_NODE_TYPE("PLpgSQL_expr");

	WRITE_STRING_FIELD(query, query, query);
}

static void
dump_function(StringInfo out, PLpgSQL_function *node)
{
	int			i;
	PLpgSQL_datum *d;

	WRITE_NODE_TYPE("PLpgSQL_function");
	WRITE_INT_FIELD(new_varno, new_varno, new_varno);
	WRITE_INT_FIELD(old_varno, old_varno, old_varno);

	appendStringInfoString(out, "\"datums\":");
	appendStringInfoChar(out, '[');
	for (i = 0; i < node->ndatums; i++)
	{
	  appendStringInfoChar(out, '{');
		d = node->datums[i];

		switch (d->dtype)
		{
			case PLPGSQL_DTYPE_VAR:
				dump_var(out, (PLpgSQL_var *) d);
				break;
			case PLPGSQL_DTYPE_ROW:
				dump_row(out, (PLpgSQL_row *) d);
				break;
			case PLPGSQL_DTYPE_REC:
				dump_record(out, (PLpgSQL_rec *) d);
				break;
			case PLPGSQL_DTYPE_RECFIELD:
				dump_record_field(out, (PLpgSQL_recfield *) d);
				break;
			default:
				elog(WARNING, "could not dump unrecognized dtype: %d",
					 (int) d->dtype);
		}
		removeTrailingDelimiter(out);
		appendStringInfoString(out, "}},");
	}
	removeTrailingDelimiter(out);
	appendStringInfoString(out, "],");

	WRITE_BLOCK_FIELD(action);
}

static void
dump_var(StringInfo out, PLpgSQL_var *node)
{
	WRITE_NODE_TYPE("PLpgSQL_var");

	WRITE_STRING_FIELD(refname, refname, refname);
	WRITE_INT_FIELD(lineno, lineno, lineno);
	WRITE_OBJ_FIELD(datatype, dump_type);
	WRITE_BOOL_FIELD(isconst, isconst, isconst);
	WRITE_BOOL_FIELD(notnull, notnull, notnull);
	WRITE_EXPR_FIELD(default_val);
	WRITE_EXPR_FIELD(cursor_explicit_expr);
	WRITE_INT_FIELD(cursor_explicit_argrow, cursor_explicit_argrow, cursor_explicit_argrow);
	WRITE_INT_FIELD(cursor_options, cursor_options, cursor_options);
}

static void
dump_variable(StringInfo out, PLpgSQL_variable *node)
{
	switch (node->dtype)
	{
		case PLPGSQL_DTYPE_REC:
			dump_record(out, (PLpgSQL_rec *) node);
			break;
		case PLPGSQL_DTYPE_VAR:
			dump_var(out, (PLpgSQL_var *) node);
			break;
		case PLPGSQL_DTYPE_ROW:
			dump_row(out, (PLpgSQL_row *) node);
			break;
		default:
			elog(ERROR, "unrecognized variable type: %d", node->dtype);
			break;
	}
}

static void
dump_type(StringInfo out, PLpgSQL_type *node)
{
	WRITE_NODE_TYPE("PLpgSQL_type");

	WRITE_STRING_FIELD(typname, typname, typname);
}

static void
dump_row(StringInfo out, PLpgSQL_row *node)
{
	int i = 0;

	WRITE_NODE_TYPE("PLpgSQL_row");

	WRITE_STRING_FIELD(refname, refname, refname);
	WRITE_INT_FIELD(lineno, lineno, lineno);

	appendStringInfoString(out, "\"fields\":");
	appendStringInfoChar(out, '[');

	for (i = 0; i < node->nfields; i++)
	{
		if (node->fieldnames[i]) {
		  appendStringInfoChar(out, '{');
			WRITE_STRING_VALUE(name, node->fieldnames[i]);
			WRITE_INT_VALUE(varno, node->varnos[i]);
			removeTrailingDelimiter(out);
			appendStringInfoString(out, "},");
		} else {
			appendStringInfoString(out, "null,");
		}
	}
	removeTrailingDelimiter(out);

	appendStringInfoString(out, "],");
}

static void
dump_record(StringInfo out, PLpgSQL_rec *node) {
	WRITE_NODE_TYPE("PLpgSQL_rec");

	WRITE_STRING_FIELD(refname, refname, refname);
	WRITE_INT_FIELD(dno, dno, dno);
	WRITE_INT_FIELD(lineno, lineno, lineno);
}

static void
dump_record_field(StringInfo out, PLpgSQL_recfield *node) {
	WRITE_NODE_TYPE("PLpgSQL_recfield");

	WRITE_STRING_FIELD(fieldname, fieldname, fieldname);
	WRITE_INT_FIELD(recparentno, recparentno, recparentno);
}

char *
plpgsqlToJSON(PLpgSQL_function *func)
{
	StringInfoData str;

	initStringInfo(&str);

	appendStringInfoChar(&str, '{');

	dump_function(&str, func);

	removeTrailingDelimiter(&str);
	appendStringInfoString(&str, "}}");

	return str.data;
}
