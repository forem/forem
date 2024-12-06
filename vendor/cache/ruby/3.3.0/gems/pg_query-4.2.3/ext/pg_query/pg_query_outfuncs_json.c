#include "pg_query_outfuncs.h"

#include "postgres.h"

#include <ctype.h>

#include "access/relation.h"
#include "nodes/parsenodes.h"
#include "nodes/plannodes.h"
#include "nodes/value.h"
#include "utils/datum.h"

#include "pg_query_json_helper.c"

#define OUT_TYPE(typename, typename_c) StringInfo

#define OUT_NODE(typename, typename_c, typename_underscore, typename_underscore_upcase, typename_cast, fldname) \
  { \
    WRITE_NODE_TYPE(CppAsString(typename)); \
    _out##typename_c(out, (const typename_cast *) obj); \
  }

/* Write the label for the node type */
#define WRITE_NODE_TYPE(nodelabel) \
	appendStringInfoString(out, "\"" nodelabel "\":{")

/* Write an integer field */
#define WRITE_INT_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%d,", node->fldname); \
	}

/* Write an unsigned integer field */
#define WRITE_UINT_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%u,", node->fldname); \
	}

/* Write a long-integer field */
#define WRITE_LONG_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%ld,", node->fldname); \
	}

/* Write a char field (ie, one ascii character) */
#define WRITE_CHAR_FIELD(outname, outname_json, fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":\"%c\",", node->fldname); \
	}

/* Write an enumerated-type field */
#define WRITE_ENUM_FIELD(typename, outname, outname_json, fldname) \
	appendStringInfo(out, "\"" CppAsString(outname_json) "\":\"%s\",", \
					 _enumToString##typename(node->fldname));

/* Write a float field */
#define WRITE_FLOAT_FIELD(outname, outname_json, fldname) \
	appendStringInfo(out, "\"" CppAsString(outname_json) "\":%f,", node->fldname)

/* Write a boolean field */
#define WRITE_BOOL_FIELD(outname, outname_json, fldname) \
	if (node->fldname) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":%s,", \
					 	booltostr(node->fldname)); \
	}

/* Write a character-string (possibly NULL) field */
#define WRITE_STRING_FIELD(outname, outname_json, fldname) \
	if (node->fldname != NULL) { \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":"); \
	 	_outToken(out, node->fldname); \
	 	appendStringInfo(out, ","); \
	}

#define WRITE_LIST_FIELD(outname, outname_json, fldname) \
	if (node->fldname != NULL) { \
		const ListCell *lc; \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":"); \
		appendStringInfoChar(out, '['); \
		foreach(lc, node->fldname) { \
			if (lfirst(lc) == NULL) \
				appendStringInfoString(out, "{}"); \
			else \
				_outNode(out, lfirst(lc)); \
			if (lnext(node->fldname, lc)) \
				appendStringInfoString(out, ","); \
		} \
		 appendStringInfo(out, "],"); \
    }

#define WRITE_NODE_FIELD(outname, outname_json, fldname) \
	if (true) { \
		 appendStringInfo(out, "\"" CppAsString(outname_json) "\":"); \
	     _outNode(out, &node->fldname); \
		 appendStringInfo(out, ","); \
  	}

#define WRITE_NODE_PTR_FIELD(outname, outname_json, fldname) \
	if (node->fldname != NULL) { \
		 appendStringInfo(out, "\"" CppAsString(outname_json) "\":"); \
		 _outNode(out, node->fldname); \
		 appendStringInfo(out, ","); \
	}

#define WRITE_SPECIFIC_NODE_FIELD(typename, typename_underscore, outname, outname_json, fldname) \
	{ \
    	appendStringInfo(out, "\"" CppAsString(outname_json) "\":{"); \
    	_out##typename(out, &node->fldname); \
		removeTrailingDelimiter(out); \
 		appendStringInfo(out, "},"); \
  	}

#define WRITE_SPECIFIC_NODE_PTR_FIELD(typename, typename_underscore, outname, outname_json, fldname) \
	if (node->fldname != NULL) { \
		 appendStringInfo(out, "\"" CppAsString(outname_json) "\":{"); \
	   	 _out##typename(out, node->fldname); \
		 removeTrailingDelimiter(out); \
 		 appendStringInfo(out, "},"); \
	}

#define WRITE_BITMAPSET_FIELD(outname, outname_json, fldname) \
	if (!bms_is_empty(node->fldname)) \
	{ \
		int x = 0; \
		appendStringInfo(out, "\"" CppAsString(outname_json) "\":["); \
		while ((x = bms_next_member(node->fldname, x)) >= 0) \
			appendStringInfo(out, "%d,", x); \
		removeTrailingDelimiter(out); \
		appendStringInfo(out, "],"); \
	}

static void _outNode(StringInfo out, const void *obj);

static void
_outList(StringInfo out, const List *node)
{
	const ListCell *lc;

	appendStringInfo(out, "\"items\":");
	appendStringInfoChar(out, '[');

	foreach(lc, node)
	{
		if (lfirst(lc) == NULL)
			appendStringInfoString(out, "{}");
		else
			_outNode(out, lfirst(lc));

		if (lnext(node, lc))
			appendStringInfoString(out, ",");
	}

	appendStringInfoChar(out, ']');
	appendStringInfo(out, ",");
}

static void
_outIntList(StringInfo out, const List *node)
{
	const ListCell *lc;

	appendStringInfo(out, "\"items\":");
	appendStringInfoChar(out, '[');

	foreach(lc, node)
	{
		appendStringInfo(out, "%d", lfirst_int(lc));

		if (lnext(node, lc))
			appendStringInfoString(out, ",");
	}

	appendStringInfoChar(out, ']');
	appendStringInfo(out, ",");
}

static void
_outOidList(StringInfo out, const List *node)
{
	const ListCell *lc;

	appendStringInfo(out, "\"items\":");
	appendStringInfoChar(out, '[');

	foreach(lc, node)
	{
		appendStringInfo(out, "%u", lfirst_oid(lc));

		if (lnext(node, lc))
			appendStringInfoString(out, ",");
	}

	appendStringInfoChar(out, ']');
	appendStringInfo(out, ",");
}

static void
_outInteger(StringInfo out, const Integer *node)
{
	if (node->ival > 0)
		appendStringInfo(out, "\"ival\":%d", node->ival);
}

static void
_outBoolean(StringInfo out, const Boolean *node)
{
	appendStringInfo(out, "\"boolval\":%s", booltostr(node->boolval));
}

static void
_outFloat(StringInfo out, const Float *node)
{
	appendStringInfo(out, "\"fval\":");
	_outToken(out, node->fval);
}

static void
_outString(StringInfo out, const String *node)
{
	appendStringInfo(out, "\"sval\":");
	_outToken(out, node->sval);
}

static void
_outBitString(StringInfo out, const BitString *node)
{
	appendStringInfo(out, "\"bsval\":");
	_outToken(out, node->bsval);
}

static void
_outAConst(StringInfo out, const A_Const *node)
{
	if (node->isnull) {
		appendStringInfo(out, "\"isnull\":true");
	} else {
		switch (node->val.node.type) {
			case T_Integer:
				appendStringInfoString(out, "\"ival\":{");
				_outInteger(out, &node->val.ival);
				appendStringInfoChar(out, '}');
				break;
			case T_Float:
				appendStringInfoString(out, "\"fval\":{");
				_outFloat(out, &node->val.fval);
				appendStringInfoChar(out, '}');
				break;
			case T_Boolean:
				appendStringInfo(out, "\"boolval\":{%s}", node->val.boolval.boolval ? "\"boolval\":true" : "");
				break;
			case T_String:
				appendStringInfoString(out, "\"sval\":{");
				_outString(out, &node->val.sval);
				appendStringInfoChar(out, '}');
				break;
			case T_BitString:
				appendStringInfoString(out, "\"bsval\":{");
				_outBitString(out, &node->val.bsval);
				appendStringInfoChar(out, '}');
				break;

			// Unreachable, A_Const cannot contain any other nodes.
			default:
				Assert(false);
		}
	}

	appendStringInfo(out, ",\"location\":%d", node->location);
}

#include "pg_query_enum_defs.c"
#include "pg_query_outfuncs_defs.c"

static void
_outNode(StringInfo out, const void *obj)
{
	if (obj == NULL)
	{
		appendStringInfoString(out, "null");
	}
	else
	{
		appendStringInfoChar(out, '{');
		switch (nodeTag(obj))
		{
			#include "pg_query_outfuncs_conds.c"

			default:
				elog(WARNING, "could not dump unrecognized node type: %d",
					 (int) nodeTag(obj));

				appendStringInfo(out, "}");
				return;
		}
		removeTrailingDelimiter(out);
		appendStringInfo(out, "}}");
	}
}

char *
pg_query_node_to_json(const void *obj)
{
	StringInfoData out;

	initStringInfo(&out);
	_outNode(&out, obj);

	return out.data;
}

char *
pg_query_nodes_to_json(const void *obj)
{
	StringInfoData out;
	const ListCell *lc;

	initStringInfo(&out);

	if (obj == NULL) /* Make sure we generate valid JSON for empty queries */
	{
		appendStringInfo(&out, "{\"version\":%d,\"stmts\":[]}", PG_VERSION_NUM);
	}
	else
	{
		appendStringInfoString(&out, "{");
		appendStringInfo(&out, "\"version\":%d,", PG_VERSION_NUM);
		appendStringInfoString(&out, "\"stmts\":");
		appendStringInfoChar(&out, '[');

		foreach(lc, obj)
		{
			appendStringInfoChar(&out, '{');
			_outRawStmt(&out, lfirst(lc));
			removeTrailingDelimiter(&out);
			appendStringInfoChar(&out, '}');

			if (lnext(obj, lc))
				appendStringInfoString(&out, ",");
		}

		appendStringInfoChar(&out, ']');
		appendStringInfoString(&out, "}");
	}

	return out.data;
}
