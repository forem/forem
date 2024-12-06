/*-------------------------------------------------------------------------
 *
 * plpgsql.h		- Definitions for the PL/pgSQL
 *			  procedural language
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/pl/plpgsql/src/plpgsql.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef PLPGSQL_H
#define PLPGSQL_H

#include "access/xact.h"
#include "commands/event_trigger.h"
#include "commands/trigger.h"
#include "executor/spi.h"
#include "utils/expandedrecord.h"
#include "utils/typcache.h"


/**********************************************************************
 * Definitions
 **********************************************************************/

/* define our text domain for translations */
#undef TEXTDOMAIN
#define TEXTDOMAIN PG_TEXTDOMAIN("plpgsql")

#undef _
#define _(x) dgettext(TEXTDOMAIN, x)

/*
 * Compiler's namespace item types
 */
typedef enum PLpgSQL_nsitem_type
{
	PLPGSQL_NSTYPE_LABEL,		/* block label */
	PLPGSQL_NSTYPE_VAR,			/* scalar variable */
	PLPGSQL_NSTYPE_REC			/* composite variable */
} PLpgSQL_nsitem_type;

/*
 * A PLPGSQL_NSTYPE_LABEL stack entry must be one of these types
 */
typedef enum PLpgSQL_label_type
{
	PLPGSQL_LABEL_BLOCK,		/* DECLARE/BEGIN block */
	PLPGSQL_LABEL_LOOP,			/* looping construct */
	PLPGSQL_LABEL_OTHER			/* anything else */
} PLpgSQL_label_type;

/*
 * Datum array node types
 */
typedef enum PLpgSQL_datum_type
{
	PLPGSQL_DTYPE_VAR,
	PLPGSQL_DTYPE_ROW,
	PLPGSQL_DTYPE_REC,
	PLPGSQL_DTYPE_RECFIELD,
	PLPGSQL_DTYPE_PROMISE
} PLpgSQL_datum_type;

/*
 * DTYPE_PROMISE datums have these possible ways of computing the promise
 */
typedef enum PLpgSQL_promise_type
{
	PLPGSQL_PROMISE_NONE = 0,	/* not a promise, or promise satisfied */
	PLPGSQL_PROMISE_TG_NAME,
	PLPGSQL_PROMISE_TG_WHEN,
	PLPGSQL_PROMISE_TG_LEVEL,
	PLPGSQL_PROMISE_TG_OP,
	PLPGSQL_PROMISE_TG_RELID,
	PLPGSQL_PROMISE_TG_TABLE_NAME,
	PLPGSQL_PROMISE_TG_TABLE_SCHEMA,
	PLPGSQL_PROMISE_TG_NARGS,
	PLPGSQL_PROMISE_TG_ARGV,
	PLPGSQL_PROMISE_TG_EVENT,
	PLPGSQL_PROMISE_TG_TAG
} PLpgSQL_promise_type;

/*
 * Variants distinguished in PLpgSQL_type structs
 */
typedef enum PLpgSQL_type_type
{
	PLPGSQL_TTYPE_SCALAR,		/* scalar types and domains */
	PLPGSQL_TTYPE_REC,			/* composite types, including RECORD */
	PLPGSQL_TTYPE_PSEUDO		/* pseudotypes */
} PLpgSQL_type_type;

/*
 * Execution tree node types
 */
typedef enum PLpgSQL_stmt_type
{
	PLPGSQL_STMT_BLOCK,
	PLPGSQL_STMT_ASSIGN,
	PLPGSQL_STMT_IF,
	PLPGSQL_STMT_CASE,
	PLPGSQL_STMT_LOOP,
	PLPGSQL_STMT_WHILE,
	PLPGSQL_STMT_FORI,
	PLPGSQL_STMT_FORS,
	PLPGSQL_STMT_FORC,
	PLPGSQL_STMT_FOREACH_A,
	PLPGSQL_STMT_EXIT,
	PLPGSQL_STMT_RETURN,
	PLPGSQL_STMT_RETURN_NEXT,
	PLPGSQL_STMT_RETURN_QUERY,
	PLPGSQL_STMT_RAISE,
	PLPGSQL_STMT_ASSERT,
	PLPGSQL_STMT_EXECSQL,
	PLPGSQL_STMT_DYNEXECUTE,
	PLPGSQL_STMT_DYNFORS,
	PLPGSQL_STMT_GETDIAG,
	PLPGSQL_STMT_OPEN,
	PLPGSQL_STMT_FETCH,
	PLPGSQL_STMT_CLOSE,
	PLPGSQL_STMT_PERFORM,
	PLPGSQL_STMT_CALL,
	PLPGSQL_STMT_COMMIT,
	PLPGSQL_STMT_ROLLBACK
} PLpgSQL_stmt_type;

/*
 * Execution node return codes
 */
enum
{
	PLPGSQL_RC_OK,
	PLPGSQL_RC_EXIT,
	PLPGSQL_RC_RETURN,
	PLPGSQL_RC_CONTINUE
};

/*
 * GET DIAGNOSTICS information items
 */
typedef enum PLpgSQL_getdiag_kind
{
	PLPGSQL_GETDIAG_ROW_COUNT,
	PLPGSQL_GETDIAG_CONTEXT,
	PLPGSQL_GETDIAG_ERROR_CONTEXT,
	PLPGSQL_GETDIAG_ERROR_DETAIL,
	PLPGSQL_GETDIAG_ERROR_HINT,
	PLPGSQL_GETDIAG_RETURNED_SQLSTATE,
	PLPGSQL_GETDIAG_COLUMN_NAME,
	PLPGSQL_GETDIAG_CONSTRAINT_NAME,
	PLPGSQL_GETDIAG_DATATYPE_NAME,
	PLPGSQL_GETDIAG_MESSAGE_TEXT,
	PLPGSQL_GETDIAG_TABLE_NAME,
	PLPGSQL_GETDIAG_SCHEMA_NAME
} PLpgSQL_getdiag_kind;

/*
 * RAISE statement options
 */
typedef enum PLpgSQL_raise_option_type
{
	PLPGSQL_RAISEOPTION_ERRCODE,
	PLPGSQL_RAISEOPTION_MESSAGE,
	PLPGSQL_RAISEOPTION_DETAIL,
	PLPGSQL_RAISEOPTION_HINT,
	PLPGSQL_RAISEOPTION_COLUMN,
	PLPGSQL_RAISEOPTION_CONSTRAINT,
	PLPGSQL_RAISEOPTION_DATATYPE,
	PLPGSQL_RAISEOPTION_TABLE,
	PLPGSQL_RAISEOPTION_SCHEMA
} PLpgSQL_raise_option_type;

/*
 * Behavioral modes for plpgsql variable resolution
 */
typedef enum PLpgSQL_resolve_option
{
	PLPGSQL_RESOLVE_ERROR,		/* throw error if ambiguous */
	PLPGSQL_RESOLVE_VARIABLE,	/* prefer plpgsql var to table column */
	PLPGSQL_RESOLVE_COLUMN		/* prefer table column to plpgsql var */
} PLpgSQL_resolve_option;


/**********************************************************************
 * Node and structure definitions
 **********************************************************************/

/*
 * Postgres data type
 */
typedef struct PLpgSQL_type
{
	char	   *typname;		/* (simple) name of the type */
	Oid			typoid;			/* OID of the data type */
	PLpgSQL_type_type ttype;	/* PLPGSQL_TTYPE_ code */
	int16		typlen;			/* stuff copied from its pg_type entry */
	bool		typbyval;
	char		typtype;
	Oid			collation;		/* from pg_type, but can be overridden */
	bool		typisarray;		/* is "true" array, or domain over one */
	int32		atttypmod;		/* typmod (taken from someplace else) */
	/* Remaining fields are used only for named composite types (not RECORD) */
	TypeName   *origtypname;	/* type name as written by user */
	TypeCacheEntry *tcache;		/* typcache entry for composite type */
	uint64		tupdesc_id;		/* last-seen tupdesc identifier */
} PLpgSQL_type;

/*
 * SQL Query to plan and execute
 */
typedef struct PLpgSQL_expr
{
	char	   *query;			/* query string, verbatim from function body */
	RawParseMode parseMode;		/* raw_parser() mode to use */
	SPIPlanPtr	plan;			/* plan, or NULL if not made yet */
	Bitmapset  *paramnos;		/* all dnos referenced by this query */

	/* function containing this expr (not set until we first parse query) */
	struct PLpgSQL_function *func;

	/* namespace chain visible to this expr */
	struct PLpgSQL_nsitem *ns;

	/* fields for "simple expression" fast-path execution: */
	Expr	   *expr_simple_expr;	/* NULL means not a simple expr */
	Oid			expr_simple_type;	/* result type Oid, if simple */
	int32		expr_simple_typmod; /* result typmod, if simple */
	bool		expr_simple_mutable;	/* true if simple expr is mutable */

	/*
	 * These fields are used to optimize assignments to expanded-datum
	 * variables.  If this expression is the source of an assignment to a
	 * simple variable, target_param holds that variable's dno; else it's -1.
	 * If we match a Param within expr_simple_expr to such a variable, that
	 * Param's address is stored in expr_rw_param; then expression code
	 * generation will allow the value for that Param to be passed read/write.
	 */
	int			target_param;	/* dno of assign target, or -1 if none */
	Param	   *expr_rw_param;	/* read/write Param within expr, if any */

	/*
	 * If the expression was ever determined to be simple, we remember its
	 * CachedPlanSource and CachedPlan here.  If expr_simple_plan_lxid matches
	 * current LXID, then we hold a refcount on expr_simple_plan in the
	 * current transaction.  Otherwise we need to get one before re-using it.
	 */
	CachedPlanSource *expr_simple_plansource;	/* extracted from "plan" */
	CachedPlan *expr_simple_plan;	/* extracted from "plan" */
	LocalTransactionId expr_simple_plan_lxid;

	/*
	 * if expr is simple AND prepared in current transaction,
	 * expr_simple_state and expr_simple_in_use are valid. Test validity by
	 * seeing if expr_simple_lxid matches current LXID.  (If not,
	 * expr_simple_state probably points at garbage!)
	 */
	ExprState  *expr_simple_state;	/* eval tree for expr_simple_expr */
	bool		expr_simple_in_use; /* true if eval tree is active */
	LocalTransactionId expr_simple_lxid;
} PLpgSQL_expr;

/*
 * Generic datum array item
 *
 * PLpgSQL_datum is the common supertype for PLpgSQL_var, PLpgSQL_row,
 * PLpgSQL_rec, and PLpgSQL_recfield.
 */
typedef struct PLpgSQL_datum
{
	PLpgSQL_datum_type dtype;
	int			dno;
} PLpgSQL_datum;

/*
 * Scalar or composite variable
 *
 * The variants PLpgSQL_var, PLpgSQL_row, and PLpgSQL_rec share these
 * fields.
 */
typedef struct PLpgSQL_variable
{
	PLpgSQL_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLpgSQL_expr *default_val;
} PLpgSQL_variable;

/*
 * Scalar variable
 *
 * DTYPE_VAR and DTYPE_PROMISE datums both use this struct type.
 * A PROMISE datum works exactly like a VAR datum for most purposes,
 * but if it is read without having previously been assigned to, then
 * a special "promised" value is computed and assigned to the datum
 * before the read is performed.  This technique avoids the overhead of
 * computing the variable's value in cases where we expect that many
 * functions will never read it.
 */
typedef struct PLpgSQL_var
{
	PLpgSQL_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLpgSQL_expr *default_val;
	/* end of PLpgSQL_variable fields */

	PLpgSQL_type *datatype;

	/*
	 * Variables declared as CURSOR FOR <query> are mostly like ordinary
	 * scalar variables of type refcursor, but they have these additional
	 * properties:
	 */
	PLpgSQL_expr *cursor_explicit_expr;
	int			cursor_explicit_argrow;
	int			cursor_options;

	/* Fields below here can change at runtime */

	Datum		value;
	bool		isnull;
	bool		freeval;

	/*
	 * The promise field records which "promised" value to assign if the
	 * promise must be honored.  If it's a normal variable, or the promise has
	 * been fulfilled, this is PLPGSQL_PROMISE_NONE.
	 */
	PLpgSQL_promise_type promise;
} PLpgSQL_var;

/*
 * Row variable - this represents one or more variables that are listed in an
 * INTO clause, FOR-loop targetlist, cursor argument list, etc.  We also use
 * a row to represent a function's OUT parameters when there's more than one.
 *
 * Note that there's no way to name the row as such from PL/pgSQL code,
 * so many functions don't need to support these.
 *
 * That also means that there's no real name for the row variable, so we
 * conventionally set refname to "(unnamed row)".  We could leave it NULL,
 * but it's too convenient to be able to assume that refname is valid in
 * all variants of PLpgSQL_variable.
 *
 * isconst, notnull, and default_val are unsupported (and hence
 * always zero/null) for a row.  The member variables of a row should have
 * been checked to be writable at compile time, so isconst is correctly set
 * to false.  notnull and default_val aren't applicable.
 */
typedef struct PLpgSQL_row
{
	PLpgSQL_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLpgSQL_expr *default_val;
	/* end of PLpgSQL_variable fields */

	/*
	 * rowtupdesc is only set up if we might need to convert the row into a
	 * composite datum, which currently only happens for OUT parameters.
	 * Otherwise it is NULL.
	 */
	TupleDesc	rowtupdesc;

	int			nfields;
	char	  **fieldnames;
	int		   *varnos;
} PLpgSQL_row;

/*
 * Record variable (any composite type, including RECORD)
 */
typedef struct PLpgSQL_rec
{
	PLpgSQL_datum_type dtype;
	int			dno;
	char	   *refname;
	int			lineno;
	bool		isconst;
	bool		notnull;
	PLpgSQL_expr *default_val;
	/* end of PLpgSQL_variable fields */

	/*
	 * Note: for non-RECORD cases, we may from time to time re-look-up the
	 * composite type, using datatype->origtypname.  That can result in
	 * changing rectypeid.
	 */

	PLpgSQL_type *datatype;		/* can be NULL, if rectypeid is RECORDOID */
	Oid			rectypeid;		/* declared type of variable */
	/* RECFIELDs for this record are chained together for easy access */
	int			firstfield;		/* dno of first RECFIELD, or -1 if none */

	/* Fields below here can change at runtime */

	/* We always store record variables as "expanded" records */
	ExpandedRecordHeader *erh;
} PLpgSQL_rec;

/*
 * Field in record
 */
typedef struct PLpgSQL_recfield
{
	PLpgSQL_datum_type dtype;
	int			dno;
	/* end of PLpgSQL_datum fields */

	char	   *fieldname;		/* name of field */
	int			recparentno;	/* dno of parent record */
	int			nextfield;		/* dno of next child, or -1 if none */
	uint64		rectupledescid; /* record's tupledesc ID as of last lookup */
	ExpandedRecordFieldInfo finfo;	/* field's attnum and type info */
	/* if rectupledescid == INVALID_TUPLEDESC_IDENTIFIER, finfo isn't valid */
} PLpgSQL_recfield;

/*
 * Item in the compilers namespace tree
 */
typedef struct PLpgSQL_nsitem
{
	PLpgSQL_nsitem_type itemtype;

	/*
	 * For labels, itemno is a value of enum PLpgSQL_label_type. For other
	 * itemtypes, itemno is the associated PLpgSQL_datum's dno.
	 */
	int			itemno;
	struct PLpgSQL_nsitem *prev;
	char		name[FLEXIBLE_ARRAY_MEMBER];	/* nul-terminated string */
} PLpgSQL_nsitem;

/*
 * Generic execution node
 */
typedef struct PLpgSQL_stmt
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;

	/*
	 * Unique statement ID in this function (starting at 1; 0 is invalid/not
	 * set).  This can be used by a profiler as the index for an array of
	 * per-statement metrics.
	 */
	unsigned int stmtid;
} PLpgSQL_stmt;

/*
 * One EXCEPTION condition name
 */
typedef struct PLpgSQL_condition
{
	int			sqlerrstate;	/* SQLSTATE code */
	char	   *condname;		/* condition name (for debugging) */
	struct PLpgSQL_condition *next;
} PLpgSQL_condition;

/*
 * EXCEPTION block
 */
typedef struct PLpgSQL_exception_block
{
	int			sqlstate_varno;
	int			sqlerrm_varno;
	List	   *exc_list;		/* List of WHEN clauses */
} PLpgSQL_exception_block;

/*
 * One EXCEPTION ... WHEN clause
 */
typedef struct PLpgSQL_exception
{
	int			lineno;
	PLpgSQL_condition *conditions;
	List	   *action;			/* List of statements */
} PLpgSQL_exception;

/*
 * Block of statements
 */
typedef struct PLpgSQL_stmt_block
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	List	   *body;			/* List of statements */
	int			n_initvars;		/* Length of initvarnos[] */
	int		   *initvarnos;		/* dnos of variables declared in this block */
	PLpgSQL_exception_block *exceptions;
} PLpgSQL_stmt_block;

/*
 * Assign statement
 */
typedef struct PLpgSQL_stmt_assign
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	int			varno;
	PLpgSQL_expr *expr;
} PLpgSQL_stmt_assign;

/*
 * PERFORM statement
 */
typedef struct PLpgSQL_stmt_perform
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *expr;
} PLpgSQL_stmt_perform;

/*
 * CALL statement
 */
typedef struct PLpgSQL_stmt_call
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *expr;
	bool		is_call;
	PLpgSQL_variable *target;
} PLpgSQL_stmt_call;

/*
 * COMMIT statement
 */
typedef struct PLpgSQL_stmt_commit
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	bool		chain;
} PLpgSQL_stmt_commit;

/*
 * ROLLBACK statement
 */
typedef struct PLpgSQL_stmt_rollback
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	bool		chain;
} PLpgSQL_stmt_rollback;

/*
 * GET DIAGNOSTICS item
 */
typedef struct PLpgSQL_diag_item
{
	PLpgSQL_getdiag_kind kind;	/* id for diagnostic value desired */
	int			target;			/* where to assign it */
} PLpgSQL_diag_item;

/*
 * GET DIAGNOSTICS statement
 */
typedef struct PLpgSQL_stmt_getdiag
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	bool		is_stacked;		/* STACKED or CURRENT diagnostics area? */
	List	   *diag_items;		/* List of PLpgSQL_diag_item */
} PLpgSQL_stmt_getdiag;

/*
 * IF statement
 */
typedef struct PLpgSQL_stmt_if
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *cond;			/* boolean expression for THEN */
	List	   *then_body;		/* List of statements */
	List	   *elsif_list;		/* List of PLpgSQL_if_elsif structs */
	List	   *else_body;		/* List of statements */
} PLpgSQL_stmt_if;

/*
 * one ELSIF arm of IF statement
 */
typedef struct PLpgSQL_if_elsif
{
	int			lineno;
	PLpgSQL_expr *cond;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLpgSQL_if_elsif;

/*
 * CASE statement
 */
typedef struct PLpgSQL_stmt_case
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *t_expr;		/* test expression, or NULL if none */
	int			t_varno;		/* var to store test expression value into */
	List	   *case_when_list; /* List of PLpgSQL_case_when structs */
	bool		have_else;		/* flag needed because list could be empty */
	List	   *else_stmts;		/* List of statements */
} PLpgSQL_stmt_case;

/*
 * one arm of CASE statement
 */
typedef struct PLpgSQL_case_when
{
	int			lineno;
	PLpgSQL_expr *expr;			/* boolean expression for this case */
	List	   *stmts;			/* List of statements */
} PLpgSQL_case_when;

/*
 * Unconditional LOOP statement
 */
typedef struct PLpgSQL_stmt_loop
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	List	   *body;			/* List of statements */
} PLpgSQL_stmt_loop;

/*
 * WHILE cond LOOP statement
 */
typedef struct PLpgSQL_stmt_while
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_expr *cond;
	List	   *body;			/* List of statements */
} PLpgSQL_stmt_while;

/*
 * FOR statement with integer loopvar
 */
typedef struct PLpgSQL_stmt_fori
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_var *var;
	PLpgSQL_expr *lower;
	PLpgSQL_expr *upper;
	PLpgSQL_expr *step;			/* NULL means default (ie, BY 1) */
	int			reverse;
	List	   *body;			/* List of statements */
} PLpgSQL_stmt_fori;

/*
 * PLpgSQL_stmt_forq represents a FOR statement running over a SQL query.
 * It is the common supertype of PLpgSQL_stmt_fors, PLpgSQL_stmt_forc
 * and PLpgSQL_stmt_dynfors.
 */
typedef struct PLpgSQL_stmt_forq
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
} PLpgSQL_stmt_forq;

/*
 * FOR statement running over SELECT
 */
typedef struct PLpgSQL_stmt_fors
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLpgSQL_stmt_forq */
	PLpgSQL_expr *query;
} PLpgSQL_stmt_fors;

/*
 * FOR statement running over cursor
 */
typedef struct PLpgSQL_stmt_forc
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLpgSQL_stmt_forq */
	int			curvar;
	PLpgSQL_expr *argquery;		/* cursor arguments if any */
} PLpgSQL_stmt_forc;

/*
 * FOR statement running over EXECUTE
 */
typedef struct PLpgSQL_stmt_dynfors
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	PLpgSQL_variable *var;		/* Loop variable (record or row) */
	List	   *body;			/* List of statements */
	/* end of fields that must match PLpgSQL_stmt_forq */
	PLpgSQL_expr *query;
	List	   *params;			/* USING expressions */
} PLpgSQL_stmt_dynfors;

/*
 * FOREACH item in array loop
 */
typedef struct PLpgSQL_stmt_foreach_a
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	char	   *label;
	int			varno;			/* loop target variable */
	int			slice;			/* slice dimension, or 0 */
	PLpgSQL_expr *expr;			/* array expression */
	List	   *body;			/* List of statements */
} PLpgSQL_stmt_foreach_a;

/*
 * OPEN a curvar
 */
typedef struct PLpgSQL_stmt_open
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	int			curvar;
	int			cursor_options;
	PLpgSQL_expr *argquery;
	PLpgSQL_expr *query;
	PLpgSQL_expr *dynquery;
	List	   *params;			/* USING expressions */
} PLpgSQL_stmt_open;

/*
 * FETCH or MOVE statement
 */
typedef struct PLpgSQL_stmt_fetch
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_variable *target;	/* target (record or row) */
	int			curvar;			/* cursor variable to fetch from */
	FetchDirection direction;	/* fetch direction */
	long		how_many;		/* count, if constant (expr is NULL) */
	PLpgSQL_expr *expr;			/* count, if expression */
	bool		is_move;		/* is this a fetch or move? */
	bool		returns_multiple_rows;	/* can return more than one row? */
} PLpgSQL_stmt_fetch;

/*
 * CLOSE curvar
 */
typedef struct PLpgSQL_stmt_close
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	int			curvar;
} PLpgSQL_stmt_close;

/*
 * EXIT or CONTINUE statement
 */
typedef struct PLpgSQL_stmt_exit
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	bool		is_exit;		/* Is this an exit or a continue? */
	char	   *label;			/* NULL if it's an unlabeled EXIT/CONTINUE */
	PLpgSQL_expr *cond;
} PLpgSQL_stmt_exit;

/*
 * RETURN statement
 */
typedef struct PLpgSQL_stmt_return
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *expr;
	int			retvarno;
} PLpgSQL_stmt_return;

/*
 * RETURN NEXT statement
 */
typedef struct PLpgSQL_stmt_return_next
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *expr;
	int			retvarno;
} PLpgSQL_stmt_return_next;

/*
 * RETURN QUERY statement
 */
typedef struct PLpgSQL_stmt_return_query
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *query;		/* if static query */
	PLpgSQL_expr *dynquery;		/* if dynamic query (RETURN QUERY EXECUTE) */
	List	   *params;			/* USING arguments for dynamic query */
} PLpgSQL_stmt_return_query;

/*
 * RAISE statement
 */
typedef struct PLpgSQL_stmt_raise
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	int			elog_level;
	char	   *condname;		/* condition name, SQLSTATE, or NULL */
	char	   *message;		/* old-style message format literal, or NULL */
	List	   *params;			/* list of expressions for old-style message */
	List	   *options;		/* list of PLpgSQL_raise_option */
} PLpgSQL_stmt_raise;

/*
 * RAISE statement option
 */
typedef struct PLpgSQL_raise_option
{
	PLpgSQL_raise_option_type opt_type;
	PLpgSQL_expr *expr;
} PLpgSQL_raise_option;

/*
 * ASSERT statement
 */
typedef struct PLpgSQL_stmt_assert
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *cond;
	PLpgSQL_expr *message;
} PLpgSQL_stmt_assert;

/*
 * Generic SQL statement to execute
 */
typedef struct PLpgSQL_stmt_execsql
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *sqlstmt;
	bool		mod_stmt;		/* is the stmt INSERT/UPDATE/DELETE/MERGE? */
	bool		mod_stmt_set;	/* is mod_stmt valid yet? */
	bool		into;			/* INTO supplied? */
	bool		strict;			/* INTO STRICT flag */
	PLpgSQL_variable *target;	/* INTO target (record or row) */
} PLpgSQL_stmt_execsql;

/*
 * Dynamic SQL string to execute
 */
typedef struct PLpgSQL_stmt_dynexecute
{
	PLpgSQL_stmt_type cmd_type;
	int			lineno;
	unsigned int stmtid;
	PLpgSQL_expr *query;		/* string expression */
	bool		into;			/* INTO supplied? */
	bool		strict;			/* INTO STRICT flag */
	PLpgSQL_variable *target;	/* INTO target (record or row) */
	List	   *params;			/* USING expressions */
} PLpgSQL_stmt_dynexecute;

/*
 * Hash lookup key for functions
 */
typedef struct PLpgSQL_func_hashkey
{
	Oid			funcOid;

	bool		isTrigger;		/* true if called as a DML trigger */
	bool		isEventTrigger; /* true if called as an event trigger */

	/* be careful that pad bytes in this struct get zeroed! */

	/*
	 * For a trigger function, the OID of the trigger is part of the hash key
	 * --- we want to compile the trigger function separately for each trigger
	 * it is used with, in case the rowtype or transition table names are
	 * different.  Zero if not called as a DML trigger.
	 */
	Oid			trigOid;

	/*
	 * We must include the input collation as part of the hash key too,
	 * because we have to generate different plans (with different Param
	 * collations) for different collation settings.
	 */
	Oid			inputCollation;

	/*
	 * We include actual argument types in the hash key to support polymorphic
	 * PLpgSQL functions.  Be careful that extra positions are zeroed!
	 */
	Oid			argtypes[FUNC_MAX_ARGS];
} PLpgSQL_func_hashkey;

/*
 * Trigger type
 */
typedef enum PLpgSQL_trigtype
{
	PLPGSQL_DML_TRIGGER,
	PLPGSQL_EVENT_TRIGGER,
	PLPGSQL_NOT_TRIGGER
} PLpgSQL_trigtype;

/*
 * Complete compiled function
 */
typedef struct PLpgSQL_function
{
	char	   *fn_signature;
	Oid			fn_oid;
	TransactionId fn_xmin;
	ItemPointerData fn_tid;
	PLpgSQL_trigtype fn_is_trigger;
	Oid			fn_input_collation;
	PLpgSQL_func_hashkey *fn_hashkey;	/* back-link to hashtable key */
	MemoryContext fn_cxt;

	Oid			fn_rettype;
	int			fn_rettyplen;
	bool		fn_retbyval;
	bool		fn_retistuple;
	bool		fn_retisdomain;
	bool		fn_retset;
	bool		fn_readonly;
	char		fn_prokind;

	int			fn_nargs;
	int			fn_argvarnos[FUNC_MAX_ARGS];
	int			out_param_varno;
	int			found_varno;
	int			new_varno;
	int			old_varno;

	PLpgSQL_resolve_option resolve_option;

	bool		print_strict_params;

	/* extra checks */
	int			extra_warnings;
	int			extra_errors;

	/* the datums representing the function's local variables */
	int			ndatums;
	PLpgSQL_datum **datums;
	Size		copiable_size;	/* space for locally instantiated datums */

	/* function body parsetree */
	PLpgSQL_stmt_block *action;

	/* data derived while parsing body */
	unsigned int nstatements;	/* counter for assigning stmtids */
	bool		requires_procedure_resowner;	/* contains CALL or DO? */

	/* these fields change when the function is used */
	struct PLpgSQL_execstate *cur_estate;
	unsigned long use_count;
} PLpgSQL_function;

/*
 * Runtime execution data
 */
typedef struct PLpgSQL_execstate
{
	PLpgSQL_function *func;		/* function being executed */

	TriggerData *trigdata;		/* if regular trigger, data about firing */
	EventTriggerData *evtrigdata;	/* if event trigger, data about firing */

	Datum		retval;
	bool		retisnull;
	Oid			rettype;		/* type of current retval */

	Oid			fn_rettype;		/* info about declared function rettype */
	bool		retistuple;
	bool		retisset;

	bool		readonly_func;
	bool		atomic;

	char	   *exitlabel;		/* the "target" label of the current EXIT or
								 * CONTINUE stmt, if any */
	ErrorData  *cur_error;		/* current exception handler's error */

	Tuplestorestate *tuple_store;	/* SRFs accumulate results here */
	TupleDesc	tuple_store_desc;	/* descriptor for tuples in tuple_store */
	MemoryContext tuple_store_cxt;
	ResourceOwner tuple_store_owner;
	ReturnSetInfo *rsi;

	int			found_varno;

	/*
	 * The datums representing the function's local variables.  Some of these
	 * are local storage in this execstate, but some just point to the shared
	 * copy belonging to the PLpgSQL_function, depending on whether or not we
	 * need any per-execution state for the datum's dtype.
	 */
	int			ndatums;
	PLpgSQL_datum **datums;
	/* context containing variable values (same as func's SPI_proc context) */
	MemoryContext datum_context;

	/*
	 * paramLI is what we use to pass local variable values to the executor.
	 * It does not have a ParamExternData array; we just dynamically
	 * instantiate parameter data as needed.  By convention, PARAM_EXTERN
	 * Params have paramid equal to the dno of the referenced local variable.
	 */
	ParamListInfo paramLI;

	/* EState and resowner to use for "simple" expression evaluation */
	EState	   *simple_eval_estate;
	ResourceOwner simple_eval_resowner;

	/* if running nonatomic procedure or DO block, resowner to use for CALL */
	ResourceOwner procedure_resowner;

	/* lookup table to use for executing type casts */
	HTAB	   *cast_hash;
	MemoryContext cast_hash_context;

	/* memory context for statement-lifespan temporary values */
	MemoryContext stmt_mcontext;	/* current stmt context, or NULL if none */
	MemoryContext stmt_mcontext_parent; /* parent of current context */

	/* temporary state for results from evaluation of query or expr */
	SPITupleTable *eval_tuptable;
	uint64		eval_processed;
	ExprContext *eval_econtext; /* for executing simple expressions */

	/* status information for error context reporting */
	PLpgSQL_stmt *err_stmt;		/* current stmt */
	PLpgSQL_variable *err_var;	/* current variable, if in a DECLARE section */
	const char *err_text;		/* additional state info */

	void	   *plugin_info;	/* reserved for use by optional plugin */
} PLpgSQL_execstate;

/*
 * A PLpgSQL_plugin structure represents an instrumentation plugin.
 * To instrument PL/pgSQL, a plugin library must access the rendezvous
 * variable "PLpgSQL_plugin" and set it to point to a PLpgSQL_plugin struct.
 * Typically the struct could just be static data in the plugin library.
 * We expect that a plugin would do this at library load time (_PG_init()).
 *
 * This structure is basically a collection of function pointers --- at
 * various interesting points in pl_exec.c, we call these functions
 * (if the pointers are non-NULL) to give the plugin a chance to watch
 * what we are doing.
 *
 * func_setup is called when we start a function, before we've initialized
 * the local variables defined by the function.
 *
 * func_beg is called when we start a function, after we've initialized
 * the local variables.
 *
 * func_end is called at the end of a function.
 *
 * stmt_beg and stmt_end are called before and after (respectively) each
 * statement.
 *
 * Also, immediately before any call to func_setup, PL/pgSQL fills in the
 * remaining fields with pointers to some of its own functions, allowing the
 * plugin to invoke those functions conveniently.  The exposed functions are:
 *		plpgsql_exec_error_callback
 *		exec_assign_expr
 *		exec_assign_value
 *		exec_eval_datum
 *		exec_cast_value
 * (plpgsql_exec_error_callback is not actually meant to be called by the
 * plugin, but rather to allow it to identify PL/pgSQL error context stack
 * frames.  The others are useful for debugger-like plugins to examine and
 * set variables.)
 */
typedef struct PLpgSQL_plugin
{
	/* Function pointers set up by the plugin */
	void		(*func_setup) (PLpgSQL_execstate *estate, PLpgSQL_function *func);
	void		(*func_beg) (PLpgSQL_execstate *estate, PLpgSQL_function *func);
	void		(*func_end) (PLpgSQL_execstate *estate, PLpgSQL_function *func);
	void		(*stmt_beg) (PLpgSQL_execstate *estate, PLpgSQL_stmt *stmt);
	void		(*stmt_end) (PLpgSQL_execstate *estate, PLpgSQL_stmt *stmt);

	/* Function pointers set by PL/pgSQL itself */
	void		(*error_callback) (void *arg);
	void		(*assign_expr) (PLpgSQL_execstate *estate,
								PLpgSQL_datum *target,
								PLpgSQL_expr *expr);
	void		(*assign_value) (PLpgSQL_execstate *estate,
								 PLpgSQL_datum *target,
								 Datum value, bool isNull,
								 Oid valtype, int32 valtypmod);
	void		(*eval_datum) (PLpgSQL_execstate *estate, PLpgSQL_datum *datum,
							   Oid *typeId, int32 *typetypmod,
							   Datum *value, bool *isnull);
	Datum		(*cast_value) (PLpgSQL_execstate *estate,
							   Datum value, bool *isnull,
							   Oid valtype, int32 valtypmod,
							   Oid reqtype, int32 reqtypmod);
} PLpgSQL_plugin;

/*
 * Struct types used during parsing
 */

typedef struct PLword
{
	char	   *ident;			/* palloc'd converted identifier */
	bool		quoted;			/* Was it double-quoted? */
} PLword;

typedef struct PLcword
{
	List	   *idents;			/* composite identifiers (list of String) */
} PLcword;

typedef struct PLwdatum
{
	PLpgSQL_datum *datum;		/* referenced variable */
	char	   *ident;			/* valid if simple name */
	bool		quoted;
	List	   *idents;			/* valid if composite name */
} PLwdatum;

/**********************************************************************
 * Global variable declarations
 **********************************************************************/

typedef enum
{
	IDENTIFIER_LOOKUP_NORMAL,	/* normal processing of var names */
	IDENTIFIER_LOOKUP_DECLARE,	/* In DECLARE --- don't look up names */
	IDENTIFIER_LOOKUP_EXPR		/* In SQL expression --- special case */
} IdentifierLookup;

extern __thread  IdentifierLookup plpgsql_IdentifierLookup;

extern __thread  int plpgsql_variable_conflict;

extern __thread  bool plpgsql_print_strict_params;

extern bool plpgsql_check_asserts;

/* extra compile-time and run-time checks */
#define PLPGSQL_XCHECK_NONE						0
#define PLPGSQL_XCHECK_SHADOWVAR				(1 << 1)
#define PLPGSQL_XCHECK_TOOMANYROWS				(1 << 2)
#define PLPGSQL_XCHECK_STRICTMULTIASSIGNMENT	(1 << 3)
#define PLPGSQL_XCHECK_ALL						((int) ~0)

extern int	plpgsql_extra_warnings;
extern int	plpgsql_extra_errors;

extern __thread  bool plpgsql_check_syntax;
extern __thread  bool plpgsql_DumpExecTree;

extern __thread  PLpgSQL_stmt_block *plpgsql_parse_result;

extern __thread  int plpgsql_nDatums;
extern __thread  PLpgSQL_datum **plpgsql_Datums;

extern __thread  char *plpgsql_error_funcname;

extern __thread  PLpgSQL_function *plpgsql_curr_compile;
extern __thread  MemoryContext plpgsql_compile_tmp_cxt;

extern PLpgSQL_plugin **plpgsql_plugin_ptr;

/**********************************************************************
 * Function declarations
 **********************************************************************/

/*
 * Functions in pl_comp.c
 */
extern PLpgSQL_function *plpgsql_compile(FunctionCallInfo fcinfo,
										 bool forValidator);
extern PLpgSQL_function *plpgsql_compile_inline(char *proc_source);
extern void plpgsql_parser_setup(struct ParseState *pstate,
								 PLpgSQL_expr *expr);
extern bool plpgsql_parse_word(char *word1, const char *yytxt, bool lookup,
							   PLwdatum *wdatum, PLword *word);
extern bool plpgsql_parse_dblword(char *word1, char *word2,
								  PLwdatum *wdatum, PLcword *cword);
extern bool plpgsql_parse_tripword(char *word1, char *word2, char *word3,
								   PLwdatum *wdatum, PLcword *cword);
extern PLpgSQL_type *plpgsql_parse_wordtype(char *ident);
extern PLpgSQL_type *plpgsql_parse_cwordtype(List *idents);
extern PLpgSQL_type *plpgsql_parse_wordrowtype(char *ident);
extern PLpgSQL_type *plpgsql_parse_cwordrowtype(List *idents);
extern PLpgSQL_type *plpgsql_build_datatype(Oid typeOid, int32 typmod,
											Oid collation,
											TypeName *origtypname);
extern PLpgSQL_variable *plpgsql_build_variable(const char *refname, int lineno,
												PLpgSQL_type *dtype,
												bool add2namespace);
extern PLpgSQL_rec *plpgsql_build_record(const char *refname, int lineno,
										 PLpgSQL_type *dtype, Oid rectypeid,
										 bool add2namespace);
extern PLpgSQL_recfield *plpgsql_build_recfield(PLpgSQL_rec *rec,
												const char *fldname);
extern int	plpgsql_recognize_err_condition(const char *condname,
											bool allow_sqlstate);
extern PLpgSQL_condition *plpgsql_parse_err_condition(char *condname);
extern void plpgsql_start_datums(void);
extern void plpgsql_finish_datums(PLpgSQL_function *function);
extern void plpgsql_adddatum(PLpgSQL_datum *newdatum);
extern int	plpgsql_add_initdatums(int **varnos);
extern void plpgsql_HashTableInit(void);

/*
 * Functions in pl_handler.c
 */
extern void _PG_init(void);

/*
 * Functions in pl_exec.c
 */
extern Datum plpgsql_exec_function(PLpgSQL_function *func,
								   FunctionCallInfo fcinfo,
								   EState *simple_eval_estate,
								   ResourceOwner simple_eval_resowner,
								   ResourceOwner procedure_resowner,
								   bool atomic);
extern HeapTuple plpgsql_exec_trigger(PLpgSQL_function *func,
									  TriggerData *trigdata);
extern void plpgsql_exec_event_trigger(PLpgSQL_function *func,
									   EventTriggerData *trigdata);
extern void plpgsql_xact_cb(XactEvent event, void *arg);
extern void plpgsql_subxact_cb(SubXactEvent event, SubTransactionId mySubid,
							   SubTransactionId parentSubid, void *arg);
extern Oid	plpgsql_exec_get_datum_type(PLpgSQL_execstate *estate,
										PLpgSQL_datum *datum);
extern void plpgsql_exec_get_datum_type_info(PLpgSQL_execstate *estate,
											 PLpgSQL_datum *datum,
											 Oid *typeId, int32 *typMod,
											 Oid *collation);

/*
 * Functions for namespace handling in pl_funcs.c
 */
extern void plpgsql_ns_init(void);
extern void plpgsql_ns_push(const char *label,
							PLpgSQL_label_type label_type);
extern void plpgsql_ns_pop(void);
extern PLpgSQL_nsitem *plpgsql_ns_top(void);
extern void plpgsql_ns_additem(PLpgSQL_nsitem_type itemtype, int itemno, const char *name);
extern PLpgSQL_nsitem *plpgsql_ns_lookup(PLpgSQL_nsitem *ns_cur, bool localmode,
										 const char *name1, const char *name2,
										 const char *name3, int *names_used);
extern PLpgSQL_nsitem *plpgsql_ns_lookup_label(PLpgSQL_nsitem *ns_cur,
											   const char *name);
extern PLpgSQL_nsitem *plpgsql_ns_find_nearest_loop(PLpgSQL_nsitem *ns_cur);

/*
 * Other functions in pl_funcs.c
 */
extern const char *plpgsql_stmt_typename(PLpgSQL_stmt *stmt);
extern const char *plpgsql_getdiag_kindname(PLpgSQL_getdiag_kind kind);
extern void plpgsql_free_function_memory(PLpgSQL_function *func);
extern void plpgsql_dumptree(PLpgSQL_function *func);

/*
 * Scanner functions in pl_scanner.c
 */
extern int	plpgsql_base_yylex(void);
extern int	plpgsql_yylex(void);
extern void plpgsql_push_back_token(int token);
extern bool plpgsql_token_is_unreserved_keyword(int token);
extern void plpgsql_append_source_text(StringInfo buf,
									   int startlocation, int endlocation);
extern int	plpgsql_peek(void);
extern void plpgsql_peek2(int *tok1_p, int *tok2_p, int *tok1_loc,
						  int *tok2_loc);
extern int	plpgsql_scanner_errposition(int location);
extern void plpgsql_yyerror(const char *message) pg_attribute_noreturn();
extern int	plpgsql_location_to_lineno(int location);
extern int	plpgsql_latest_lineno(void);
extern void plpgsql_scanner_init(const char *str);
extern void plpgsql_scanner_finish(void);

/*
 * Externs in gram.y
 */
extern int	plpgsql_yyparse(void);

#endif							/* PLPGSQL_H */
