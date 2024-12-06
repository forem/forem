#ifndef PG_QUERY_H
#define PG_QUERY_H

#include <stdint.h>
#include <sys/types.h>

typedef struct {
	char* message; // exception message
	char* funcname; // source function of exception (e.g. SearchSysCache)
	char* filename; // source of exception (e.g. parse.l)
	int lineno; // source of exception (e.g. 104)
	int cursorpos; // char in query at which exception occurred
	char* context; // additional context (optional, can be NULL)
} PgQueryError;

typedef struct {
  size_t len;
  char* data;
} PgQueryProtobuf;

typedef struct {
  PgQueryProtobuf pbuf;
  char* stderr_buffer;
  PgQueryError* error;
} PgQueryScanResult;

typedef struct {
  char* parse_tree;
  char* stderr_buffer;
  PgQueryError* error;
} PgQueryParseResult;

typedef struct {
  PgQueryProtobuf parse_tree;
  char* stderr_buffer;
  PgQueryError* error;
} PgQueryProtobufParseResult;

typedef struct {
  int stmt_location;
  int stmt_len;
} PgQuerySplitStmt;

typedef struct {
  PgQuerySplitStmt **stmts;
  int n_stmts;
  char* stderr_buffer;
  PgQueryError* error;
} PgQuerySplitResult;

typedef struct {
  char* query;
  PgQueryError* error;
} PgQueryDeparseResult;

typedef struct {
  char* plpgsql_funcs;
  PgQueryError* error;
} PgQueryPlpgsqlParseResult;

typedef struct {
  uint64_t fingerprint;
  char* fingerprint_str;
  char* stderr_buffer;
  PgQueryError* error;
} PgQueryFingerprintResult;

typedef struct {
  char* normalized_query;
  PgQueryError* error;
} PgQueryNormalizeResult;

#ifdef __cplusplus
extern "C" {
#endif

PgQueryNormalizeResult pg_query_normalize(const char* input);
PgQueryScanResult pg_query_scan(const char* input);
PgQueryParseResult pg_query_parse(const char* input);
PgQueryProtobufParseResult pg_query_parse_protobuf(const char* input);
PgQueryPlpgsqlParseResult pg_query_parse_plpgsql(const char* input);

PgQueryFingerprintResult pg_query_fingerprint(const char* input);

// Use pg_query_split_with_scanner when you need to split statements that may
// contain parse errors, otherwise pg_query_split_with_parser is recommended
// for improved accuracy due the parser adding additional token handling.
//
// Note that we try to support special cases like comments, strings containing
// ";" on both, as well as oddities like "CREATE RULE .. (SELECT 1; SELECT 2);"
// which is treated as as single statement.
PgQuerySplitResult pg_query_split_with_scanner(const char *input);
PgQuerySplitResult pg_query_split_with_parser(const char *input);

PgQueryDeparseResult pg_query_deparse_protobuf(PgQueryProtobuf parse_tree);

void pg_query_free_normalize_result(PgQueryNormalizeResult result);
void pg_query_free_scan_result(PgQueryScanResult result);
void pg_query_free_parse_result(PgQueryParseResult result);
void pg_query_free_split_result(PgQuerySplitResult result);
void pg_query_free_deparse_result(PgQueryDeparseResult result);
void pg_query_free_protobuf_parse_result(PgQueryProtobufParseResult result);
void pg_query_free_plpgsql_parse_result(PgQueryPlpgsqlParseResult result);
void pg_query_free_fingerprint_result(PgQueryFingerprintResult result);

// Optional, cleans up the top-level memory context (automatically done for threads that exit)
void pg_query_exit(void);

// Postgres version information
#define PG_MAJORVERSION "15"
#define PG_VERSION "15.1"
#define PG_VERSION_NUM 150001

// Deprecated APIs below

void pg_query_init(void); // Deprecated as of 9.5-1.4.1, this is now run automatically as needed

#ifdef __cplusplus
}
#endif

#endif
