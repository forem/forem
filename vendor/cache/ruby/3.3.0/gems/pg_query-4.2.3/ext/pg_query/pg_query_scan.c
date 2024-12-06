#include "pg_query.h"
#include "pg_query_internal.h"

#include "parser/gramparse.h"
#include "lib/stringinfo.h"

#include "protobuf/pg_query.pb-c.h"

#include <unistd.h>
#include <fcntl.h>

/* This is ugly. We need to access yyleng outside of scan.l, and casting yyscanner
   to this internal struct seemed like one way to do it... */
struct yyguts_t
{
  void *yyextra_r;
  FILE *yyin_r, *yyout_r;
  size_t yy_buffer_stack_top; /**< index of top of stack. */
  size_t yy_buffer_stack_max; /**< capacity of stack. */
  struct yy_buffer_state *yy_buffer_stack; /**< Stack as an array. */
  char yy_hold_char;
  size_t yy_n_chars;
  size_t yyleng_r;
};

PgQueryScanResult pg_query_scan(const char* input)
{
  MemoryContext ctx = NULL;
  PgQueryScanResult result = {0};
  core_yyscan_t yyscanner;
  core_yy_extra_type yyextra;
  core_YYSTYPE yylval;
  YYLTYPE    yylloc;
  PgQuery__ScanResult scan_result = PG_QUERY__SCAN_RESULT__INIT;
  PgQuery__ScanToken **output_tokens;
  size_t token_count = 0;
  size_t i;

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
    for (;; token_count++)
    {
      if (core_yylex(&yylval, &yylloc, yyscanner) == 0) break;
    }
    scanner_finish(yyscanner);

    output_tokens = malloc(sizeof(PgQuery__ScanToken *) * token_count);

    /* initialize the flex scanner --- should match raw_parser() */
    yyscanner = scanner_init(input, &yyextra, &ScanKeywords, ScanKeywordTokens);

    /* Lex tokens  */
    for (i = 0; ; i++)
    {
      int tok;
      int keyword;

      tok = core_yylex(&yylval, &yylloc, yyscanner);
      if (tok == 0) break;

      output_tokens[i] = malloc(sizeof(PgQuery__ScanToken));
      pg_query__scan_token__init(output_tokens[i]);
      output_tokens[i]->start = yylloc;
      if (tok == SCONST || tok == BCONST || tok == XCONST || tok == IDENT || tok == C_COMMENT) {
        output_tokens[i]->end = yyextra.yyllocend;
      } else {
        output_tokens[i]->end = yylloc + ((struct yyguts_t*) yyscanner)->yyleng_r;
      }
      output_tokens[i]->token = tok;

      switch (tok) {
      #define PG_KEYWORD(a,b,c,d) case b: output_tokens[i]->keyword_kind = c + 1; break;
      #include "parser/kwlist.h"
      #undef PG_KEYWORD
      default: output_tokens[i]->keyword_kind = 0;
      }
    }

    scanner_finish(yyscanner);

    scan_result.version = PG_VERSION_NUM;
    scan_result.n_tokens = token_count;
    scan_result.tokens = output_tokens;
    result.pbuf.len = pg_query__scan_result__get_packed_size(&scan_result);
    result.pbuf.data = malloc(result.pbuf.len);
    pg_query__scan_result__pack(&scan_result, (void*) result.pbuf.data);

    for (i = 0; i < token_count; i++) {
      free(output_tokens[i]);
    }
    free(output_tokens);

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

void pg_query_free_scan_result(PgQueryScanResult result)
{
  if (result.error) {
    pg_query_free_error(result.error);
  }

  free(result.pbuf.data);
  free(result.stderr_buffer);
}
