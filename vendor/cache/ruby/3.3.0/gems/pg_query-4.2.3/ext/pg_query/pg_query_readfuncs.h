#ifndef PG_QUERY_READFUNCS_H
#define PG_QUERY_READFUNCS_H

#include "pg_query.h"

#include "postgres.h"
#include "nodes/pg_list.h"

List * pg_query_protobuf_to_nodes(PgQueryProtobuf protobuf);

#endif
