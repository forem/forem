#ifndef POSTGRES_DEPARSE_H
#define POSTGRES_DEPARSE_H

#include "lib/stringinfo.h"
#include "nodes/parsenodes.h"

extern void deparseRawStmt(StringInfo str, RawStmt *raw_stmt);

#endif
