#ifndef PG_QUERY_INTERNAL_H
#define PG_QUERY_INTERNAL_H

#include "postgres.h"
#include "utils/memutils.h"
#include "nodes/pg_list.h"

#define STDERR_BUFFER_LEN 4096
#define DEBUG

typedef struct {
  List *tree;
  char* stderr_buffer;
  PgQueryError* error;
} PgQueryInternalParsetreeAndError;

PgQueryInternalParsetreeAndError pg_query_raw_parse(const char* input);

void pg_query_free_error(PgQueryError *error);

MemoryContext pg_query_enter_memory_context();
void pg_query_exit_memory_context(MemoryContext ctx);

#endif
