/*-------------------------------------------------------------------------
 *
 * atomics.h
 *	  Atomic operations.
 *
 * Hardware and compiler dependent functions for manipulating memory
 * atomically and dealing with cache coherency. Used to implement locking
 * facilities and lockless algorithms/data structures.
 *
 * To bring up postgres on a platform/compiler at the very least
 * implementations for the following operations should be provided:
 * * pg_compiler_barrier(), pg_write_barrier(), pg_read_barrier()
 * * pg_atomic_compare_exchange_u32(), pg_atomic_fetch_add_u32()
 * * pg_atomic_test_set_flag(), pg_atomic_init_flag(), pg_atomic_clear_flag()
 * * PG_HAVE_8BYTE_SINGLE_COPY_ATOMICITY should be defined if appropriate.
 *
 * There exist generic, hardware independent, implementations for several
 * compilers which might be sufficient, although possibly not optimal, for a
 * new platform. If no such generic implementation is available spinlocks (or
 * even OS provided semaphores) will be used to implement the API.
 *
 * Implement _u64 atomics if and only if your platform can use them
 * efficiently (and obviously correctly).
 *
 * Use higher level functionality (lwlocks, spinlocks, heavyweight locks)
 * whenever possible. Writing correct code using these facilities is hard.
 *
 * For an introduction to using memory barriers within the PostgreSQL backend,
 * see src/backend/storage/lmgr/README.barrier
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/port/atomics.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef ATOMICS_H
#define ATOMICS_H

#ifdef FRONTEND
#error "atomics.h may not be included from frontend code"
#endif

#define INSIDE_ATOMICS_H

#include <limits.h>

/*
 * First a set of architecture specific files is included.
 *
 * These files can provide the full set of atomics or can do pretty much
 * nothing if all the compilers commonly used on these platforms provide
 * usable generics.
 *
 * Don't add an inline assembly of the actual atomic operations if all the
 * common implementations of your platform provide intrinsics. Intrinsics are
 * much easier to understand and potentially support more architectures.
 *
 * It will often make sense to define memory barrier semantics here, since
 * e.g. generic compiler intrinsics for x86 memory barriers can't know that
 * postgres doesn't need x86 read/write barriers do anything more than a
 * compiler barrier.
 *
 */
#if defined(__arm__) || defined(__arm) || \
	defined(__aarch64__) || defined(__aarch64)
#include "port/atomics/arch-arm.h"
#elif defined(__i386__) || defined(__i386) || defined(__x86_64__)
#include "port/atomics/arch-x86.h"
#elif defined(__ia64__) || defined(__ia64)
#include "port/atomics/arch-ia64.h"
#elif defined(__ppc__) || defined(__powerpc__) || defined(__ppc64__) || defined(__powerpc64__)
#include "port/atomics/arch-ppc.h"
#elif defined(__hppa) || defined(__hppa__)
#include "port/atomics/arch-hppa.h"
#endif

/*
 * Compiler specific, but architecture independent implementations.
 *
 * Provide architecture independent implementations of the atomic
 * facilities. At the very least compiler barriers should be provided, but a
 * full implementation of
 * * pg_compiler_barrier(), pg_write_barrier(), pg_read_barrier()
 * * pg_atomic_compare_exchange_u32(), pg_atomic_fetch_add_u32()
 * using compiler intrinsics are a good idea.
 */
/*
 * gcc or compatible, including clang and icc.  Exclude xlc.  The ppc64le "IBM
 * XL C/C++ for Linux, V13.1.2" emulates gcc, but __sync_lock_test_and_set()
 * of one-byte types elicits SIGSEGV.  That bug was gone by V13.1.5 (2016-12).
 */
#if (defined(__GNUC__) || defined(__INTEL_COMPILER)) && !(defined(__IBMC__) || defined(__IBMCPP__))
#include "port/atomics/generic-gcc.h"
#elif defined(_MSC_VER)
#include "port/atomics/generic-msvc.h"
#elif defined(__hpux) && defined(__ia64) && !defined(__GNUC__)
#include "port/atomics/generic-acc.h"
#elif defined(__SUNPRO_C) && !defined(__GNUC__)
#include "port/atomics/generic-sunpro.h"
#else
/*
 * Unsupported compiler, we'll likely use slower fallbacks... At least
 * compiler barriers should really be provided.
 */
#endif

/*
 * Provide a full fallback of the pg_*_barrier(), pg_atomic**_flag and
 * pg_atomic_* APIs for platforms without sufficient spinlock and/or atomics
 * support. In the case of spinlock backed atomics the emulation is expected
 * to be efficient, although less so than native atomics support.
 */
#include "port/atomics/fallback.h"

/*
 * Provide additional operations using supported infrastructure. These are
 * expected to be efficient if the underlying atomic operations are efficient.
 */
#include "port/atomics/generic.h"


/*
 * pg_compiler_barrier - prevent the compiler from moving code across
 *
 * A compiler barrier need not (and preferably should not) emit any actual
 * machine code, but must act as an optimization fence: the compiler must not
 * reorder loads or stores to main memory around the barrier.  However, the
 * CPU may still reorder loads or stores at runtime, if the architecture's
 * memory model permits this.
 */
#define pg_compiler_barrier()	pg_compiler_barrier_impl()

/*
 * pg_memory_barrier - prevent the CPU from reordering memory access
 *
 * A memory barrier must act as a compiler barrier, and in addition must
 * guarantee that all loads and stores issued prior to the barrier are
 * completed before any loads or stores issued after the barrier.  Unless
 * loads and stores are totally ordered (which is not the case on most
 * architectures) this requires issuing some sort of memory fencing
 * instruction.
 */
#define pg_memory_barrier() pg_memory_barrier_impl()

/*
 * pg_(read|write)_barrier - prevent the CPU from reordering memory access
 *
 * A read barrier must act as a compiler barrier, and in addition must
 * guarantee that any loads issued prior to the barrier are completed before
 * any loads issued after the barrier.  Similarly, a write barrier acts
 * as a compiler barrier, and also orders stores.  Read and write barriers
 * are thus weaker than a full memory barrier, but stronger than a compiler
 * barrier.  In practice, on machines with strong memory ordering, read and
 * write barriers may require nothing more than a compiler barrier.
 */
#define pg_read_barrier()	pg_read_barrier_impl()
#define pg_write_barrier()	pg_write_barrier_impl()

/*
 * Spinloop delay - Allow CPU to relax in busy loops
 */
#define pg_spin_delay() pg_spin_delay_impl()

/*
 * pg_atomic_init_flag - initialize atomic flag.
 *
 * No barrier semantics.
 */
static inline void
pg_atomic_init_flag(volatile pg_atomic_flag *ptr)
{
	pg_atomic_init_flag_impl(ptr);
}

/*
 * pg_atomic_test_set_flag - TAS()
 *
 * Returns true if the flag has successfully been set, false otherwise.
 *
 * Acquire (including read barrier) semantics.
 */
static inline bool
pg_atomic_test_set_flag(volatile pg_atomic_flag *ptr)
{
	return pg_atomic_test_set_flag_impl(ptr);
}

/*
 * pg_atomic_unlocked_test_flag - Check if the lock is free
 *
 * Returns true if the flag currently is not set, false otherwise.
 *
 * No barrier semantics.
 */
static inline bool
pg_atomic_unlocked_test_flag(volatile pg_atomic_flag *ptr)
{
	return pg_atomic_unlocked_test_flag_impl(ptr);
}

/*
 * pg_atomic_clear_flag - release lock set by TAS()
 *
 * Release (including write barrier) semantics.
 */
static inline void
pg_atomic_clear_flag(volatile pg_atomic_flag *ptr)
{
	pg_atomic_clear_flag_impl(ptr);
}


/*
 * pg_atomic_init_u32 - initialize atomic variable
 *
 * Has to be done before any concurrent usage..
 *
 * No barrier semantics.
 */
static inline void
pg_atomic_init_u32(volatile pg_atomic_uint32 *ptr, uint32 val)
{
	AssertPointerAlignment(ptr, 4);

	pg_atomic_init_u32_impl(ptr, val);
}

/*
 * pg_atomic_read_u32 - unlocked read from atomic variable.
 *
 * The read is guaranteed to return a value as it has been written by this or
 * another process at some point in the past. There's however no cache
 * coherency interaction guaranteeing the value hasn't since been written to
 * again.
 *
 * No barrier semantics.
 */
static inline uint32
pg_atomic_read_u32(volatile pg_atomic_uint32 *ptr)
{
	AssertPointerAlignment(ptr, 4);
	return pg_atomic_read_u32_impl(ptr);
}

/*
 * pg_atomic_write_u32 - write to atomic variable.
 *
 * The write is guaranteed to succeed as a whole, i.e. it's not possible to
 * observe a partial write for any reader.  Note that this correctly interacts
 * with pg_atomic_compare_exchange_u32, in contrast to
 * pg_atomic_unlocked_write_u32().
 *
 * No barrier semantics.
 */
static inline void
pg_atomic_write_u32(volatile pg_atomic_uint32 *ptr, uint32 val)
{
	AssertPointerAlignment(ptr, 4);

	pg_atomic_write_u32_impl(ptr, val);
}

/*
 * pg_atomic_unlocked_write_u32 - unlocked write to atomic variable.
 *
 * The write is guaranteed to succeed as a whole, i.e. it's not possible to
 * observe a partial write for any reader.  But note that writing this way is
 * not guaranteed to correctly interact with read-modify-write operations like
 * pg_atomic_compare_exchange_u32.  This should only be used in cases where
 * minor performance regressions due to atomics emulation are unacceptable.
 *
 * No barrier semantics.
 */
static inline void
pg_atomic_unlocked_write_u32(volatile pg_atomic_uint32 *ptr, uint32 val)
{
	AssertPointerAlignment(ptr, 4);

	pg_atomic_unlocked_write_u32_impl(ptr, val);
}

/*
 * pg_atomic_exchange_u32 - exchange newval with current value
 *
 * Returns the old value of 'ptr' before the swap.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_exchange_u32(volatile pg_atomic_uint32 *ptr, uint32 newval)
{
	AssertPointerAlignment(ptr, 4);

	return pg_atomic_exchange_u32_impl(ptr, newval);
}

/*
 * pg_atomic_compare_exchange_u32 - CAS operation
 *
 * Atomically compare the current value of ptr with *expected and store newval
 * iff ptr and *expected have the same value. The current value of *ptr will
 * always be stored in *expected.
 *
 * Return true if values have been exchanged, false otherwise.
 *
 * Full barrier semantics.
 */
static inline bool
pg_atomic_compare_exchange_u32(volatile pg_atomic_uint32 *ptr,
							   uint32 *expected, uint32 newval)
{
	AssertPointerAlignment(ptr, 4);
	AssertPointerAlignment(expected, 4);

	return pg_atomic_compare_exchange_u32_impl(ptr, expected, newval);
}

/*
 * pg_atomic_fetch_add_u32 - atomically add to variable
 *
 * Returns the value of ptr before the arithmetic operation.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_fetch_add_u32(volatile pg_atomic_uint32 *ptr, int32 add_)
{
	AssertPointerAlignment(ptr, 4);
	return pg_atomic_fetch_add_u32_impl(ptr, add_);
}

/*
 * pg_atomic_fetch_sub_u32 - atomically subtract from variable
 *
 * Returns the value of ptr before the arithmetic operation. Note that sub_
 * may not be INT_MIN due to platform limitations.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_fetch_sub_u32(volatile pg_atomic_uint32 *ptr, int32 sub_)
{
	AssertPointerAlignment(ptr, 4);
	Assert(sub_ != INT_MIN);
	return pg_atomic_fetch_sub_u32_impl(ptr, sub_);
}

/*
 * pg_atomic_fetch_and_u32 - atomically bit-and and_ with variable
 *
 * Returns the value of ptr before the arithmetic operation.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_fetch_and_u32(volatile pg_atomic_uint32 *ptr, uint32 and_)
{
	AssertPointerAlignment(ptr, 4);
	return pg_atomic_fetch_and_u32_impl(ptr, and_);
}

/*
 * pg_atomic_fetch_or_u32 - atomically bit-or or_ with variable
 *
 * Returns the value of ptr before the arithmetic operation.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_fetch_or_u32(volatile pg_atomic_uint32 *ptr, uint32 or_)
{
	AssertPointerAlignment(ptr, 4);
	return pg_atomic_fetch_or_u32_impl(ptr, or_);
}

/*
 * pg_atomic_add_fetch_u32 - atomically add to variable
 *
 * Returns the value of ptr after the arithmetic operation.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_add_fetch_u32(volatile pg_atomic_uint32 *ptr, int32 add_)
{
	AssertPointerAlignment(ptr, 4);
	return pg_atomic_add_fetch_u32_impl(ptr, add_);
}

/*
 * pg_atomic_sub_fetch_u32 - atomically subtract from variable
 *
 * Returns the value of ptr after the arithmetic operation. Note that sub_ may
 * not be INT_MIN due to platform limitations.
 *
 * Full barrier semantics.
 */
static inline uint32
pg_atomic_sub_fetch_u32(volatile pg_atomic_uint32 *ptr, int32 sub_)
{
	AssertPointerAlignment(ptr, 4);
	Assert(sub_ != INT_MIN);
	return pg_atomic_sub_fetch_u32_impl(ptr, sub_);
}

/* ----
 * The 64 bit operations have the same semantics as their 32bit counterparts
 * if they are available. Check the corresponding 32bit function for
 * documentation.
 * ----
 */
static inline void
pg_atomic_init_u64(volatile pg_atomic_uint64 *ptr, uint64 val)
{
	/*
	 * Can't necessarily enforce alignment - and don't need it - when using
	 * the spinlock based fallback implementation. Therefore only assert when
	 * not using it.
	 */
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	pg_atomic_init_u64_impl(ptr, val);
}

static inline uint64
pg_atomic_read_u64(volatile pg_atomic_uint64 *ptr)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_read_u64_impl(ptr);
}

static inline void
pg_atomic_write_u64(volatile pg_atomic_uint64 *ptr, uint64 val)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	pg_atomic_write_u64_impl(ptr, val);
}

static inline uint64
pg_atomic_exchange_u64(volatile pg_atomic_uint64 *ptr, uint64 newval)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_exchange_u64_impl(ptr, newval);
}

static inline bool
pg_atomic_compare_exchange_u64(volatile pg_atomic_uint64 *ptr,
							   uint64 *expected, uint64 newval)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
	AssertPointerAlignment(expected, 8);
#endif
	return pg_atomic_compare_exchange_u64_impl(ptr, expected, newval);
}

static inline uint64
pg_atomic_fetch_add_u64(volatile pg_atomic_uint64 *ptr, int64 add_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_fetch_add_u64_impl(ptr, add_);
}

static inline uint64
pg_atomic_fetch_sub_u64(volatile pg_atomic_uint64 *ptr, int64 sub_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	Assert(sub_ != PG_INT64_MIN);
	return pg_atomic_fetch_sub_u64_impl(ptr, sub_);
}

static inline uint64
pg_atomic_fetch_and_u64(volatile pg_atomic_uint64 *ptr, uint64 and_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_fetch_and_u64_impl(ptr, and_);
}

static inline uint64
pg_atomic_fetch_or_u64(volatile pg_atomic_uint64 *ptr, uint64 or_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_fetch_or_u64_impl(ptr, or_);
}

static inline uint64
pg_atomic_add_fetch_u64(volatile pg_atomic_uint64 *ptr, int64 add_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	return pg_atomic_add_fetch_u64_impl(ptr, add_);
}

static inline uint64
pg_atomic_sub_fetch_u64(volatile pg_atomic_uint64 *ptr, int64 sub_)
{
#ifndef PG_HAVE_ATOMIC_U64_SIMULATION
	AssertPointerAlignment(ptr, 8);
#endif
	Assert(sub_ != PG_INT64_MIN);
	return pg_atomic_sub_fetch_u64_impl(ptr, sub_);
}

#undef INSIDE_ATOMICS_H

#endif							/* ATOMICS_H */
