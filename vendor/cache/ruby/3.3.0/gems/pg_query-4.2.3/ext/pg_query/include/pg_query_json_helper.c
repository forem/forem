#include "lib/stringinfo.h"

#define booltostr(x)	((x) ? "true" : "false")

static void
removeTrailingDelimiter(StringInfo str)
{
	if (str->len >= 1 && str->data[str->len - 1] == ',') {
		str->len -= 1;
		str->data[str->len] = '\0';
	}
}

static void
_outToken(StringInfo buf, const char *str)
{
	if (str == NULL)
	{
		appendStringInfoString(buf, "null");
		return;
	}

	// copied directly from https://github.com/postgres/postgres/blob/master/src/backend/utils/adt/json.c#L2428
	const char *p;

	appendStringInfoCharMacro(buf, '"');
	for (p = str; *p; p++)
	{
		switch (*p)
		{
			case '\b':
				appendStringInfoString(buf, "\\b");
				break;
			case '\f':
				appendStringInfoString(buf, "\\f");
				break;
			case '\n':
				appendStringInfoString(buf, "\\n");
				break;
			case '\r':
				appendStringInfoString(buf, "\\r");
				break;
			case '\t':
				appendStringInfoString(buf, "\\t");
				break;
			case '"':
				appendStringInfoString(buf, "\\\"");
				break;
			case '\\':
				appendStringInfoString(buf, "\\\\");
				break;
			default:
				if ((unsigned char) *p < ' ' || *p == '<' || *p == '>')
					appendStringInfo(buf, "\\u%04x", (int) *p);
				else
					appendStringInfoCharMacro(buf, *p);
				break;
		}
	}
	appendStringInfoCharMacro(buf, '"');
}
