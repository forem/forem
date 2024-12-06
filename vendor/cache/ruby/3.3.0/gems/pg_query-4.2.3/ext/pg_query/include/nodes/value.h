/*-------------------------------------------------------------------------
 *
 * value.h
 *	  interface for value nodes
 *
 *
 * Copyright (c) 2003-2022, PostgreSQL Global Development Group
 *
 * src/include/nodes/value.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef VALUE_H
#define VALUE_H

#include "nodes/nodes.h"

/*
 * The node types Integer, Float, String, and BitString are used to represent
 * literals in the lexer and are also used to pass constants around in the
 * parser.  One difference between these node types and, say, a plain int or
 * char * is that the nodes can be put into a List.
 *
 * (There used to be a Value node, which encompassed all these different node types.  Hence the name of this file.)
 */

typedef struct Integer
{
	NodeTag		type;
	int			ival;
} Integer;

/*
 * Float is internally represented as string.  Using T_Float as the node type
 * simply indicates that the contents of the string look like a valid numeric
 * literal.  The value might end up being converted to NUMERIC, so we can't
 * store it internally as a C double, since that could lose precision.  Since
 * these nodes are generally only used in the parsing process, not for runtime
 * data, it's better to use the more general representation.
 *
 * Note that an integer-looking string will get lexed as T_Float if the value
 * is too large to fit in an 'int'.
 */
typedef struct Float
{
	NodeTag		type;
	char	   *fval;
} Float;

typedef struct Boolean
{
	NodeTag		type;
	bool		boolval;
} Boolean;

typedef struct String
{
	NodeTag		type;
	char	   *sval;
} String;

typedef struct BitString
{
	NodeTag		type;
	char	   *bsval;
} BitString;

#define intVal(v)		(castNode(Integer, v)->ival)
#define floatVal(v)		atof(castNode(Float, v)->fval)
#define boolVal(v)		(castNode(Boolean, v)->boolval)
#define strVal(v)		(castNode(String, v)->sval)

extern Integer *makeInteger(int i);
extern Float *makeFloat(char *numericStr);
extern Boolean *makeBoolean(bool var);
extern String *makeString(char *str);
extern BitString *makeBitString(char *str);

#endif							/* VALUE_H */
