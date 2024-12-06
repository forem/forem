/*-------------------------------------------------------------------------
 *
 * arch-ppc.h
 *	  Atomic operations considerations specific to PowerPC
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * NOTES:
 *
 * src/include/port/atomics/arch-ppc.h
 *
 *-------------------------------------------------------------------------
 */

#if defined(__GNUC__)

/*
 * lwsync orders loads with respect to each other, and similarly with stores.
 * But a load can be performed before a subsequent store, so sync must be used
 * for a full memory barrier.
 */
#define pg_memory_barrier_impl()	__asm__ __volatile__ ("sync" : : : "memory")
#define pg_read_barrier_impl()		__asm__ __volatile__ ("lwsync" : : : "memory")
#define pg_write_barrier_impl()		__asm__ __volatile__ ("lwsync" : : : "memory")
#endif

#define PG_HAVE_ATOMIC_U32_SUPPORT
typedef struct pg_atomic_uint32
{
	volatile uint32 value;
} pg_atomic_uint32;

/* 64bit atomics are only supported in 64bit mode */
#if SIZEOF_VOID_P >= 8
#define PG_HAVE_ATOMIC_U64_SUPPORT
typedef struct pg_atomic_uint64
{
	volatile uint64 value pg_attribute_aligned(8);
} pg_atomic_uint64;

#endif

/*
 * This mimics gcc __atomic_compare_exchange_n(..., __ATOMIC_SEQ_CST), but
 * code generation differs at the end.  __atomic_compare_exchange_n():
 *  100:	isync
 *  104:	mfcr    r3
 *  108:	rlwinm  r3,r3,3,31,31
 *  10c:	bne     120 <.eb+0x10>
 *  110:	clrldi  r3,r3,63
 *  114:	addi    r1,r1,112
 *  118:	blr
 *  11c:	nop
 *  120:	clrldi  r3,r3,63
 *  124:	stw     r9,0(r4)
 *  128:	addi    r1,r1,112
 *  12c:	blr
 *
 * This:
 *   f0:	isync
 *   f4:	mfcr    r9
 *   f8:	rldicl. r3,r9,35,63
 *   fc:	bne     104 <.eb>
 *  100:	stw     r10,0(r4)
 *  104:	addi    r1,r1,112
 *  108:	blr
 *
 * This implementation may or may not have materially different performance.
 * It's not exploiting the fact that cr0 still holds the relevant comparison
 * bits, set during the __asm__.  One could fix that by moving more code into
 * the __asm__.  (That would remove the freedom to eliminate dead stores when
 * the caller ignores "expected", but few callers do.)
 *
 * Recognizing constant "newval" would be superfluous, because there's no
 * immediate-operand version of stwcx.
 */
#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U32
static inline bool
pg_atomic_compare_exchange_u32_impl(volatile pg_atomic_uint32 *ptr,
									uint32 *expected, uint32 newval)
{
	uint32 found;
	uint32 condition_register;
	bool ret;

#ifdef HAVE_I_CONSTRAINT__BUILTIN_CONSTANT_P
	if (__builtin_constant_p(*expected) &&
		(int32) *expected <= PG_INT16_MAX &&
		(int32) *expected >= PG_INT16_MIN)
		__asm__ __volatile__(
			"	sync				\n"
			"	lwarx   %0,0,%5		\n"
			"	cmpwi   %0,%3		\n"
			"	bne     $+12		\n"		/* branch to isync */
			"	stwcx.  %4,0,%5		\n"
			"	bne     $-16		\n"		/* branch to lwarx */
			"	isync				\n"
			"	mfcr    %1          \n"
:			"=&r"(found), "=r"(condition_register), "+m"(ptr->value)
:			"i"(*expected), "r"(newval), "r"(&ptr->value)
:			"memory", "cc");
	else
#endif
		__asm__ __volatile__(
			"	sync				\n"
			"	lwarx   %0,0,%5		\n"
			"	cmpw    %0,%3		\n"
			"	bne     $+12		\n"		/* branch to isync */
			"	stwcx.  %4,0,%5		\n"
			"	bne     $-16		\n"		/* branch to lwarx */
			"	isync				\n"
			"	mfcr    %1          \n"
:			"=&r"(found), "=r"(condition_register), "+m"(ptr->value)
:			"r"(*expected), "r"(newval), "r"(&ptr->value)
:			"memory", "cc");

	ret = (condition_register >> 29) & 1;	/* test eq bit of cr0 */
	if (!ret)
		*expected = found;
	return ret;
}

/*
 * This mirrors gcc __sync_fetch_and_add().
 *
 * Like tas(), use constraint "=&b" to avoid allocating r0.
 */
#define PG_HAVE_ATOMIC_FETCH_ADD_U32
static inline uint32
pg_atomic_fetch_add_u32_impl(volatile pg_atomic_uint32 *ptr, int32 add_)
{
	uint32 _t;
	uint32 res;

#ifdef HAVE_I_CONSTRAINT__BUILTIN_CONSTANT_P
	if (__builtin_constant_p(add_) &&
		add_ <= PG_INT16_MAX && add_ >= PG_INT16_MIN)
		__asm__ __volatile__(
			"	sync				\n"
			"	lwarx   %1,0,%4		\n"
			"	addi    %0,%1,%3	\n"
			"	stwcx.  %0,0,%4		\n"
			"	bne     $-12		\n"		/* branch to lwarx */
			"	isync				\n"
:			"=&r"(_t), "=&b"(res), "+m"(ptr->value)
:			"i"(add_), "r"(&ptr->value)
:			"memory", "cc");
	else
#endif
		__asm__ __volatile__(
			"	sync				\n"
			"	lwarx   %1,0,%4		\n"
			"	add     %0,%1,%3	\n"
			"	stwcx.  %0,0,%4		\n"
			"	bne     $-12		\n"		/* branch to lwarx */
			"	isync				\n"
:			"=&r"(_t), "=&r"(res), "+m"(ptr->value)
:			"r"(add_), "r"(&ptr->value)
:			"memory", "cc");

	return res;
}

#ifdef PG_HAVE_ATOMIC_U64_SUPPORT

#define PG_HAVE_ATOMIC_COMPARE_EXCHANGE_U64
static inline bool
pg_atomic_compare_exchange_u64_impl(volatile pg_atomic_uint64 *ptr,
									uint64 *expected, uint64 newval)
{
	uint64 found;
	uint32 condition_register;
	bool ret;

	/* Like u32, but s/lwarx/ldarx/; s/stwcx/stdcx/; s/cmpw/cmpd/ */
#ifdef HAVE_I_CONSTRAINT__BUILTIN_CONSTANT_P
	if (__builtin_constant_p(*expected) &&
		(int64) *expected <= PG_INT16_MAX &&
		(int64) *expected >= PG_INT16_MIN)
		__asm__ __volatile__(
			"	sync				\n"
			"	ldarx   %0,0,%5		\n"
			"	cmpdi   %0,%3		\n"
			"	bne     $+12		\n"		/* branch to isync */
			"	stdcx.  %4,0,%5		\n"
			"	bne     $-16		\n"		/* branch to ldarx */
			"	isync				\n"
			"	mfcr    %1          \n"
:			"=&r"(found), "=r"(condition_register), "+m"(ptr->value)
:			"i"(*expected), "r"(newval), "r"(&ptr->value)
:			"memory", "cc");
	else
#endif
		__asm__ __volatile__(
			"	sync				\n"
			"	ldarx   %0,0,%5		\n"
			"	cmpd    %0,%3		\n"
			"	bne     $+12		\n"		/* branch to isync */
			"	stdcx.  %4,0,%5		\n"
			"	bne     $-16		\n"		/* branch to ldarx */
			"	isync				\n"
			"	mfcr    %1          \n"
:			"=&r"(found), "=r"(condition_register), "+m"(ptr->value)
:			"r"(*expected), "r"(newval), "r"(&ptr->value)
:			"memory", "cc");

	ret = (condition_register >> 29) & 1;	/* test eq bit of cr0 */
	if (!ret)
		*expected = found;
	return ret;
}

#define PG_HAVE_ATOMIC_FETCH_ADD_U64
static inline uint64
pg_atomic_fetch_add_u64_impl(volatile pg_atomic_uint64 *ptr, int64 add_)
{
	uint64 _t;
	uint64 res;

	/* Like u32, but s/lwarx/ldarx/; s/stwcx/stdcx/ */
#ifdef HAVE_I_CONSTRAINT__BUILTIN_CONSTANT_P
	if (__builtin_constant_p(add_) &&
		add_ <= PG_INT16_MAX && add_ >= PG_INT16_MIN)
		__asm__ __volatile__(
			"	sync				\n"
			"	ldarx   %1,0,%4		\n"
			"	addi    %0,%1,%3	\n"
			"	stdcx.  %0,0,%4		\n"
			"	bne     $-12		\n"		/* branch to ldarx */
			"	isync				\n"
:			"=&r"(_t), "=&b"(res), "+m"(ptr->value)
:			"i"(add_), "r"(&ptr->value)
:			"memory", "cc");
	else
#endif
		__asm__ __volatile__(
			"	sync				\n"
			"	ldarx   %1,0,%4		\n"
			"	add     %0,%1,%3	\n"
			"	stdcx.  %0,0,%4		\n"
			"	bne     $-12		\n"		/* branch to ldarx */
			"	isync				\n"
:			"=&r"(_t), "=&r"(res), "+m"(ptr->value)
:			"r"(add_), "r"(&ptr->value)
:			"memory", "cc");

	return res;
}

#endif /* PG_HAVE_ATOMIC_U64_SUPPORT */

/* per architecture manual doubleword accesses have single copy atomicity */
#define PG_HAVE_8BYTE_SINGLE_COPY_ATOMICITY
