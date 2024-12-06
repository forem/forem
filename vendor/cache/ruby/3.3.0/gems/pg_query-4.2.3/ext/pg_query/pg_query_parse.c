#include "pg_query.h"
#include "pg_query_internal.h"
#include "pg_query_outfuncs.h"

#include "parser/parser.h"
#include "parser/scanner.h"
#include "parser/scansup.h"

#include <unistd.h>
#include <fcntl.h>

PgQueryInternalParsetreeAndError pg_query_raw_parse(const char* input)
{
	PgQueryInternalParsetreeAndError result = {0};
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
		result.tree = raw_parser(input, RAW_PARSE_DEFAULT);

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

	return result;
}

PgQueryParseResult pg_query_parse(const char* input)
{
	MemoryContext ctx = NULL;
	PgQueryInternalParsetreeAndError parsetree_and_error;
	PgQueryParseResult result = {0};
	char *tree_json = NULL;

	ctx = pg_query_enter_memory_context();

	parsetree_and_error = pg_query_raw_parse(input);

	// These are all malloc-ed and will survive exiting the memory context, the caller is responsible to free them now
	result.stderr_buffer = parsetree_and_error.stderr_buffer;
	result.error = parsetree_and_error.error;

	tree_json = pg_query_nodes_to_json(parsetree_and_error.tree);
	result.parse_tree = strdup(tree_json);
	pfree(tree_json);

	pg_query_exit_memory_context(ctx);

	return result;
}

PgQueryProtobufParseResult pg_query_parse_protobuf(const char* input)
{
	MemoryContext ctx = NULL;
	PgQueryInternalParsetreeAndError parsetree_and_error;
	PgQueryProtobufParseResult result = {};

	ctx = pg_query_enter_memory_context();

	parsetree_and_error = pg_query_raw_parse(input);

	// These are all malloc-ed and will survive exiting the memory context, the caller is responsible to free them now
	result.stderr_buffer = parsetree_and_error.stderr_buffer;
	result.error = parsetree_and_error.error;
	result.parse_tree = pg_query_nodes_to_protobuf(parsetree_and_error.tree);

	pg_query_exit_memory_context(ctx);

	return result;
}

void pg_query_free_parse_result(PgQueryParseResult result)
{
	if (result.error) {
		pg_query_free_error(result.error);
	}

	free(result.parse_tree);
	free(result.stderr_buffer);
}

void pg_query_free_protobuf_parse_result(PgQueryProtobufParseResult result)
{
	if (result.error) {
		pg_query_free_error(result.error);
	}

	free(result.parse_tree.data);
	free(result.stderr_buffer);
}
