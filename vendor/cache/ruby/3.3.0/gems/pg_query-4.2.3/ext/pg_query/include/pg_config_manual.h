/*------------------------------------------------------------------------
 * PostgreSQL manual configuration settings
 *
 * This file contains various configuration symbols and limits.  In
 * all cases, changing them is only useful in very rare situations or
 * for developers.  If you edit any of these, be sure to do a *full*
 * rebuild (and an initdb if noted).
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/pg_config_manual.h
 *------------------------------------------------------------------------
 */

/*
 * This is the default value for wal_segment_size to be used when initdb is run
 * without the --wal-segsize option.  It must be a valid segment size.
 */
#define DEFAULT_XLOG_SEG_SIZE	(16*1024*1024)

/*
 * Maximum length for identifiers (e.g. table names, column names,
 * function names).  Names actually are limited to one fewer byte than this,
 * because the length must include a trailing zero byte.
 *
 * Changing this requires an initdb.
 */
#define NAMEDATALEN 64

/*
 * Maximum number of arguments to a function.
 *
 * The minimum value is 8 (GIN indexes use 8-argument support functions).
 * The maximum possible value is around 600 (limited by index tuple size in
 * pg_proc's index; BLCKSZ larger than 8K would allow more).  Values larger
 * than needed will waste memory and processing time, but do not directly
 * cost disk space.
 *
 * Changing this does not require an initdb, but it does require a full
 * backend recompile (including any user-defined C functions).
 */
#define FUNC_MAX_ARGS		100

/*
 * When creating a product derived from PostgreSQL with changes that cause
 * incompatibilities for loadable modules, it is recommended to change this
 * string so that dfmgr.c can refuse to load incompatible modules with a clean
 * error message.  Typical examples that cause incompatibilities are any
 * changes to node tags or node structures.  (Note that dfmgr.c already
 * detects common sources of incompatibilities due to major version
 * differences and due to some changed compile-time constants.  This setting
 * is for catching anything that cannot be detected in a straightforward way.)
 *
 * There is no prescribed format for the string.  The suggestion is to include
 * product or company name, and optionally any internally-relevant ABI
 * version.  Example: "ACME Postgres/1.2".  Note that the string will appear
 * in a user-facing error message if an ABI mismatch is detected.
 */
#define FMGR_ABI_EXTRA		"PostgreSQL"

/*
 * Maximum number of columns in an index.  There is little point in making
 * this anything but a multiple of 32, because the main cost is associated
 * with index tuple header size (see access/itup.h).
 *
 * Changing this requires an initdb.
 */
#define INDEX_MAX_KEYS		32

/*
 * Maximum number of columns in a partition key
 */
#define PARTITION_MAX_KEYS	32

/*
 * Decide whether built-in 8-byte types, including float8, int8, and
 * timestamp, are passed by value.  This is on by default if sizeof(Datum) >=
 * 8 (that is, on 64-bit platforms).  If sizeof(Datum) < 8 (32-bit platforms),
 * this must be off.  We keep this here as an option so that it is easy to
 * test the pass-by-reference code paths on 64-bit platforms.
 *
 * Changing this requires an initdb.
 */
#if SIZEOF_VOID_P >= 8
#define USE_FLOAT8_BYVAL 1
#endif

/*
 * When we don't have native spinlocks, we use semaphores to simulate them.
 * Decreasing this value reduces consumption of OS resources; increasing it
 * may improve performance, but supplying a real spinlock implementation is
 * probably far better.
 */
#define NUM_SPINLOCK_SEMAPHORES		128

/*
 * When we have neither spinlocks nor atomic operations support we're
 * implementing atomic operations on top of spinlock on top of semaphores. To
 * be safe against atomic operations while holding a spinlock separate
 * semaphores have to be used.
 */
#define NUM_ATOMICS_SEMAPHORES		64

/*
 * MAXPGPATH: standard size of a pathname buffer in PostgreSQL (hence,
 * maximum usable pathname length is one less).
 *
 * We'd use a standard system header symbol for this, if there weren't
 * so many to choose from: MAXPATHLEN, MAX_PATH, PATH_MAX are all
 * defined by different "standards", and often have different values
 * on the same platform!  So we just punt and use a reasonably
 * generous setting here.
 */
#define MAXPGPATH		1024

/*
 * PG_SOMAXCONN: maximum accept-queue length limit passed to
 * listen(2).  You'd think we should use SOMAXCONN from
 * <sys/socket.h>, but on many systems that symbol is much smaller
 * than the kernel's actual limit.  In any case, this symbol need be
 * twiddled only if you have a kernel that refuses large limit values,
 * rather than silently reducing the value to what it can handle
 * (which is what most if not all Unixen do).
 */
#define PG_SOMAXCONN	10000

/*
 * You can try changing this if you have a machine with bytes of
 * another size, but no guarantee...
 */
#define BITS_PER_BYTE		8

/*
 * Preferred alignment for disk I/O buffers.  On some CPUs, copies between
 * user space and kernel space are significantly faster if the user buffer
 * is aligned on a larger-than-MAXALIGN boundary.  Ideally this should be
 * a platform-dependent value, but for now we just hard-wire it.
 */
#define ALIGNOF_BUFFER	32

/*
 * If EXEC_BACKEND is defined, the postmaster uses an alternative method for
 * starting subprocesses: Instead of simply using fork(), as is standard on
 * Unix platforms, it uses fork()+exec() or something equivalent on Windows,
 * as well as lots of extra code to bring the required global state to those
 * new processes.  This must be enabled on Windows (because there is no
 * fork()).  On other platforms, it's only useful for verifying those
 * otherwise Windows-specific code paths.
 */
#if defined(WIN32) && !defined(__CYGWIN__)
#define EXEC_BACKEND
#endif

/*
 * Define this if your operating system supports link()
 */
#if !defined(WIN32) && !defined(__CYGWIN__)
#define HAVE_WORKING_LINK 1
#endif

/*
 * USE_POSIX_FADVISE controls whether Postgres will attempt to use the
 * posix_fadvise() kernel call.  Usually the automatic configure tests are
 * sufficient, but some older Linux distributions had broken versions of
 * posix_fadvise().  If necessary you can remove the #define here.
 */
#if HAVE_DECL_POSIX_FADVISE && defined(HAVE_POSIX_FADVISE)
#define USE_POSIX_FADVISE
#endif

/*
 * USE_PREFETCH code should be compiled only if we have a way to implement
 * prefetching.  (This is decoupled from USE_POSIX_FADVISE because there
 * might in future be support for alternative low-level prefetch APIs.
 * If you change this, you probably need to adjust the error message in
 * check_effective_io_concurrency.)
 */
#ifdef USE_POSIX_FADVISE
#define USE_PREFETCH
#endif

/*
 * Default and maximum values for backend_flush_after, bgwriter_flush_after
 * and checkpoint_flush_after; measured in blocks.  Currently, these are
 * enabled by default if sync_file_range() exists, ie, only on Linux.  Perhaps
 * we could also enable by default if we have mmap and msync(MS_ASYNC)?
 */
#ifdef HAVE_SYNC_FILE_RANGE
#define DEFAULT_BACKEND_FLUSH_AFTER 0	/* never enabled by default */
#define DEFAULT_BGWRITER_FLUSH_AFTER 64
#define DEFAULT_CHECKPOINT_FLUSH_AFTER 32
#else
#define DEFAULT_BACKEND_FLUSH_AFTER 0
#define DEFAULT_BGWRITER_FLUSH_AFTER 0
#define DEFAULT_CHECKPOINT_FLUSH_AFTER 0
#endif
/* upper limit for all three variables */
#define WRITEBACK_MAX_PENDING_FLUSHES 256

/*
 * USE_SSL code should be compiled only when compiling with an SSL
 * implementation.
 */
#ifdef USE_OPENSSL
#define USE_SSL
#endif

/*
 * This is the default directory in which AF_UNIX socket files are
 * placed.  Caution: changing this risks breaking your existing client
 * applications, which are likely to continue to look in the old
 * directory.  But if you just hate the idea of sockets in /tmp,
 * here's where to twiddle it.  You can also override this at runtime
 * with the postmaster's -k switch.
 *
 * If set to an empty string, then AF_UNIX sockets are not used by default: A
 * server will not create an AF_UNIX socket unless the run-time configuration
 * is changed, a client will connect via TCP/IP by default and will only use
 * an AF_UNIX socket if one is explicitly specified.
 *
 * This is done by default on Windows because there is no good standard
 * location for AF_UNIX sockets and many installations on Windows don't
 * support them yet.
 */
#ifndef WIN32
#define DEFAULT_PGSOCKET_DIR  "/tmp"
#else
#define DEFAULT_PGSOCKET_DIR ""
#endif

/*
 * This is the default event source for Windows event log.
 */
#define DEFAULT_EVENT_SOURCE  "PostgreSQL"

/*
 * On PPC machines, decide whether to use the mutex hint bit in LWARX
 * instructions.  Setting the hint bit will slightly improve spinlock
 * performance on POWER6 and later machines, but does nothing before that,
 * and will result in illegal-instruction failures on some pre-POWER4
 * machines.  By default we use the hint bit when building for 64-bit PPC,
 * which should be safe in nearly all cases.  You might want to override
 * this if you are building 32-bit code for a known-recent PPC machine.
 */
#ifdef HAVE_PPC_LWARX_MUTEX_HINT	/* must have assembler support in any case */
#if defined(__ppc64__) || defined(__powerpc64__)
#define USE_PPC_LWARX_MUTEX_HINT
#endif
#endif

/*
 * On PPC machines, decide whether to use LWSYNC instructions in place of
 * ISYNC and SYNC.  This provides slightly better performance, but will
 * result in illegal-instruction failures on some pre-POWER4 machines.
 * By default we use LWSYNC when building for 64-bit PPC, which should be
 * safe in nearly all cases.
 */
#if defined(__ppc64__) || defined(__powerpc64__)
#define USE_PPC_LWSYNC
#endif

/*
 * Assumed cache line size. This doesn't affect correctness, but can be used
 * for low-level optimizations. Currently, this is used to pad some data
 * structures in xlog.c, to ensure that highly-contended fields are on
 * different cache lines. Too small a value can hurt performance due to false
 * sharing, while the only downside of too large a value is a few bytes of
 * wasted memory. The default is 128, which should be large enough for all
 * supported platforms.
 */
#define PG_CACHE_LINE_SIZE		128

/*
 *------------------------------------------------------------------------
 * The following symbols are for enabling debugging code, not for
 * controlling user-visible features or resource limits.
 *------------------------------------------------------------------------
 */

/*
 * Include Valgrind "client requests", mostly in the memory allocator, so
 * Valgrind understands PostgreSQL memory contexts.  This permits detecting
 * memory errors that Valgrind would not detect on a vanilla build.  It also
 * enables detection of buffer accesses that take place without holding a
 * buffer pin (or without holding a buffer lock in the case of index access
 * methods that superimpose their own custom client requests on top of the
 * generic bufmgr.c requests).
 *
 * "make installcheck" is significantly slower under Valgrind.  The client
 * requests fall in hot code paths, so USE_VALGRIND slows execution by a few
 * percentage points even when not run under Valgrind.
 *
 * Do not try to test the server under Valgrind without having built the
 * server with USE_VALGRIND; else you will get false positives from sinval
 * messaging (see comments in AddCatcacheInvalidationMessage).  It's also
 * important to use the suppression file src/tools/valgrind.supp to
 * exclude other known false positives.
 *
 * You should normally use MEMORY_CONTEXT_CHECKING with USE_VALGRIND;
 * instrumentation of repalloc() is inferior without it.
 */
/* #define USE_VALGRIND */

/*
 * Define this to cause pfree()'d memory to be cleared immediately, to
 * facilitate catching bugs that refer to already-freed values.
 * Right now, this gets defined automatically if --enable-cassert.
 */
#ifdef USE_ASSERT_CHECKING
#define CLOBBER_FREED_MEMORY
#endif

/*
 * Define this to check memory allocation errors (scribbling on more
 * bytes than were allocated).  Right now, this gets defined
 * automatically if --enable-cassert or USE_VALGRIND.
 */
#if defined(USE_ASSERT_CHECKING) || defined(USE_VALGRIND)
#define MEMORY_CONTEXT_CHECKING
#endif

/*
 * Define this to cause palloc()'d memory to be filled with random data, to
 * facilitate catching code that depends on the contents of uninitialized
 * memory.  Caution: this is horrendously expensive.
 */
/* #define RANDOMIZE_ALLOCATED_MEMORY */

/*
 * For cache-invalidation debugging, define DISCARD_CACHES_ENABLED to enable
 * use of the debug_discard_caches GUC to aggressively flush syscache/relcache
 * entries whenever it's possible to deliver invalidations.  See
 * AcceptInvalidationMessages() in src/backend/utils/cache/inval.c for
 * details.
 *
 * USE_ASSERT_CHECKING builds default to enabling this.  It's possible to use
 * DISCARD_CACHES_ENABLED without a cassert build and the implied
 * CLOBBER_FREED_MEMORY and MEMORY_CONTEXT_CHECKING options, but it's unlikely
 * to be as effective at identifying problems.
 */
/* #define DISCARD_CACHES_ENABLED */

#if defined(USE_ASSERT_CHECKING) && !defined(DISCARD_CACHES_ENABLED)
#define DISCARD_CACHES_ENABLED
#endif

/*
 * Backwards compatibility for the older compile-time-only clobber-cache
 * macros.
 */
#if !defined(DISCARD_CACHES_ENABLED) && (defined(CLOBBER_CACHE_ALWAYS) || defined(CLOBBER_CACHE_RECURSIVELY))
#define DISCARD_CACHES_ENABLED
#endif

/*
 * Recover memory used for relcache entries when invalidated.  See
 * RelationBuildDescr() in src/backend/utils/cache/relcache.c.
 *
 * This is active automatically for clobber-cache builds when clobbering is
 * active, but can be overridden here by explicitly defining
 * RECOVER_RELATION_BUILD_MEMORY.  Define to 1 to always free relation cache
 * memory even when clobber is off, or to 0 to never free relation cache
 * memory even when clobbering is on.
 */
 /* #define RECOVER_RELATION_BUILD_MEMORY 0 */	/* Force disable */
 /* #define RECOVER_RELATION_BUILD_MEMORY 1 */	/* Force enable */

/*
 * Define this to force all parse and plan trees to be passed through
 * copyObject(), to facilitate catching errors and omissions in
 * copyObject().
 */
/* #define COPY_PARSE_PLAN_TREES */

/*
 * Define this to force all parse and plan trees to be passed through
 * outfuncs.c/readfuncs.c, to facilitate catching errors and omissions in
 * those modules.
 */
/* #define WRITE_READ_PARSE_PLAN_TREES */

/*
 * Define this to force all raw parse trees for DML statements to be scanned
 * by raw_expression_tree_walker(), to facilitate catching errors and
 * omissions in that function.
 */
/* #define RAW_EXPRESSION_COVERAGE_TEST */

/*
 * Enable debugging print statements for lock-related operations.
 */
/* #define LOCK_DEBUG */

/*
 * Enable debugging print statements for WAL-related operations; see
 * also the wal_debug GUC var.
 */
/* #define WAL_DEBUG */

/*
 * Enable tracing of resource consumption during sort operations;
 * see also the trace_sort GUC var.  For 8.1 this is enabled by default.
 */
#define TRACE_SORT 1

/*
 * Enable tracing of syncscan operations (see also the trace_syncscan GUC var).
 */
/* #define TRACE_SYNCSCAN */
