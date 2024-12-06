#include "pg_query.h"
#include "pg_query_internal.h"
#include "pg_query_fingerprint.h"

#include "parser/parser.h"
#include "parser/scanner.h"
#include "parser/scansup.h"
#include "mb/pg_wchar.h"
#include "nodes/nodeFuncs.h"

#include "pg_query_outfuncs.h"

/*
 * Struct for tracking locations/lengths of constants during normalization
 */
typedef struct pgssLocationLen
{
	int			location;		/* start offset in query text */
	int			length;			/* length in bytes, or -1 to ignore */
	int			param_id;		/* Param id to use - if negative prefix, need to abs(..) and add highest_extern_param_id */
} pgssLocationLen;

/*
 * Working state for constant tree walker
 */
typedef struct pgssConstLocations
{
	/* Array of locations of constants that should be removed */
	pgssLocationLen *clocations;

	/* Allocated length of clocations array */
	int			clocations_buf_size;

	/* Current number of valid entries in clocations array */
	int			clocations_count;

	/* highest Param id we have assigned, not yet taking into account external param refs */
	int			highest_normalize_param_id;

	/* highest Param id we've seen, in order to start normalization correctly */
	int			highest_extern_param_id;

	/* query text */
	const char * query;
	int			query_len;

	/* optional recording of assigned or discovered param refs, only active if param_refs is not NULL */
	int *param_refs;
	int param_refs_buf_size;
	int param_refs_count;
} pgssConstLocations;

/*
 * Intermediate working state struct to remember param refs for individual target list elements
 */
typedef struct FpAndParamRefs
{
	uint64_t fp;
	int* param_refs;
	int param_refs_count;
} FpAndParamRefs;

/*
 * comp_location: comparator for qsorting pgssLocationLen structs by location
 */
static int
comp_location(const void *a, const void *b)
{
	int			l = ((const pgssLocationLen *) a)->location;
	int			r = ((const pgssLocationLen *) b)->location;

	if (l < r)
		return -1;
	else if (l > r)
		return +1;
	else
		return 0;
}

/*
 * Given a valid SQL string and an array of constant-location records,
 * fill in the textual lengths of those constants.
 *
 * The constants may use any allowed constant syntax, such as float literals,
 * bit-strings, single-quoted strings and dollar-quoted strings.  This is
 * accomplished by using the public API for the core scanner.
 *
 * It is the caller's job to ensure that the string is a valid SQL statement
 * with constants at the indicated locations.  Since in practice the string
 * has already been parsed, and the locations that the caller provides will
 * have originated from within the authoritative parser, this should not be
 * a problem.
 *
 * Duplicate constant pointers are possible, and will have their lengths
 * marked as '-1', so that they are later ignored.  (Actually, we assume the
 * lengths were initialized as -1 to start with, and don't change them here.)
 *
 * N.B. There is an assumption that a '-' character at a Const location begins
 * a negative numeric constant.  This precludes there ever being another
 * reason for a constant to start with a '-'.
 */
static void
fill_in_constant_lengths(pgssConstLocations *jstate, const char *query)
{
	pgssLocationLen *locs;
	core_yyscan_t yyscanner;
	core_yy_extra_type yyextra;
	core_YYSTYPE yylval;
	YYLTYPE		yylloc;
	int			last_loc = -1;
	int			i;

	/*
	 * Sort the records by location so that we can process them in order while
	 * scanning the query text.
	 */
	if (jstate->clocations_count > 1)
		qsort(jstate->clocations, jstate->clocations_count,
			  sizeof(pgssLocationLen), comp_location);
	locs = jstate->clocations;

	/* initialize the flex scanner --- should match raw_parser() */
	yyscanner = scanner_init(query,
							 &yyextra,
							 &ScanKeywords,
							 ScanKeywordTokens);

	/* Search for each constant, in sequence */
	for (i = 0; i < jstate->clocations_count; i++)
	{
		int			loc = locs[i].location;
		int			tok;

		Assert(loc >= 0);

		if (loc <= last_loc)
			continue;			/* Duplicate constant, ignore */

		/* Lex tokens until we find the desired constant */
		for (;;)
		{
			tok = core_yylex(&yylval, &yylloc, yyscanner);

			/* We should not hit end-of-string, but if we do, behave sanely */
			if (tok == 0)
				break;			/* out of inner for-loop */

			/*
			 * We should find the token position exactly, but if we somehow
			 * run past it, work with that.
			 */
			if (yylloc >= loc)
			{
				if (query[loc] == '-')
				{
					/*
					 * It's a negative value - this is the one and only case
					 * where we replace more than a single token.
					 *
					 * Do not compensate for the core system's special-case
					 * adjustment of location to that of the leading '-'
					 * operator in the event of a negative constant.  It is
					 * also useful for our purposes to start from the minus
					 * symbol.  In this way, queries like "select * from foo
					 * where bar = 1" and "select * from foo where bar = -2"
					 * will have identical normalized query strings.
					 */
					tok = core_yylex(&yylval, &yylloc, yyscanner);
					if (tok == 0)
						break;	/* out of inner for-loop */
				}

				/*
				 * We now rely on the assumption that flex has placed a zero
				 * byte after the text of the current token in scanbuf.
				 */
				locs[i].length = (int) strlen(yyextra.scanbuf + loc);

				/* Quoted string with Unicode escapes
				 *
				 * The lexer consumes trailing whitespace in order to find UESCAPE, but if there
				 * is no UESCAPE it has still consumed it - don't include it in constant length.
				 */
				if (locs[i].length > 4 && /* U&'' */
					(yyextra.scanbuf[loc] == 'u' || yyextra.scanbuf[loc] == 'U') &&
					 yyextra.scanbuf[loc + 1] == '&' && yyextra.scanbuf[loc + 2] == '\'')
				{
					int j = locs[i].length - 1; /* Skip the \0 */
					for (; j >= 0 && scanner_isspace(yyextra.scanbuf[loc + j]); j--) {}
					locs[i].length = j + 1; /* Count the \0 */
				}

				break;			/* out of inner for-loop */
			}
		}

		/* If we hit end-of-string, give up, leaving remaining lengths -1 */
		if (tok == 0)
			break;

		last_loc = loc;
	}

	scanner_finish(yyscanner);
}

/*
 * Generate a normalized version of the query string that will be used to
 * represent all similar queries.
 *
 * Note that the normalized representation may well vary depending on
 * just which "equivalent" query is used to create the hashtable entry.
 * We assume this is OK.
 *
 * *query_len_p contains the input string length, and is updated with
 * the result string length (which cannot be longer) on exit.
 *
 * Returns a palloc'd string.
 */
static char *
generate_normalized_query(pgssConstLocations *jstate, int query_loc, int* query_len_p, int encoding)
{
	char	   *norm_query;
	const char *query = jstate->query;
	int			query_len = *query_len_p;
	int			i,
				norm_query_buflen,		/* Space allowed for norm_query */
				len_to_wrt,		/* Length (in bytes) to write */
				quer_loc = 0,	/* Source query byte location */
				n_quer_loc = 0, /* Normalized query byte location */
				last_off = 0,	/* Offset from start for previous tok */
				last_tok_len = 0;		/* Length (in bytes) of that tok */

	/*
	 * Get constants' lengths (core system only gives us locations).  Note
	 * this also ensures the items are sorted by location.
	 */
	fill_in_constant_lengths(jstate, query);

	/*
	 * Allow for $n symbols to be longer than the constants they replace.
	 * Constants must take at least one byte in text form, while a $n symbol
	 * certainly isn't more than 11 bytes, even if n reaches INT_MAX.  We
	 * could refine that limit based on the max value of n for the current
	 * query, but it hardly seems worth any extra effort to do so.
	 */
	norm_query_buflen = query_len + jstate->clocations_count * 10;

	/* Allocate result buffer */
	norm_query = palloc(norm_query_buflen + 1);

	for (i = 0; i < jstate->clocations_count; i++)
	{
		int			off,		/* Offset from start for cur tok */
					tok_len,	/* Length (in bytes) of that tok */
					param_id;	/* Param ID to be assigned */

		off = jstate->clocations[i].location;
		/* Adjust recorded location if we're dealing with partial string */
		off -= query_loc;

		tok_len = jstate->clocations[i].length;

		if (tok_len < 0)
			continue;			/* ignore any duplicates */

		/* Copy next chunk (what precedes the next constant) */
		len_to_wrt = off - last_off;
		len_to_wrt -= last_tok_len;

		Assert(len_to_wrt >= 0);
		memcpy(norm_query + n_quer_loc, query + quer_loc, len_to_wrt);
		n_quer_loc += len_to_wrt;

		/* And insert a param symbol in place of the constant token */
		param_id = (jstate->clocations[i].param_id < 0) ?
					jstate->highest_extern_param_id + abs(jstate->clocations[i].param_id) :
					jstate->clocations[i].param_id;
		n_quer_loc += sprintf(norm_query + n_quer_loc, "$%d", param_id);

		quer_loc = off + tok_len;
		last_off = off;
		last_tok_len = tok_len;
	}

	/*
	 * We've copied up until the last ignorable constant.  Copy over the
	 * remaining bytes of the original query string.
	 */
	len_to_wrt = query_len - quer_loc;

	Assert(len_to_wrt >= 0);
	memcpy(norm_query + n_quer_loc, query + quer_loc, len_to_wrt);
	n_quer_loc += len_to_wrt;

	Assert(n_quer_loc <= norm_query_buflen);
	norm_query[n_quer_loc] = '\0';

	*query_len_p = n_quer_loc;
	return norm_query;
}

static void RecordConstLocation(pgssConstLocations *jstate, int location)
{
	/* -1 indicates unknown or undefined location */
	if (location >= 0)
	{
		/* enlarge array if needed */
		if (jstate->clocations_count >= jstate->clocations_buf_size)
		{
			jstate->clocations_buf_size *= 2;
			jstate->clocations = (pgssLocationLen *)
				repalloc(jstate->clocations,
						 jstate->clocations_buf_size *
						 sizeof(pgssLocationLen));
		}
		jstate->clocations[jstate->clocations_count].location = location;
		/* initialize lengths to -1 to simplify fill_in_constant_lengths */
		jstate->clocations[jstate->clocations_count].length = -1;
		/* by default we assume that we need a new param ref */
		jstate->clocations[jstate->clocations_count].param_id = - jstate->highest_normalize_param_id;
		jstate->highest_normalize_param_id++;
		/* record param ref number if requested */
		if (jstate->param_refs != NULL) {
			jstate->param_refs[jstate->param_refs_count] = jstate->clocations[jstate->clocations_count].param_id;
			jstate->param_refs_count++;
			if (jstate->param_refs_count >= jstate->param_refs_buf_size) {
				jstate->param_refs_buf_size *= 2;
				jstate->param_refs = (int *) repalloc(jstate->param_refs, jstate->param_refs_buf_size * sizeof(int));
			}
		}
		jstate->clocations_count++;
	}
}

static void record_defelem_arg_location(pgssConstLocations *jstate, int location)
{
	for (int i = location; i < jstate->query_len; i++) {
		if (jstate->query[i] == '\'' || jstate->query[i] == '$') {
			RecordConstLocation(jstate, i);
			break;
		}
	}
}

static void record_matching_string(pgssConstLocations *jstate, const char *str)
{
	char *loc = NULL;
	if (str == NULL)
		return;

	loc = strstr(jstate->query, str);
	if (loc != NULL)
		RecordConstLocation(jstate, loc - jstate->query - 1);
}

static bool const_record_walker(Node *node, pgssConstLocations *jstate)
{
	bool result;
	MemoryContext normalize_context = CurrentMemoryContext;

	if (node == NULL) return false;

	switch (nodeTag(node))
	{
		case T_A_Const:
			RecordConstLocation(jstate, castNode(A_Const, node)->location);
			break;
		case T_ParamRef:
			{
				/* Track the highest ParamRef number */
				if (((ParamRef *) node)->number > jstate->highest_extern_param_id)
					jstate->highest_extern_param_id = castNode(ParamRef, node)->number;

				if (jstate->param_refs != NULL) {
					jstate->param_refs[jstate->param_refs_count] = ((ParamRef *) node)->number;
					jstate->param_refs_count++;
					if (jstate->param_refs_count >= jstate->param_refs_buf_size) {
						jstate->param_refs_buf_size *= 2;
						jstate->param_refs = (int *) repalloc(jstate->param_refs, jstate->param_refs_buf_size * sizeof(int));
					}
				}
			}
			break;
		case T_DefElem:
			{
				DefElem * defElem = (DefElem *) node;
				if (defElem->arg == NULL) {
					// No argument
				} else if (IsA(defElem->arg, String)) {
					record_defelem_arg_location(jstate, defElem->location);
				} else if (IsA(defElem->arg, List) && list_length((List *) defElem->arg) == 1 && IsA(linitial((List *) defElem->arg), String)) {
					record_defelem_arg_location(jstate, defElem->location);
				}
				return const_record_walker((Node *) ((DefElem *) node)->arg, jstate);
			}
			break;
		case T_RawStmt:
			return const_record_walker((Node *) ((RawStmt *) node)->stmt, jstate);
		case T_VariableSetStmt:
			return const_record_walker((Node *) ((VariableSetStmt *) node)->args, jstate);
		case T_CopyStmt:
			return const_record_walker((Node *) ((CopyStmt *) node)->query, jstate);
		case T_ExplainStmt:
			return const_record_walker((Node *) ((ExplainStmt *) node)->query, jstate);
		case T_CreateRoleStmt:
			return const_record_walker((Node *) ((CreateRoleStmt *) node)->options, jstate);
		case T_AlterRoleStmt:
			return const_record_walker((Node *) ((AlterRoleStmt *) node)->options, jstate);
		case T_DeclareCursorStmt:
			return const_record_walker((Node *) ((DeclareCursorStmt *) node)->query, jstate);
		case T_CreateFunctionStmt:
			return const_record_walker((Node *) ((CreateFunctionStmt *) node)->options, jstate);
		case T_DoStmt:
			return const_record_walker((Node *) ((DoStmt *) node)->args, jstate);
		case T_CreateSubscriptionStmt:
			record_matching_string(jstate, ((CreateSubscriptionStmt *) node)->conninfo);
			break;
		case T_AlterSubscriptionStmt:
			record_matching_string(jstate, ((CreateSubscriptionStmt *) node)->conninfo);
			break;
		case T_CreateUserMappingStmt:
			return const_record_walker((Node *) ((CreateUserMappingStmt *) node)->options, jstate);
		case T_AlterUserMappingStmt:
			return const_record_walker((Node *) ((AlterUserMappingStmt *) node)->options, jstate);
		case T_TypeName:
			/* Don't normalize constants in typmods or arrayBounds */
			return false;
		case T_SelectStmt:
			{
				SelectStmt *stmt = (SelectStmt *) node;
				ListCell *lc;
				List *fp_and_param_refs_list = NIL;

				if (const_record_walker((Node *) stmt->distinctClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->intoClause, jstate))
					return true;
				foreach(lc, stmt->targetList)
				{
					ResTarget *res_target = lfirst_node(ResTarget, lc);
					FpAndParamRefs *fp_and_param_refs = palloc0(sizeof(FpAndParamRefs));

					/* Save all param refs we encounter or assign */
					jstate->param_refs = palloc0(1 * sizeof(int));
					jstate->param_refs_buf_size = 1;
					jstate->param_refs_count = 0;

					/* Walk the element */
					if (const_record_walker((Node *) res_target, jstate))
						return true;

					/* Remember fingerprint and param refs for later */
					fp_and_param_refs->fp = pg_query_fingerprint_node(res_target->val);
					fp_and_param_refs->param_refs = jstate->param_refs;
					fp_and_param_refs->param_refs_count = jstate->param_refs_count;
					fp_and_param_refs_list = lappend(fp_and_param_refs_list, fp_and_param_refs);

					/* Reset for next element, or stop recording if this is the last element */
					jstate->param_refs = NULL;
					jstate->param_refs_buf_size = 0;
					jstate->param_refs_count = 0;
				}
				if (const_record_walker((Node *) stmt->fromClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->whereClause, jstate))
					return true;

				/*
				 * Instead of walking all of groupClause (like raw_expression_tree_walker does),
				 * only walk certain items.
				 */
				foreach(lc, stmt->groupClause)
				{
					/*
					 * Do not walk A_Const values that are simple integers, this avoids
					 * turning "GROUP BY 1" into "GROUP BY $n", which obscures an important
					 * semantic meaning. This matches how pg_stat_statements handles the
					 * GROUP BY clause (i.e. it doesn't touch these constants)
					 */
					if (IsA(lfirst(lc), A_Const) && IsA(&castNode(A_Const, lfirst(lc))->val, Integer))
						continue;

					/*
					 * Match up GROUP BY clauses against the target list, to assign the same
					 * param refs as used in the target list - this ensures the query is valid,
					 * instead of throwing a bogus "columns ... must appear in the GROUP BY
					 * clause or be used in an aggregate function" error
					 */
					uint64_t fp = pg_query_fingerprint_node(lfirst(lc));
					FpAndParamRefs *fppr = NULL;
					ListCell *lc2;
					foreach(lc2, fp_and_param_refs_list) {
						if (fp == ((FpAndParamRefs *) lfirst(lc2))->fp) {
							fppr = (FpAndParamRefs *) lfirst(lc2);
							foreach_delete_current(fp_and_param_refs_list, lc2);
							break;
						}
					}

					int prev_cloc_count = jstate->clocations_count;
					if (const_record_walker((Node *) lfirst(lc), jstate))
						return true;

					if (fppr != NULL && fppr->param_refs_count == jstate->clocations_count - prev_cloc_count) {
						for (int i = prev_cloc_count; i < jstate->clocations_count; i++) {
							jstate->clocations[i].param_id = fppr->param_refs[i - prev_cloc_count];
						}
						jstate->highest_normalize_param_id -= fppr->param_refs_count;
					}
				}
				foreach(lc, stmt->sortClause)
				{
					/* Similarly, don't turn "ORDER BY 1" into "ORDER BY $n" */
					if (IsA(lfirst(lc), SortBy) && IsA(castNode(SortBy, lfirst(lc))->node, A_Const) &&
					    IsA(&castNode(A_Const, castNode(SortBy, lfirst(lc))->node)->val, Integer))
						continue;

					if (const_record_walker((Node *) lfirst(lc), jstate))
						return true;
				}
				if (const_record_walker((Node *) stmt->havingClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->windowClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->valuesLists, jstate))
					return true;
				if (const_record_walker((Node *) stmt->limitOffset, jstate))
					return true;
				if (const_record_walker((Node *) stmt->limitCount, jstate))
					return true;
				if (const_record_walker((Node *) stmt->lockingClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->withClause, jstate))
					return true;
				if (const_record_walker((Node *) stmt->larg, jstate))
					return true;
				if (const_record_walker((Node *) stmt->rarg, jstate))
					return true;

				return false;
			}
		default:
			{
				PG_TRY();
				{
					return raw_expression_tree_walker(node, const_record_walker, (void*) jstate);
				}
				PG_CATCH();
				{
					MemoryContextSwitchTo(normalize_context);
					FlushErrorState();
				}
				PG_END_TRY();
			}
	}

	return false;
}

PgQueryNormalizeResult pg_query_normalize(const char* input)
{
	MemoryContext ctx = NULL;
	PgQueryNormalizeResult result = {0};

	ctx = pg_query_enter_memory_context();

	PG_TRY();
	{
		List *tree;
		pgssConstLocations jstate;
		int query_len;

		/* Parse query */
		tree = raw_parser(input, RAW_PARSE_DEFAULT);

		query_len = (int) strlen(input);

		/* Set up workspace for constant recording */
		jstate.clocations_buf_size = 32;
		jstate.clocations = (pgssLocationLen *)
			palloc(jstate.clocations_buf_size * sizeof(pgssLocationLen));
		jstate.clocations_count = 0;
		jstate.highest_normalize_param_id = 1;
		jstate.highest_extern_param_id = 0;
		jstate.query = input;
		jstate.query_len = query_len;
		jstate.param_refs = NULL;
		jstate.param_refs_buf_size = 0;
		jstate.param_refs_count = 0;

		/* Walk tree and record const locations */
		const_record_walker((Node *) tree, &jstate);

		/* Normalize query */
		result.normalized_query = strdup(generate_normalized_query(&jstate, 0, &query_len, PG_UTF8));
	}
	PG_CATCH();
	{
		ErrorData* error_data;
		PgQueryError* error;

		MemoryContextSwitchTo(ctx);
		error_data = CopyErrorData();

		error = malloc(sizeof(PgQueryError));
		error->message   = strdup(error_data->message);
		error->filename  = strdup(error_data->filename);
		error->funcname  = strdup(error_data->funcname);
		error->context   = NULL;
		error->lineno    = error_data->lineno;
		error->cursorpos = error_data->cursorpos;

		result.error = error;
		FlushErrorState();
	}
	PG_END_TRY();

	pg_query_exit_memory_context(ctx);

	return result;
}

void pg_query_free_normalize_result(PgQueryNormalizeResult result)
{
  if (result.error) {
    free(result.error->message);
    free(result.error->filename);
    free(result.error->funcname);
    free(result.error);
  }

  free(result.normalized_query);
}
