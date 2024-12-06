/*-------------------------------------------------------------------------
 *
 * arch-arm.h
 *	  Atomic operations considerations specific to ARM
 *
 * Portions Copyright (c) 2013-2022, PostgreSQL Global Development Group
 *
 * NOTES:
 *
 * src/include/port/atomics/arch-arm.h
 *
 *-------------------------------------------------------------------------
 */

/* intentionally no include guards, should only be included by atomics.h */
#ifndef INSIDE_ATOMICS_H
#error "should be included via atomics.h"
#endif

/*
 * 64 bit atomics on ARM32 are implemented using kernel fallbacks and thus
 * might be slow, so disable entirely. On ARM64 that problem doesn't exist.
 */
#if !defined(__aarch64__) && !defined(__aarch64)
#define PG_DISABLE_64_BIT_ATOMICS
#else
/*
 * Architecture Reference Manual for ARMv8 states aligned read/write to/from
 * general purpose register is atomic.
 */
#define PG_HAVE_8BYTE_SINGLE_COPY_ATOMICITY
#endif  /* __aarch64__ || __aarch64 */
