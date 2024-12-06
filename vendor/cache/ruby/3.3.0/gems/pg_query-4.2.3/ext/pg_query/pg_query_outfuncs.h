#ifndef PG_QUERY_OUTFUNCS_H
#define PG_QUERY_OUTFUNCS_H

#include "pg_query.h"

PgQueryProtobuf pg_query_nodes_to_protobuf(const void *obj);

char *pg_query_node_to_json(const void *obj);
char *pg_query_nodes_to_json(const void *obj);

#endif
