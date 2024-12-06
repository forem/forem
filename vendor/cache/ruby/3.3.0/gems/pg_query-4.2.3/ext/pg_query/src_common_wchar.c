/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - pg_encoding_max_length
 * - pg_wchar_table
 * - pg_utf_mblen
 * - pg_mule_mblen
 * - pg_ascii2wchar_with_len
 * - pg_wchar2single_with_len
 * - pg_ascii_mblen
 * - pg_ascii_dsplen
 * - pg_ascii_verifychar
 * - pg_ascii_verifystr
 * - pg_eucjp2wchar_with_len
 * - pg_euc2wchar_with_len
 * - pg_wchar2euc_with_len
 * - pg_eucjp_mblen
 * - pg_euc_mblen
 * - pg_eucjp_dsplen
 * - pg_eucjp_verifychar
 * - pg_eucjp_verifystr
 * - pg_euccn2wchar_with_len
 * - pg_euccn_mblen
 * - pg_euccn_dsplen
 * - pg_euckr_verifychar
 * - pg_euckr_verifystr
 * - pg_euckr2wchar_with_len
 * - pg_euckr_mblen
 * - pg_euckr_dsplen
 * - pg_euc_dsplen
 * - pg_euctw2wchar_with_len
 * - pg_euctw_mblen
 * - pg_euctw_dsplen
 * - pg_euctw_verifychar
 * - pg_euctw_verifystr
 * - pg_utf2wchar_with_len
 * - pg_wchar2utf_with_len
 * - unicode_to_utf8
 * - pg_utf_dsplen
 * - utf8_to_unicode
 * - ucs_wcwidth
 * - mbbisearch
 * - pg_utf8_verifychar
 * - pg_utf8_islegal
 * - pg_utf8_verifystr
 * - utf8_advance
 * - Utf8Transition
 * - pg_mule2wchar_with_len
 * - pg_wchar2mule_with_len
 * - pg_mule_dsplen
 * - pg_mule_verifychar
 * - pg_mule_verifystr
 * - pg_latin12wchar_with_len
 * - pg_latin1_mblen
 * - pg_latin1_dsplen
 * - pg_latin1_verifychar
 * - pg_latin1_verifystr
 * - pg_sjis_mblen
 * - pg_sjis_dsplen
 * - pg_sjis_verifychar
 * - pg_sjis_verifystr
 * - pg_big5_mblen
 * - pg_big5_dsplen
 * - pg_big5_verifychar
 * - pg_big5_verifystr
 * - pg_gbk_mblen
 * - pg_gbk_dsplen
 * - pg_gbk_verifychar
 * - pg_gbk_verifystr
 * - pg_uhc_mblen
 * - pg_uhc_dsplen
 * - pg_uhc_verifychar
 * - pg_uhc_verifystr
 * - pg_gb18030_mblen
 * - pg_gb18030_dsplen
 * - pg_gb18030_verifychar
 * - pg_gb18030_verifystr
 * - pg_johab_mblen
 * - pg_johab_dsplen
 * - pg_johab_verifychar
 * - pg_johab_verifystr
 * - pg_encoding_mblen
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * wchar.c
 *	  Functions for working with multibyte characters in various encodings.
 *
 * Portions Copyright (c) 1998-2022, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  src/common/wchar.c
 *
 *-------------------------------------------------------------------------
 */
#include "c.h"

#include "mb/pg_wchar.h"


/*
 * Operations on multi-byte encodings are driven by a table of helper
 * functions.
 *
 * To add an encoding support, define mblen(), dsplen(), verifychar() and
 * verifystr() for the encoding.  For server-encodings, also define mb2wchar()
 * and wchar2mb() conversion functions.
 *
 * These functions generally assume that their input is validly formed.
 * The "verifier" functions, further down in the file, have to be more
 * paranoid.
 *
 * We expect that mblen() does not need to examine more than the first byte
 * of the character to discover the correct length.  GB18030 is an exception
 * to that rule, though, as it also looks at second byte.  But even that
 * behaves in a predictable way, if you only pass the first byte: it will
 * treat 4-byte encoded characters as two 2-byte encoded characters, which is
 * good enough for all current uses.
 *
 * Note: for the display output of psql to work properly, the return values
 * of the dsplen functions must conform to the Unicode standard. In particular
 * the NUL character is zero width and control characters are generally
 * width -1. It is recommended that non-ASCII encodings refer their ASCII
 * subset to the ASCII routines to ensure consistency.
 */

/*
 * SQL/ASCII
 */
static int
pg_ascii2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		*to++ = *from++;
		len--;
		cnt++;
	}
	*to = 0;
	return cnt;
}

static int
pg_ascii_mblen(const unsigned char *s)
{
	return 1;
}

static int
pg_ascii_dsplen(const unsigned char *s)
{
	if (*s == '\0')
		return 0;
	if (*s < 0x20 || *s == 0x7f)
		return -1;

	return 1;
}

/*
 * EUC
 */
static int
pg_euc2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		if (*from == SS2 && len >= 2)	/* JIS X 0201 (so called "1 byte
										 * KANA") */
		{
			from++;
			*to = (SS2 << 8) | *from++;
			len -= 2;
		}
		else if (*from == SS3 && len >= 3)	/* JIS X 0212 KANJI */
		{
			from++;
			*to = (SS3 << 16) | (*from++ << 8);
			*to |= *from++;
			len -= 3;
		}
		else if (IS_HIGHBIT_SET(*from) && len >= 2) /* JIS X 0208 KANJI */
		{
			*to = *from++ << 8;
			*to |= *from++;
			len -= 2;
		}
		else					/* must be ASCII */
		{
			*to = *from++;
			len--;
		}
		to++;
		cnt++;
	}
	*to = 0;
	return cnt;
}

static inline int
pg_euc_mblen(const unsigned char *s)
{
	int			len;

	if (*s == SS2)
		len = 2;
	else if (*s == SS3)
		len = 3;
	else if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = 1;
	return len;
}

static inline int
pg_euc_dsplen(const unsigned char *s)
{
	int			len;

	if (*s == SS2)
		len = 2;
	else if (*s == SS3)
		len = 2;
	else if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = pg_ascii_dsplen(s);
	return len;
}

/*
 * EUC_JP
 */
static int
pg_eucjp2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	return pg_euc2wchar_with_len(from, to, len);
}

static int
pg_eucjp_mblen(const unsigned char *s)
{
	return pg_euc_mblen(s);
}

static int
pg_eucjp_dsplen(const unsigned char *s)
{
	int			len;

	if (*s == SS2)
		len = 1;
	else if (*s == SS3)
		len = 2;
	else if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = pg_ascii_dsplen(s);
	return len;
}

/*
 * EUC_KR
 */
static int
pg_euckr2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	return pg_euc2wchar_with_len(from, to, len);
}

static int
pg_euckr_mblen(const unsigned char *s)
{
	return pg_euc_mblen(s);
}

static int
pg_euckr_dsplen(const unsigned char *s)
{
	return pg_euc_dsplen(s);
}

/*
 * EUC_CN
 *
 */
static int
pg_euccn2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		if (*from == SS2 && len >= 3)	/* code set 2 (unused?) */
		{
			from++;
			*to = (SS2 << 16) | (*from++ << 8);
			*to |= *from++;
			len -= 3;
		}
		else if (*from == SS3 && len >= 3)	/* code set 3 (unused ?) */
		{
			from++;
			*to = (SS3 << 16) | (*from++ << 8);
			*to |= *from++;
			len -= 3;
		}
		else if (IS_HIGHBIT_SET(*from) && len >= 2) /* code set 1 */
		{
			*to = *from++ << 8;
			*to |= *from++;
			len -= 2;
		}
		else
		{
			*to = *from++;
			len--;
		}
		to++;
		cnt++;
	}
	*to = 0;
	return cnt;
}

static int
pg_euccn_mblen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = 1;
	return len;
}

static int
pg_euccn_dsplen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = pg_ascii_dsplen(s);
	return len;
}

/*
 * EUC_TW
 *
 */
static int
pg_euctw2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		if (*from == SS2 && len >= 4)	/* code set 2 */
		{
			from++;
			*to = (((uint32) SS2) << 24) | (*from++ << 16);
			*to |= *from++ << 8;
			*to |= *from++;
			len -= 4;
		}
		else if (*from == SS3 && len >= 3)	/* code set 3 (unused?) */
		{
			from++;
			*to = (SS3 << 16) | (*from++ << 8);
			*to |= *from++;
			len -= 3;
		}
		else if (IS_HIGHBIT_SET(*from) && len >= 2) /* code set 2 */
		{
			*to = *from++ << 8;
			*to |= *from++;
			len -= 2;
		}
		else
		{
			*to = *from++;
			len--;
		}
		to++;
		cnt++;
	}
	*to = 0;
	return cnt;
}

static int
pg_euctw_mblen(const unsigned char *s)
{
	int			len;

	if (*s == SS2)
		len = 4;
	else if (*s == SS3)
		len = 3;
	else if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = 1;
	return len;
}

static int
pg_euctw_dsplen(const unsigned char *s)
{
	int			len;

	if (*s == SS2)
		len = 2;
	else if (*s == SS3)
		len = 2;
	else if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = pg_ascii_dsplen(s);
	return len;
}

/*
 * Convert pg_wchar to EUC_* encoding.
 * caller must allocate enough space for "to", including a trailing zero!
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_wchar2euc_with_len(const pg_wchar *from, unsigned char *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		unsigned char c;

		if ((c = (*from >> 24)))
		{
			*to++ = c;
			*to++ = (*from >> 16) & 0xff;
			*to++ = (*from >> 8) & 0xff;
			*to++ = *from & 0xff;
			cnt += 4;
		}
		else if ((c = (*from >> 16)))
		{
			*to++ = c;
			*to++ = (*from >> 8) & 0xff;
			*to++ = *from & 0xff;
			cnt += 3;
		}
		else if ((c = (*from >> 8)))
		{
			*to++ = c;
			*to++ = *from & 0xff;
			cnt += 2;
		}
		else
		{
			*to++ = *from;
			cnt++;
		}
		from++;
		len--;
	}
	*to = 0;
	return cnt;
}


/*
 * JOHAB
 */
static int
pg_johab_mblen(const unsigned char *s)
{
	return pg_euc_mblen(s);
}

static int
pg_johab_dsplen(const unsigned char *s)
{
	return pg_euc_dsplen(s);
}

/*
 * convert UTF8 string to pg_wchar (UCS-4)
 * caller must allocate enough space for "to", including a trailing zero!
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_utf2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;
	uint32		c1,
				c2,
				c3,
				c4;

	while (len > 0 && *from)
	{
		if ((*from & 0x80) == 0)
		{
			*to = *from++;
			len--;
		}
		else if ((*from & 0xe0) == 0xc0)
		{
			if (len < 2)
				break;			/* drop trailing incomplete char */
			c1 = *from++ & 0x1f;
			c2 = *from++ & 0x3f;
			*to = (c1 << 6) | c2;
			len -= 2;
		}
		else if ((*from & 0xf0) == 0xe0)
		{
			if (len < 3)
				break;			/* drop trailing incomplete char */
			c1 = *from++ & 0x0f;
			c2 = *from++ & 0x3f;
			c3 = *from++ & 0x3f;
			*to = (c1 << 12) | (c2 << 6) | c3;
			len -= 3;
		}
		else if ((*from & 0xf8) == 0xf0)
		{
			if (len < 4)
				break;			/* drop trailing incomplete char */
			c1 = *from++ & 0x07;
			c2 = *from++ & 0x3f;
			c3 = *from++ & 0x3f;
			c4 = *from++ & 0x3f;
			*to = (c1 << 18) | (c2 << 12) | (c3 << 6) | c4;
			len -= 4;
		}
		else
		{
			/* treat a bogus char as length 1; not ours to raise error */
			*to = *from++;
			len--;
		}
		to++;
		cnt++;
	}
	*to = 0;
	return cnt;
}


/*
 * Map a Unicode code point to UTF-8.  utf8string must have 4 bytes of
 * space allocated.
 */
unsigned char *
unicode_to_utf8(pg_wchar c, unsigned char *utf8string)
{
	if (c <= 0x7F)
	{
		utf8string[0] = c;
	}
	else if (c <= 0x7FF)
	{
		utf8string[0] = 0xC0 | ((c >> 6) & 0x1F);
		utf8string[1] = 0x80 | (c & 0x3F);
	}
	else if (c <= 0xFFFF)
	{
		utf8string[0] = 0xE0 | ((c >> 12) & 0x0F);
		utf8string[1] = 0x80 | ((c >> 6) & 0x3F);
		utf8string[2] = 0x80 | (c & 0x3F);
	}
	else
	{
		utf8string[0] = 0xF0 | ((c >> 18) & 0x07);
		utf8string[1] = 0x80 | ((c >> 12) & 0x3F);
		utf8string[2] = 0x80 | ((c >> 6) & 0x3F);
		utf8string[3] = 0x80 | (c & 0x3F);
	}

	return utf8string;
}

/*
 * Trivial conversion from pg_wchar to UTF-8.
 * caller should allocate enough space for "to"
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_wchar2utf_with_len(const pg_wchar *from, unsigned char *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		int			char_len;

		unicode_to_utf8(*from, to);
		char_len = pg_utf_mblen(to);
		cnt += char_len;
		to += char_len;
		from++;
		len--;
	}
	*to = 0;
	return cnt;
}

/*
 * Return the byte length of a UTF8 character pointed to by s
 *
 * Note: in the current implementation we do not support UTF8 sequences
 * of more than 4 bytes; hence do NOT return a value larger than 4.
 * We return "1" for any leading byte that is either flat-out illegal or
 * indicates a length larger than we support.
 *
 * pg_utf2wchar_with_len(), utf8_to_unicode(), pg_utf8_islegal(), and perhaps
 * other places would need to be fixed to change this.
 */
int
pg_utf_mblen(const unsigned char *s)
{
	int			len;

	if ((*s & 0x80) == 0)
		len = 1;
	else if ((*s & 0xe0) == 0xc0)
		len = 2;
	else if ((*s & 0xf0) == 0xe0)
		len = 3;
	else if ((*s & 0xf8) == 0xf0)
		len = 4;
#ifdef NOT_USED
	else if ((*s & 0xfc) == 0xf8)
		len = 5;
	else if ((*s & 0xfe) == 0xfc)
		len = 6;
#endif
	else
		len = 1;
	return len;
}

/*
 * This is an implementation of wcwidth() and wcswidth() as defined in
 * "The Single UNIX Specification, Version 2, The Open Group, 1997"
 * <http://www.unix.org/online.html>
 *
 * Markus Kuhn -- 2001-09-08 -- public domain
 *
 * customised for PostgreSQL
 *
 * original available at : http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c
 */

struct mbinterval
{
	unsigned int first;
	unsigned int last;
};

/* auxiliary function for binary search in interval table */
static int
mbbisearch(pg_wchar ucs, const struct mbinterval *table, int max)
{
	int			min = 0;
	int			mid;

	if (ucs < table[0].first || ucs > table[max].last)
		return 0;
	while (max >= min)
	{
		mid = (min + max) / 2;
		if (ucs > table[mid].last)
			min = mid + 1;
		else if (ucs < table[mid].first)
			max = mid - 1;
		else
			return 1;
	}

	return 0;
}


/* The following functions define the column width of an ISO 10646
 * character as follows:
 *
 *	  - The null character (U+0000) has a column width of 0.
 *
 *	  - Other C0/C1 control characters and DEL will lead to a return
 *		value of -1.
 *
 *	  - Non-spacing and enclosing combining characters (general
 *		category code Mn or Me in the Unicode database) have a
 *		column width of 0.
 *
 *	  - Spacing characters in the East Asian Wide (W) or East Asian
 *		FullWidth (F) category as defined in Unicode Technical
 *		Report #11 have a column width of 2.
 *
 *	  - All remaining characters (including all printable
 *		ISO 8859-1 and WGL4 characters, Unicode control characters,
 *		etc.) have a column width of 1.
 *
 * This implementation assumes that wchar_t characters are encoded
 * in ISO 10646.
 */

static int
ucs_wcwidth(pg_wchar ucs)
{
#include "common/unicode_combining_table.h"
#include "common/unicode_east_asian_fw_table.h"

	/* test for 8-bit control characters */
	if (ucs == 0)
		return 0;

	if (ucs < 0x20 || (ucs >= 0x7f && ucs < 0xa0) || ucs > 0x0010ffff)
		return -1;

	/*
	 * binary search in table of non-spacing characters
	 *
	 * XXX: In the official Unicode sources, it is possible for a character to
	 * be described as both non-spacing and wide at the same time. As of
	 * Unicode 13.0, treating the non-spacing property as the determining
	 * factor for display width leads to the correct behavior, so do that
	 * search first.
	 */
	if (mbbisearch(ucs, combining,
				   sizeof(combining) / sizeof(struct mbinterval) - 1))
		return 0;

	/* binary search in table of wide characters */
	if (mbbisearch(ucs, east_asian_fw,
				   sizeof(east_asian_fw) / sizeof(struct mbinterval) - 1))
		return 2;

	return 1;
}

/*
 * Convert a UTF-8 character to a Unicode code point.
 * This is a one-character version of pg_utf2wchar_with_len.
 *
 * No error checks here, c must point to a long-enough string.
 */
pg_wchar
utf8_to_unicode(const unsigned char *c)
{
	if ((*c & 0x80) == 0)
		return (pg_wchar) c[0];
	else if ((*c & 0xe0) == 0xc0)
		return (pg_wchar) (((c[0] & 0x1f) << 6) |
						   (c[1] & 0x3f));
	else if ((*c & 0xf0) == 0xe0)
		return (pg_wchar) (((c[0] & 0x0f) << 12) |
						   ((c[1] & 0x3f) << 6) |
						   (c[2] & 0x3f));
	else if ((*c & 0xf8) == 0xf0)
		return (pg_wchar) (((c[0] & 0x07) << 18) |
						   ((c[1] & 0x3f) << 12) |
						   ((c[2] & 0x3f) << 6) |
						   (c[3] & 0x3f));
	else
		/* that is an invalid code on purpose */
		return 0xffffffff;
}

static int
pg_utf_dsplen(const unsigned char *s)
{
	return ucs_wcwidth(utf8_to_unicode(s));
}

/*
 * convert mule internal code to pg_wchar
 * caller should allocate enough space for "to"
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_mule2wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		if (IS_LC1(*from) && len >= 2)
		{
			*to = *from++ << 16;
			*to |= *from++;
			len -= 2;
		}
		else if (IS_LCPRV1(*from) && len >= 3)
		{
			from++;
			*to = *from++ << 16;
			*to |= *from++;
			len -= 3;
		}
		else if (IS_LC2(*from) && len >= 3)
		{
			*to = *from++ << 16;
			*to |= *from++ << 8;
			*to |= *from++;
			len -= 3;
		}
		else if (IS_LCPRV2(*from) && len >= 4)
		{
			from++;
			*to = *from++ << 16;
			*to |= *from++ << 8;
			*to |= *from++;
			len -= 4;
		}
		else
		{						/* assume ASCII */
			*to = (unsigned char) *from++;
			len--;
		}
		to++;
		cnt++;
	}
	*to = 0;
	return cnt;
}

/*
 * convert pg_wchar to mule internal code
 * caller should allocate enough space for "to"
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_wchar2mule_with_len(const pg_wchar *from, unsigned char *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		unsigned char lb;

		lb = (*from >> 16) & 0xff;
		if (IS_LC1(lb))
		{
			*to++ = lb;
			*to++ = *from & 0xff;
			cnt += 2;
		}
		else if (IS_LC2(lb))
		{
			*to++ = lb;
			*to++ = (*from >> 8) & 0xff;
			*to++ = *from & 0xff;
			cnt += 3;
		}
		else if (IS_LCPRV1_A_RANGE(lb))
		{
			*to++ = LCPRV1_A;
			*to++ = lb;
			*to++ = *from & 0xff;
			cnt += 3;
		}
		else if (IS_LCPRV1_B_RANGE(lb))
		{
			*to++ = LCPRV1_B;
			*to++ = lb;
			*to++ = *from & 0xff;
			cnt += 3;
		}
		else if (IS_LCPRV2_A_RANGE(lb))
		{
			*to++ = LCPRV2_A;
			*to++ = lb;
			*to++ = (*from >> 8) & 0xff;
			*to++ = *from & 0xff;
			cnt += 4;
		}
		else if (IS_LCPRV2_B_RANGE(lb))
		{
			*to++ = LCPRV2_B;
			*to++ = lb;
			*to++ = (*from >> 8) & 0xff;
			*to++ = *from & 0xff;
			cnt += 4;
		}
		else
		{
			*to++ = *from & 0xff;
			cnt += 1;
		}
		from++;
		len--;
	}
	*to = 0;
	return cnt;
}

/* exported for direct use by conv.c */
int
pg_mule_mblen(const unsigned char *s)
{
	int			len;

	if (IS_LC1(*s))
		len = 2;
	else if (IS_LCPRV1(*s))
		len = 3;
	else if (IS_LC2(*s))
		len = 3;
	else if (IS_LCPRV2(*s))
		len = 4;
	else
		len = 1;				/* assume ASCII */
	return len;
}

static int
pg_mule_dsplen(const unsigned char *s)
{
	int			len;

	/*
	 * Note: it's not really appropriate to assume that all multibyte charsets
	 * are double-wide on screen.  But this seems an okay approximation for
	 * the MULE charsets we currently support.
	 */

	if (IS_LC1(*s))
		len = 1;
	else if (IS_LCPRV1(*s))
		len = 1;
	else if (IS_LC2(*s))
		len = 2;
	else if (IS_LCPRV2(*s))
		len = 2;
	else
		len = 1;				/* assume ASCII */

	return len;
}

/*
 * ISO8859-1
 */
static int
pg_latin12wchar_with_len(const unsigned char *from, pg_wchar *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		*to++ = *from++;
		len--;
		cnt++;
	}
	*to = 0;
	return cnt;
}

/*
 * Trivial conversion from pg_wchar to single byte encoding. Just ignores
 * high bits.
 * caller should allocate enough space for "to"
 * len: length of from.
 * "from" not necessarily null terminated.
 */
static int
pg_wchar2single_with_len(const pg_wchar *from, unsigned char *to, int len)
{
	int			cnt = 0;

	while (len > 0 && *from)
	{
		*to++ = *from++;
		len--;
		cnt++;
	}
	*to = 0;
	return cnt;
}

static int
pg_latin1_mblen(const unsigned char *s)
{
	return 1;
}

static int
pg_latin1_dsplen(const unsigned char *s)
{
	return pg_ascii_dsplen(s);
}

/*
 * SJIS
 */
static int
pg_sjis_mblen(const unsigned char *s)
{
	int			len;

	if (*s >= 0xa1 && *s <= 0xdf)
		len = 1;				/* 1 byte kana? */
	else if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = 1;				/* should be ASCII */
	return len;
}

static int
pg_sjis_dsplen(const unsigned char *s)
{
	int			len;

	if (*s >= 0xa1 && *s <= 0xdf)
		len = 1;				/* 1 byte kana? */
	else if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = pg_ascii_dsplen(s);	/* should be ASCII */
	return len;
}

/*
 * Big5
 */
static int
pg_big5_mblen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = 1;				/* should be ASCII */
	return len;
}

static int
pg_big5_dsplen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = pg_ascii_dsplen(s);	/* should be ASCII */
	return len;
}

/*
 * GBK
 */
static int
pg_gbk_mblen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = 1;				/* should be ASCII */
	return len;
}

static int
pg_gbk_dsplen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* kanji? */
	else
		len = pg_ascii_dsplen(s);	/* should be ASCII */
	return len;
}

/*
 * UHC
 */
static int
pg_uhc_mblen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* 2byte? */
	else
		len = 1;				/* should be ASCII */
	return len;
}

static int
pg_uhc_dsplen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;				/* 2byte? */
	else
		len = pg_ascii_dsplen(s);	/* should be ASCII */
	return len;
}

/*
 * GB18030
 *	Added by Bill Huang <bhuang@redhat.com>,<bill_huanghb@ybb.ne.jp>
 */

/*
 * Unlike all other mblen() functions, this also looks at the second byte of
 * the input.  However, if you only pass the first byte of a multi-byte
 * string, and \0 as the second byte, this still works in a predictable way:
 * a 4-byte character will be reported as two 2-byte characters.  That's
 * enough for all current uses, as a client-only encoding.  It works that
 * way, because in any valid 4-byte GB18030-encoded character, the third and
 * fourth byte look like a 2-byte encoded character, when looked at
 * separately.
 */
static int
pg_gb18030_mblen(const unsigned char *s)
{
	int			len;

	if (!IS_HIGHBIT_SET(*s))
		len = 1;				/* ASCII */
	else if (*(s + 1) >= 0x30 && *(s + 1) <= 0x39)
		len = 4;
	else
		len = 2;
	return len;
}

static int
pg_gb18030_dsplen(const unsigned char *s)
{
	int			len;

	if (IS_HIGHBIT_SET(*s))
		len = 2;
	else
		len = pg_ascii_dsplen(s);	/* ASCII */
	return len;
}

/*
 *-------------------------------------------------------------------
 * multibyte sequence validators
 *
 * The verifychar functions accept "s", a pointer to the first byte of a
 * string, and "len", the remaining length of the string.  If there is a
 * validly encoded character beginning at *s, return its length in bytes;
 * else return -1.
 *
 * The verifystr functions also accept "s", a pointer to a string and "len",
 * the length of the string.  They verify the whole string, and return the
 * number of input bytes (<= len) that are valid.  In other words, if the
 * whole string is valid, verifystr returns "len", otherwise it returns the
 * byte offset of the first invalid character.  The verifystr functions must
 * test for and reject zeroes in the input.
 *
 * The verifychar functions can assume that len > 0 and that *s != '\0', but
 * they must test for and reject zeroes in any additional bytes of a
 * multibyte character.  Note that this definition allows the function for a
 * single-byte encoding to be just "return 1".
 *-------------------------------------------------------------------
 */
static int
pg_ascii_verifychar(const unsigned char *s, int len)
{
	return 1;
}

static int
pg_ascii_verifystr(const unsigned char *s, int len)
{
	const unsigned char *nullpos = memchr(s, 0, len);

	if (nullpos == NULL)
		return len;
	else
		return nullpos - s;
}

#define IS_EUC_RANGE_VALID(c)	((c) >= 0xa1 && (c) <= 0xfe)

static int
pg_eucjp_verifychar(const unsigned char *s, int len)
{
	int			l;
	unsigned char c1,
				c2;

	c1 = *s++;

	switch (c1)
	{
		case SS2:				/* JIS X 0201 */
			l = 2;
			if (l > len)
				return -1;
			c2 = *s++;
			if (c2 < 0xa1 || c2 > 0xdf)
				return -1;
			break;

		case SS3:				/* JIS X 0212 */
			l = 3;
			if (l > len)
				return -1;
			c2 = *s++;
			if (!IS_EUC_RANGE_VALID(c2))
				return -1;
			c2 = *s++;
			if (!IS_EUC_RANGE_VALID(c2))
				return -1;
			break;

		default:
			if (IS_HIGHBIT_SET(c1)) /* JIS X 0208? */
			{
				l = 2;
				if (l > len)
					return -1;
				if (!IS_EUC_RANGE_VALID(c1))
					return -1;
				c2 = *s++;
				if (!IS_EUC_RANGE_VALID(c2))
					return -1;
			}
			else
				/* must be ASCII */
			{
				l = 1;
			}
			break;
	}

	return l;
}

static int
pg_eucjp_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_eucjp_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_euckr_verifychar(const unsigned char *s, int len)
{
	int			l;
	unsigned char c1,
				c2;

	c1 = *s++;

	if (IS_HIGHBIT_SET(c1))
	{
		l = 2;
		if (l > len)
			return -1;
		if (!IS_EUC_RANGE_VALID(c1))
			return -1;
		c2 = *s++;
		if (!IS_EUC_RANGE_VALID(c2))
			return -1;
	}
	else
		/* must be ASCII */
	{
		l = 1;
	}

	return l;
}

static int
pg_euckr_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_euckr_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

/* EUC-CN byte sequences are exactly same as EUC-KR */
#define pg_euccn_verifychar	pg_euckr_verifychar
#define pg_euccn_verifystr	pg_euckr_verifystr

static int
pg_euctw_verifychar(const unsigned char *s, int len)
{
	int			l;
	unsigned char c1,
				c2;

	c1 = *s++;

	switch (c1)
	{
		case SS2:				/* CNS 11643 Plane 1-7 */
			l = 4;
			if (l > len)
				return -1;
			c2 = *s++;
			if (c2 < 0xa1 || c2 > 0xa7)
				return -1;
			c2 = *s++;
			if (!IS_EUC_RANGE_VALID(c2))
				return -1;
			c2 = *s++;
			if (!IS_EUC_RANGE_VALID(c2))
				return -1;
			break;

		case SS3:				/* unused */
			return -1;

		default:
			if (IS_HIGHBIT_SET(c1)) /* CNS 11643 Plane 1 */
			{
				l = 2;
				if (l > len)
					return -1;
				/* no further range check on c1? */
				c2 = *s++;
				if (!IS_EUC_RANGE_VALID(c2))
					return -1;
			}
			else
				/* must be ASCII */
			{
				l = 1;
			}
			break;
	}
	return l;
}

static int
pg_euctw_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_euctw_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_johab_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;
	unsigned char c;

	l = mbl = pg_johab_mblen(s);

	if (len < l)
		return -1;

	if (!IS_HIGHBIT_SET(*s))
		return mbl;

	while (--l > 0)
	{
		c = *++s;
		if (!IS_EUC_RANGE_VALID(c))
			return -1;
	}
	return mbl;
}

static int
pg_johab_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_johab_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_mule_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;
	unsigned char c;

	l = mbl = pg_mule_mblen(s);

	if (len < l)
		return -1;

	while (--l > 0)
	{
		c = *++s;
		if (!IS_HIGHBIT_SET(c))
			return -1;
	}
	return mbl;
}

static int
pg_mule_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_mule_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_latin1_verifychar(const unsigned char *s, int len)
{
	return 1;
}

static int
pg_latin1_verifystr(const unsigned char *s, int len)
{
	const unsigned char *nullpos = memchr(s, 0, len);

	if (nullpos == NULL)
		return len;
	else
		return nullpos - s;
}

static int
pg_sjis_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;
	unsigned char c1,
				c2;

	l = mbl = pg_sjis_mblen(s);

	if (len < l)
		return -1;

	if (l == 1)					/* pg_sjis_mblen already verified it */
		return mbl;

	c1 = *s++;
	c2 = *s;
	if (!ISSJISHEAD(c1) || !ISSJISTAIL(c2))
		return -1;
	return mbl;
}

static int
pg_sjis_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_sjis_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_big5_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;

	l = mbl = pg_big5_mblen(s);

	if (len < l)
		return -1;

	while (--l > 0)
	{
		if (*++s == '\0')
			return -1;
	}

	return mbl;
}

static int
pg_big5_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_big5_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_gbk_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;

	l = mbl = pg_gbk_mblen(s);

	if (len < l)
		return -1;

	while (--l > 0)
	{
		if (*++s == '\0')
			return -1;
	}

	return mbl;
}

static int
pg_gbk_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_gbk_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_uhc_verifychar(const unsigned char *s, int len)
{
	int			l,
				mbl;

	l = mbl = pg_uhc_mblen(s);

	if (len < l)
		return -1;

	while (--l > 0)
	{
		if (*++s == '\0')
			return -1;
	}

	return mbl;
}

static int
pg_uhc_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_uhc_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_gb18030_verifychar(const unsigned char *s, int len)
{
	int			l;

	if (!IS_HIGHBIT_SET(*s))
		l = 1;					/* ASCII */
	else if (len >= 4 && *(s + 1) >= 0x30 && *(s + 1) <= 0x39)
	{
		/* Should be 4-byte, validate remaining bytes */
		if (*s >= 0x81 && *s <= 0xfe &&
			*(s + 2) >= 0x81 && *(s + 2) <= 0xfe &&
			*(s + 3) >= 0x30 && *(s + 3) <= 0x39)
			l = 4;
		else
			l = -1;
	}
	else if (len >= 2 && *s >= 0x81 && *s <= 0xfe)
	{
		/* Should be 2-byte, validate */
		if ((*(s + 1) >= 0x40 && *(s + 1) <= 0x7e) ||
			(*(s + 1) >= 0x80 && *(s + 1) <= 0xfe))
			l = 2;
		else
			l = -1;
	}
	else
		l = -1;
	return l;
}

static int
pg_gb18030_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;

	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_gb18030_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

static int
pg_utf8_verifychar(const unsigned char *s, int len)
{
	int			l;

	if ((*s & 0x80) == 0)
	{
		if (*s == '\0')
			return -1;
		return 1;
	}
	else if ((*s & 0xe0) == 0xc0)
		l = 2;
	else if ((*s & 0xf0) == 0xe0)
		l = 3;
	else if ((*s & 0xf8) == 0xf0)
		l = 4;
	else
		l = 1;

	if (l > len)
		return -1;

	if (!pg_utf8_islegal(s, l))
		return -1;

	return l;
}

/*
 * The fast path of the UTF-8 verifier uses a deterministic finite automaton
 * (DFA) for multibyte characters. In a traditional table-driven DFA, the
 * input byte and current state are used to compute an index into an array of
 * state transitions. Since the address of the next transition is dependent
 * on this computation, there is latency in executing the load instruction,
 * and the CPU is not kept busy.
 *
 * Instead, we use a "shift-based" DFA as described by Per Vognsen:
 *
 * https://gist.github.com/pervognsen/218ea17743e1442e59bb60d29b1aa725
 *
 * In a shift-based DFA, the input byte is an index into array of integers
 * whose bit pattern encodes the state transitions. To compute the next
 * state, we simply right-shift the integer by the current state and apply a
 * mask. In this scheme, the address of the transition only depends on the
 * input byte, so there is better pipelining.
 *
 * The naming convention for states and transitions was adopted from a UTF-8
 * to UTF-16/32 transcoder, whose table is reproduced below:
 *
 * https://github.com/BobSteagall/utf_utils/blob/6b7a465265de2f5fa6133d653df0c9bdd73bbcf8/src/utf_utils.cpp
 *
 * ILL  ASC  CR1  CR2  CR3  L2A  L3A  L3B  L3C  L4A  L4B  L4C CLASS / STATE
 * ==========================================================================
 * err, END, err, err, err, CS1, P3A, CS2, P3B, P4A, CS3, P4B,      | BGN/END
 * err, err, err, err, err, err, err, err, err, err, err, err,      | ERR
 *                                                                  |
 * err, err, END, END, END, err, err, err, err, err, err, err,      | CS1
 * err, err, CS1, CS1, CS1, err, err, err, err, err, err, err,      | CS2
 * err, err, CS2, CS2, CS2, err, err, err, err, err, err, err,      | CS3
 *                                                                  |
 * err, err, err, err, CS1, err, err, err, err, err, err, err,      | P3A
 * err, err, CS1, CS1, err, err, err, err, err, err, err, err,      | P3B
 *                                                                  |
 * err, err, err, CS2, CS2, err, err, err, err, err, err, err,      | P4A
 * err, err, CS2, err, err, err, err, err, err, err, err, err,      | P4B
 *
 * In the most straightforward implementation, a shift-based DFA for UTF-8
 * requires 64-bit integers to encode the transitions, but with an SMT solver
 * it's possible to find state numbers such that the transitions fit within
 * 32-bit integers, as Dougall Johnson demonstrated:
 *
 * https://gist.github.com/dougallj/166e326de6ad4cf2c94be97a204c025f
 *
 * This packed representation is the reason for the seemingly odd choice of
 * state values below.
 */

/* Error */
#define	ERR  0
/* Begin */
#define	BGN 11
/* Continuation states, expect 1/2/3 continuation bytes */
#define	CS1 16
#define	CS2  1
#define	CS3  5
/* Partial states, where the first continuation byte has a restricted range */
#define	P3A  6					/* Lead was E0, check for 3-byte overlong */
#define	P3B 20					/* Lead was ED, check for surrogate */
#define	P4A 25					/* Lead was F0, check for 4-byte overlong */
#define	P4B 30					/* Lead was F4, check for too-large */
/* Begin and End are the same state */
#define	END BGN

/* the encoded state transitions for the lookup table */

/* ASCII */
#define ASC (END << BGN)
/* 2-byte lead */
#define L2A (CS1 << BGN)
/* 3-byte lead */
#define L3A (P3A << BGN)
#define L3B (CS2 << BGN)
#define L3C (P3B << BGN)
/* 4-byte lead */
#define L4A (P4A << BGN)
#define L4B (CS3 << BGN)
#define L4C (P4B << BGN)
/* continuation byte */
#define CR1 (END << CS1) | (CS1 << CS2) | (CS2 << CS3) | (CS1 << P3B) | (CS2 << P4B)
#define CR2 (END << CS1) | (CS1 << CS2) | (CS2 << CS3) | (CS1 << P3B) | (CS2 << P4A)
#define CR3 (END << CS1) | (CS1 << CS2) | (CS2 << CS3) | (CS1 << P3A) | (CS2 << P4A)
/* invalid byte */
#define ILL ERR

static const uint32 Utf8Transition[256] =
{
	/* ASCII */

	ILL, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,

	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,

	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,

	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,
	ASC, ASC, ASC, ASC, ASC, ASC, ASC, ASC,

	/* continuation bytes */

	/* 80..8F */
	CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1,
	CR1, CR1, CR1, CR1, CR1, CR1, CR1, CR1,

	/* 90..9F */
	CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2,
	CR2, CR2, CR2, CR2, CR2, CR2, CR2, CR2,

	/* A0..BF */
	CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3,
	CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3,
	CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3,
	CR3, CR3, CR3, CR3, CR3, CR3, CR3, CR3,

	/* leading bytes */

	/* C0..DF */
	ILL, ILL, L2A, L2A, L2A, L2A, L2A, L2A,
	L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A,
	L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A,
	L2A, L2A, L2A, L2A, L2A, L2A, L2A, L2A,

	/* E0..EF */
	L3A, L3B, L3B, L3B, L3B, L3B, L3B, L3B,
	L3B, L3B, L3B, L3B, L3B, L3C, L3B, L3B,

	/* F0..FF */
	L4A, L4B, L4B, L4B, L4C, ILL, ILL, ILL,
	ILL, ILL, ILL, ILL, ILL, ILL, ILL, ILL
};

static void
utf8_advance(const unsigned char *s, uint32 *state, int len)
{
	/* Note: We deliberately don't check the state's value here. */
	while (len > 0)
	{
		/*
		 * It's important that the mask value is 31: In most instruction sets,
		 * a shift by a 32-bit operand is understood to be a shift by its mod
		 * 32, so the compiler should elide the mask operation.
		 */
		*state = Utf8Transition[*s++] >> (*state & 31);
		len--;
	}

	*state &= 31;
}

static int
pg_utf8_verifystr(const unsigned char *s, int len)
{
	const unsigned char *start = s;
	const int	orig_len = len;
	uint32		state = BGN;

/*
 * Sixteen seems to give the best balance of performance across different
 * byte distributions.
 */
#define STRIDE_LENGTH 16

	if (len >= STRIDE_LENGTH)
	{
		while (len >= STRIDE_LENGTH)
		{
			/*
			 * If the chunk is all ASCII, we can skip the full UTF-8 check,
			 * but we must first check for a non-END state, which means the
			 * previous chunk ended in the middle of a multibyte sequence.
			 */
			if (state != END || !is_valid_ascii(s, STRIDE_LENGTH))
				utf8_advance(s, &state, STRIDE_LENGTH);

			s += STRIDE_LENGTH;
			len -= STRIDE_LENGTH;
		}

		/* The error state persists, so we only need to check for it here. */
		if (state == ERR)
		{
			/*
			 * Start over from the beginning with the slow path so we can
			 * count the valid bytes.
			 */
			len = orig_len;
			s = start;
		}
		else if (state != END)
		{
			/*
			 * The fast path exited in the middle of a multibyte sequence.
			 * Walk backwards to find the leading byte so that the slow path
			 * can resume checking from there. We must always backtrack at
			 * least one byte, since the current byte could be e.g. an ASCII
			 * byte after a 2-byte lead, which is invalid.
			 */
			do
			{
				Assert(s > start);
				s--;
				len++;
				Assert(IS_HIGHBIT_SET(*s));
			} while (pg_utf_mblen(s) <= 1);
		}
	}

	/* check remaining bytes */
	while (len > 0)
	{
		int			l;

		/* fast path for ASCII-subset characters */
		if (!IS_HIGHBIT_SET(*s))
		{
			if (*s == '\0')
				break;
			l = 1;
		}
		else
		{
			l = pg_utf8_verifychar(s, len);
			if (l == -1)
				break;
		}
		s += l;
		len -= l;
	}

	return s - start;
}

/*
 * Check for validity of a single UTF-8 encoded character
 *
 * This directly implements the rules in RFC3629.  The bizarre-looking
 * restrictions on the second byte are meant to ensure that there isn't
 * more than one encoding of a given Unicode character point; that is,
 * you may not use a longer-than-necessary byte sequence with high order
 * zero bits to represent a character that would fit in fewer bytes.
 * To do otherwise is to create security hazards (eg, create an apparent
 * non-ASCII character that decodes to plain ASCII).
 *
 * length is assumed to have been obtained by pg_utf_mblen(), and the
 * caller must have checked that that many bytes are present in the buffer.
 */
bool
pg_utf8_islegal(const unsigned char *source, int length)
{
	unsigned char a;

	switch (length)
	{
		default:
			/* reject lengths 5 and 6 for now */
			return false;
		case 4:
			a = source[3];
			if (a < 0x80 || a > 0xBF)
				return false;
			/* FALL THRU */
		case 3:
			a = source[2];
			if (a < 0x80 || a > 0xBF)
				return false;
			/* FALL THRU */
		case 2:
			a = source[1];
			switch (*source)
			{
				case 0xE0:
					if (a < 0xA0 || a > 0xBF)
						return false;
					break;
				case 0xED:
					if (a < 0x80 || a > 0x9F)
						return false;
					break;
				case 0xF0:
					if (a < 0x90 || a > 0xBF)
						return false;
					break;
				case 0xF4:
					if (a < 0x80 || a > 0x8F)
						return false;
					break;
				default:
					if (a < 0x80 || a > 0xBF)
						return false;
					break;
			}
			/* FALL THRU */
		case 1:
			a = *source;
			if (a >= 0x80 && a < 0xC2)
				return false;
			if (a > 0xF4)
				return false;
			break;
	}
	return true;
}


/*
 *-------------------------------------------------------------------
 * encoding info table
 * XXX must be sorted by the same order as enum pg_enc (in mb/pg_wchar.h)
 *-------------------------------------------------------------------
 */
const pg_wchar_tbl pg_wchar_table[] = {
	{pg_ascii2wchar_with_len, pg_wchar2single_with_len, pg_ascii_mblen, pg_ascii_dsplen, pg_ascii_verifychar, pg_ascii_verifystr, 1},	/* PG_SQL_ASCII */
	{pg_eucjp2wchar_with_len, pg_wchar2euc_with_len, pg_eucjp_mblen, pg_eucjp_dsplen, pg_eucjp_verifychar, pg_eucjp_verifystr, 3},	/* PG_EUC_JP */
	{pg_euccn2wchar_with_len, pg_wchar2euc_with_len, pg_euccn_mblen, pg_euccn_dsplen, pg_euccn_verifychar, pg_euccn_verifystr, 2},	/* PG_EUC_CN */
	{pg_euckr2wchar_with_len, pg_wchar2euc_with_len, pg_euckr_mblen, pg_euckr_dsplen, pg_euckr_verifychar, pg_euckr_verifystr, 3},	/* PG_EUC_KR */
	{pg_euctw2wchar_with_len, pg_wchar2euc_with_len, pg_euctw_mblen, pg_euctw_dsplen, pg_euctw_verifychar, pg_euctw_verifystr, 4},	/* PG_EUC_TW */
	{pg_eucjp2wchar_with_len, pg_wchar2euc_with_len, pg_eucjp_mblen, pg_eucjp_dsplen, pg_eucjp_verifychar, pg_eucjp_verifystr, 3},	/* PG_EUC_JIS_2004 */
	{pg_utf2wchar_with_len, pg_wchar2utf_with_len, pg_utf_mblen, pg_utf_dsplen, pg_utf8_verifychar, pg_utf8_verifystr, 4},	/* PG_UTF8 */
	{pg_mule2wchar_with_len, pg_wchar2mule_with_len, pg_mule_mblen, pg_mule_dsplen, pg_mule_verifychar, pg_mule_verifystr, 4},	/* PG_MULE_INTERNAL */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN1 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN2 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN3 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN4 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN5 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN6 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN7 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN8 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN9 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_LATIN10 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1256 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1258 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN866 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN874 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_KOI8R */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1251 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1252 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* ISO-8859-5 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* ISO-8859-6 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* ISO-8859-7 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* ISO-8859-8 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1250 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1253 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1254 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1255 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_WIN1257 */
	{pg_latin12wchar_with_len, pg_wchar2single_with_len, pg_latin1_mblen, pg_latin1_dsplen, pg_latin1_verifychar, pg_latin1_verifystr, 1},	/* PG_KOI8U */
	{0, 0, pg_sjis_mblen, pg_sjis_dsplen, pg_sjis_verifychar, pg_sjis_verifystr, 2},	/* PG_SJIS */
	{0, 0, pg_big5_mblen, pg_big5_dsplen, pg_big5_verifychar, pg_big5_verifystr, 2},	/* PG_BIG5 */
	{0, 0, pg_gbk_mblen, pg_gbk_dsplen, pg_gbk_verifychar, pg_gbk_verifystr, 2},	/* PG_GBK */
	{0, 0, pg_uhc_mblen, pg_uhc_dsplen, pg_uhc_verifychar, pg_uhc_verifystr, 2},	/* PG_UHC */
	{0, 0, pg_gb18030_mblen, pg_gb18030_dsplen, pg_gb18030_verifychar, pg_gb18030_verifystr, 4},	/* PG_GB18030 */
	{0, 0, pg_johab_mblen, pg_johab_dsplen, pg_johab_verifychar, pg_johab_verifystr, 3},	/* PG_JOHAB */
	{0, 0, pg_sjis_mblen, pg_sjis_dsplen, pg_sjis_verifychar, pg_sjis_verifystr, 2} /* PG_SHIFT_JIS_2004 */
};

/*
 * Returns the byte length of a multibyte character.
 *
 * Caution: when dealing with text that is not certainly valid in the
 * specified encoding, the result may exceed the actual remaining
 * string length.  Callers that are not prepared to deal with that
 * should use pg_encoding_mblen_bounded() instead.
 */
int
pg_encoding_mblen(int encoding, const char *mbstr)
{
	return (PG_VALID_ENCODING(encoding) ?
			pg_wchar_table[encoding].mblen((const unsigned char *) mbstr) :
			pg_wchar_table[PG_SQL_ASCII].mblen((const unsigned char *) mbstr));
}

/*
 * Returns the byte length of a multibyte character; but not more than
 * the distance to end of string.
 */


/*
 * Returns the display length of a multibyte character.
 */


/*
 * Verify the first multibyte character of the given string.
 * Return its byte length if good, -1 if bad.  (See comments above for
 * full details of the mbverifychar API.)
 */


/*
 * Verify that a string is valid for the given encoding.
 * Returns the number of input bytes (<= len) that form a valid string.
 * (See comments above for full details of the mbverifystr API.)
 */


/*
 * fetch maximum length of a given encoding
 */
int
pg_encoding_max_length(int encoding)
{
	Assert(PG_VALID_ENCODING(encoding));

	return pg_wchar_table[encoding].maxmblen;
}
