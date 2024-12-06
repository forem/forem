#ifndef PG_QUERY_FINGERPRINT_H
#define PG_QUERY_FINGERPRINT_H

#include <stdbool.h>

extern PgQueryFingerprintResult pg_query_fingerprint_with_opts(const char* input, bool printTokens);

extern uint64_t pg_query_fingerprint_node(const void * node);

#endif
