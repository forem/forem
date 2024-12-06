#include "pg_query_readfuncs.h"

#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"

#include "protobuf/pg_query.pb-c.h"

#define OUT_TYPE(typename, typename_c) PgQuery__##typename_c*

#define READ_COND(typename, typename_c, typename_underscore, typename_underscore_upcase, typename_cast, outname) \
	case PG_QUERY__NODE__NODE_##typename_underscore_upcase: \
		return (Node *) _read##typename_c(msg->outname);

#define READ_INT_FIELD(outname, outname_json, fldname) node->fldname = msg->outname;
#define READ_UINT_FIELD(outname, outname_json, fldname) node->fldname = msg->outname;
#define READ_LONG_FIELD(outname, outname_json, fldname) node->fldname = msg->outname;
#define READ_FLOAT_FIELD(outname, outname_json, fldname) node->fldname = msg->outname;
#define READ_BOOL_FIELD(outname, outname_json, fldname) node->fldname = msg->outname;

#define READ_CHAR_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL && strlen(msg->outname) > 0) { \
		node->fldname = msg->outname[0]; \
	}

#define READ_STRING_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL && strlen(msg->outname) > 0) { \
		node->fldname = pstrdup(msg->outname); \
	}

#define READ_ENUM_FIELD(typename, outname, outname_json, fldname) \
	node->fldname = _intToEnum##typename(msg->outname);

#define READ_LIST_FIELD(outname, outname_json, fldname) \
	{ \
		if (msg->n_##outname > 0) \
			node->fldname = list_make1(_readNode(msg->outname[0])); \
	    for (int i = 1; i < msg->n_##outname; i++) \
			node->fldname = lappend(node->fldname, _readNode(msg->outname[i])); \
	}

#define READ_BITMAPSET_FIELD(outname, outname_json, fldname) // FIXME

#define READ_NODE_FIELD(outname, outname_json, fldname) \
	node->fldname = *_readNode(msg->outname);

#define READ_NODE_PTR_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL) { \
		node->fldname = _readNode(msg->outname); \
	}

#define READ_EXPR_PTR_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL) { \
		node->fldname = (Expr *) _readNode(msg->outname); \
	}

#define READ_VALUE_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL) { \
		node->fldname = *((Value *) _readNode(msg->outname)); \
	}

#define READ_VALUE_PTR_FIELD(outname, outname_json, fldname) \
	if (msg->outname != NULL) { \
		node->fldname = (Value *) _readNode(msg->outname); \
	}

#define READ_SPECIFIC_NODE_FIELD(typename, typename_underscore, outname, outname_json, fldname) \
	node->fldname = *_read##typename(msg->outname);

#define READ_SPECIFIC_NODE_PTR_FIELD(typename, typename_underscore, outname, outname_json, fldname) \
	if (msg->outname != NULL) { \
		node->fldname = _read##typename(msg->outname); \
	}

static Node * _readNode(PgQuery__Node *msg);

static String *
_readString(PgQuery__String* msg)
{
	return makeString(pstrdup(msg->sval));
}

#include "pg_query_enum_defs.c"
#include "pg_query_readfuncs_defs.c"

static List * _readList(PgQuery__List *msg)
{
	List *node = NULL;
	if (msg->n_items > 0)
		node = list_make1(_readNode(msg->items[0]));
	for (int i = 1; i < msg->n_items; i++)
		node = lappend(node, _readNode(msg->items[i]));
	return node;
}

static Node * _readNode(PgQuery__Node *msg)
{
	switch (msg->node_case)
	{
		#include "pg_query_readfuncs_conds.c"

		case PG_QUERY__NODE__NODE_INTEGER:
			return (Node *) makeInteger(msg->integer->ival);
		case PG_QUERY__NODE__NODE_FLOAT:
			return (Node *) makeFloat(pstrdup(msg->float_->fval));
		case PG_QUERY__NODE__NODE_BOOLEAN:
			return (Node *) makeBoolean(msg->boolean->boolval);
		case PG_QUERY__NODE__NODE_STRING:
			return (Node *) makeString(pstrdup(msg->string->sval));
		case PG_QUERY__NODE__NODE_BIT_STRING:
			return (Node *) makeBitString(pstrdup(msg->bit_string->bsval));
		case PG_QUERY__NODE__NODE_A_CONST: {
			A_Const *ac = makeNode(A_Const);
			ac->location = msg->a_const->location;

			if (msg->a_const->isnull) {
				ac->isnull = true;
			} else {
				switch (msg->a_const->val_case) {
					case PG_QUERY__A__CONST__VAL_IVAL:
						ac->val.ival = *makeInteger(msg->a_const->ival->ival);
						break;
					case PG_QUERY__A__CONST__VAL_FVAL:
						ac->val.fval = *makeFloat(pstrdup(msg->a_const->fval->fval));
						break;
					case PG_QUERY__A__CONST__VAL_BOOLVAL:
						ac->val.boolval = *makeBoolean(msg->a_const->boolval->boolval);
						break;
					case PG_QUERY__A__CONST__VAL_SVAL:
						ac->val.sval = *makeString(pstrdup(msg->a_const->sval->sval));
						break;
					case PG_QUERY__A__CONST__VAL_BSVAL:
						ac->val.bsval = *makeBitString(pstrdup(msg->a_const->bsval->bsval));
						break;
					case PG_QUERY__A__CONST__VAL__NOT_SET:
					case _PG_QUERY__A__CONST__VAL__CASE_IS_INT_SIZE:
						Assert(false);
						break;
				}
			}

			return (Node *) ac;
		}
		case PG_QUERY__NODE__NODE_LIST:
			return (Node *) _readList(msg->list);
		case PG_QUERY__NODE__NODE__NOT_SET:
			return NULL;
		default:
			elog(ERROR, "unsupported protobuf node type: %d",
				 (int) msg->node_case);
	}
}

List * pg_query_protobuf_to_nodes(PgQueryProtobuf protobuf)
{
	PgQuery__ParseResult *result = NULL;
	List * list = NULL;
	size_t i = 0;

	result = pg_query__parse_result__unpack(NULL, protobuf.len, (const uint8_t *) protobuf.data);

	// TODO: Handle this by returning an error instead
	Assert(result != NULL);

	// TODO: Handle this by returning an error instead
	Assert(result->version == PG_VERSION_NUM);

	if (result->n_stmts > 0)
		list = list_make1(_readRawStmt(result->stmts[0]));
    for (i = 1; i < result->n_stmts; i++)
		list = lappend(list, _readRawStmt(result->stmts[i]));

	pg_query__parse_result__free_unpacked(result, NULL);

	return list;
}
