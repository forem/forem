#include "pg_query.h"
#include "pg_query_internal.h"

#include "parser/gramparse.h"
#include "lib/stringinfo.h"

#include <unistd.h>
#include <fcntl.h>

PgQuerySplitResult pg_query_split_with_scanner(const char* input)
{
  MemoryContext ctx = NULL;
  PgQuerySplitResult result = {0};
  core_yyscan_t yyscanner;
  core_yy_extra_type yyextra;
  core_YYSTYPE yylval;
  YYLTYPE    yylloc;
  size_t curstmt = 0;
  bool keyword_before_terminator = false;
  int stmtstart = 0;
  bool is_keyword = false;
  size_t open_parens = 0;

  ctx = pg_query_enter_memory_context();

  MemoryContext parse_context = CurrentMemoryContext;

  char stderr_buffer[STDERR_BUFFER_LEN + 1] = {0};
#ifndef DEBUG
  int stderr_global;
  int stderr_pipe[2];
#endif

#ifndef DEBUG
  // Setup pipe for stderr redirection
  if (pipe(stderr_pipe) != 0) {
    PgQueryError* error = malloc(sizeof(PgQueryError));

    error->message = strdup("Failed to open pipe, too many open file descriptors")

    result.error = error;

    return result;
  }

  fcntl(stderr_pipe[0], F_SETFL, fcntl(stderr_pipe[0], F_GETFL) | O_NONBLOCK);

  // Redirect stderr to the pipe
  stderr_global = dup(STDERR_FILENO);
  dup2(stderr_pipe[1], STDERR_FILENO);
  close(stderr_pipe[1]);
#endif

  PG_TRY();
  {
    // Really this is stupid, we only run twice so we can pre-allocate the output array correctly
    yyscanner = scanner_init(input, &yyextra, &ScanKeywords, ScanKeywordTokens);
    while (true)
    {
      int tok = core_yylex(&yylval, &yylloc, yyscanner);
      switch (tok) {
      #define PG_KEYWORD(a,b,c,d) case b: is_keyword = true; break;
      #include "parser/kwlist.h"
      #undef PG_KEYWORD
      default: is_keyword = false;
      }
      if (is_keyword)
        keyword_before_terminator = true;
      else if (tok == '(')
        open_parens++;
      else if (tok == ')')
        open_parens--;
      else if (keyword_before_terminator && open_parens == 0 && (tok == ';' || tok == 0))
      {
        result.n_stmts++;
        keyword_before_terminator = false;
      }
      if (tok == 0) break;
    }
    scanner_finish(yyscanner);

    result.stmts = malloc(sizeof(PgQuerySplitStmt *) * result.n_stmts);

    // Now actually set the output values
    keyword_before_terminator = false;
    open_parens = 0;
    yyscanner = scanner_init(input, &yyextra, &ScanKeywords, ScanKeywordTokens);
    while (true)
    {
      int tok = core_yylex(&yylval, &yylloc, yyscanner);
      switch (tok) {
      #define PG_KEYWORD(a,b,c,d) case b: is_keyword = true; break;
      #include "parser/kwlist.h"
      default: is_keyword = false;
      }
      if (is_keyword)
        keyword_before_terminator = true;
      else if (tok == '(')
        open_parens++;
      else if (tok == ')')
        open_parens--;
      else if (keyword_before_terminator && open_parens == 0 && (tok == ';' || tok == 0))
      {
        // Add statement up to the current position
        result.stmts[curstmt] = malloc(sizeof(PgQuerySplitStmt));
        result.stmts[curstmt]->stmt_location = stmtstart;
        result.stmts[curstmt]->stmt_len = yylloc - stmtstart;

        stmtstart = yylloc + 1;
        keyword_before_terminator = false;

        curstmt++;
      }
      else if (open_parens == 0 && tok == ';') // Advance statement start in case we skip an empty statement
      {
        stmtstart = yylloc + 1;
      }

      if (tok == 0) break;
    }

    scanner_finish(yyscanner);

#ifndef DEBUG
    // Save stderr for result
    read(stderr_pipe[0], stderr_buffer, STDERR_BUFFER_LEN);
#endif

    result.stderr_buffer = strdup(stderr_buffer);
  }
  PG_CATCH();
  {
    ErrorData* error_data;
    PgQueryError* error;

    MemoryContextSwitchTo(parse_context);
    error_data = CopyErrorData();

    // Note: This is intentionally malloc so exiting the memory context doesn't free this
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

#ifndef DEBUG
  // Restore stderr, close pipe
  dup2(stderr_global, STDERR_FILENO);
  close(stderr_pipe[0]);
  close(stderr_global);
#endif

  pg_query_exit_memory_context(ctx);

  return result;
}

PgQuerySplitResult pg_query_split_with_parser(const char* input)
{
	MemoryContext ctx = NULL;
	PgQueryInternalParsetreeAndError parsetree_and_error;
	PgQuerySplitResult result = {};

	ctx = pg_query_enter_memory_context();

	parsetree_and_error = pg_query_raw_parse(input);

	// These are all malloc-ed and will survive exiting the memory context, the caller is responsible to free them now
	result.stderr_buffer = parsetree_and_error.stderr_buffer;
	result.error = parsetree_and_error.error;

	if (parsetree_and_error.tree != NULL)
	{
		ListCell *lc;

		result.n_stmts = list_length(parsetree_and_error.tree);
		result.stmts = malloc(sizeof(PgQuerySplitStmt*) * result.n_stmts);
		foreach (lc, parsetree_and_error.tree)
		{
			RawStmt *raw_stmt = castNode(RawStmt, lfirst(lc));
			result.stmts[foreach_current_index(lc)] = malloc(sizeof(PgQuerySplitStmt));
			result.stmts[foreach_current_index(lc)]->stmt_location = raw_stmt->stmt_location;
			if (raw_stmt->stmt_len == 0)
				result.stmts[foreach_current_index(lc)]->stmt_len = strlen(input) - raw_stmt->stmt_location;
			else
				result.stmts[foreach_current_index(lc)]->stmt_len = raw_stmt->stmt_len;
		}
	}
	else
	{
		result.n_stmts = 0;
		result.stmts = NULL;
	}

	pg_query_exit_memory_context(ctx);

	return result;
}

void pg_query_free_split_result(PgQuerySplitResult result)
{
	if (result.error) {
		pg_query_free_error(result.error);
	}
	free(result.stderr_buffer);

	if (result.stmts != NULL)
	{
    for (int i = 0; i < result.n_stmts; ++i)
    {
      free(result.stmts[i]);
    }
		free(result.stmts);
	}
}
