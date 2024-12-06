/*-------------------------------------------------------------------------
 *
 * pg_bswap.h
 *	  Byte swapping.
 *
 * Macros for reversing the byte order of 16, 32 and 64-bit unsigned integers.
 * For example, 0xAABBCCDD becomes 0xDDCCBBAA.  These are just wrappers for
 * built-in functions provided by the compiler where support exists.
 *
 * Note that all of these functions accept unsigned integers as arguments and
 * return the same.  Use caution when using these wrapper macros with signed
 * integers.
 *
 * Copyright (c) 2015-2022, PostgreSQL Global Development Group
 *
 * src/include/port/pg_bswap.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_BSWAP_H
#define PG_BSWAP_H


/*
 * In all supported versions msvc provides _byteswap_* functions in stdlib.h,
 * already included by c.h.
 */


/* implementation of uint16 pg_bswap16(uint16) */
#if defined(HAVE__BUILTIN_BSWAP16)

#define pg_bswap16(x) __builtin_bswap16(x)

#elif defined(_MSC_VER)

#define pg_bswap16(x) _byteswap_ushort(x)

#else

static inline uint16
pg_bswap16(uint16 x)
{
	return
		((x << 8) & 0xff00) |
		((x >> 8) & 0x00ff);
}

#endif							/* HAVE__BUILTIN_BSWAP16 */


/* implementation of uint32 pg_bswap32(uint32) */
#if defined(HAVE__BUILTIN_BSWAP32)

#define pg_bswap32(x) __builtin_bswap32(x)

#elif defined(_MSC_VER)

#define pg_bswap32(x) _byteswap_ulong(x)

#else

static inline uint32
pg_bswap32(uint32 x)
{
	return
		((x << 24) & 0xff000000) |
		((x << 8) & 0x00ff0000) |
		((x >> 8) & 0x0000ff00) |
		((x >> 24) & 0x000000ff);
}

#endif							/* HAVE__BUILTIN_BSWAP32 */


/* implementation of uint64 pg_bswap64(uint64) */
#if defined(HAVE__BUILTIN_BSWAP64)

#define pg_bswap64(x) __builtin_bswap64(x)


#elif defined(_MSC_VER)

#define pg_bswap64(x) _byteswap_uint64(x)

#else

static inline uint64
pg_bswap64(uint64 x)
{
	return
		((x << 56) & UINT64CONST(0xff00000000000000)) |
		((x << 40) & UINT64CONST(0x00ff000000000000)) |
		((x << 24) & UINT64CONST(0x0000ff0000000000)) |
		((x << 8) & UINT64CONST(0x000000ff00000000)) |
		((x >> 8) & UINT64CONST(0x00000000ff000000)) |
		((x >> 24) & UINT64CONST(0x0000000000ff0000)) |
		((x >> 40) & UINT64CONST(0x000000000000ff00)) |
		((x >> 56) & UINT64CONST(0x00000000000000ff));
}
#endif							/* HAVE__BUILTIN_BSWAP64 */


/*
 * Portable and fast equivalents for ntohs, ntohl, htons, htonl,
 * additionally extended to 64 bits.
 */
#ifdef WORDS_BIGENDIAN

#define pg_hton16(x)		(x)
#define pg_hton32(x)		(x)
#define pg_hton64(x)		(x)

#define pg_ntoh16(x)		(x)
#define pg_ntoh32(x)		(x)
#define pg_ntoh64(x)		(x)

#else

#define pg_hton16(x)		pg_bswap16(x)
#define pg_hton32(x)		pg_bswap32(x)
#define pg_hton64(x)		pg_bswap64(x)

#define pg_ntoh16(x)		pg_bswap16(x)
#define pg_ntoh32(x)		pg_bswap32(x)
#define pg_ntoh64(x)		pg_bswap64(x)

#endif							/* WORDS_BIGENDIAN */


/*
 * Rearrange the bytes of a Datum from big-endian order into the native byte
 * order.  On big-endian machines, this does nothing at all.  Note that the C
 * type Datum is an unsigned integer type on all platforms.
 *
 * One possible application of the DatumBigEndianToNative() macro is to make
 * bitwise comparisons cheaper.  A simple 3-way comparison of Datums
 * transformed by the macro (based on native, unsigned comparisons) will return
 * the same result as a memcmp() of the corresponding original Datums, but can
 * be much cheaper.  It's generally safe to do this on big-endian systems
 * without any special transformation occurring first.
 *
 * If SIZEOF_DATUM is not defined, then postgres.h wasn't included and these
 * macros probably shouldn't be used, so we define nothing.  Note that
 * SIZEOF_DATUM == 8 would evaluate as 0 == 8 in that case, potentially
 * leading to the wrong implementation being selected and confusing errors, so
 * defining nothing is safest.
 */
#ifdef SIZEOF_DATUM
#ifdef WORDS_BIGENDIAN
#define		DatumBigEndianToNative(x)	(x)
#else							/* !WORDS_BIGENDIAN */
#if SIZEOF_DATUM == 8
#define		DatumBigEndianToNative(x)	pg_bswap64(x)
#else							/* SIZEOF_DATUM != 8 */
#define		DatumBigEndianToNative(x)	pg_bswap32(x)
#endif							/* SIZEOF_DATUM == 8 */
#endif							/* WORDS_BIGENDIAN */
#endif							/* SIZEOF_DATUM */

#endif							/* PG_BSWAP_H */
