/*--------------------------------------------------------------------
 * Symbols referenced in this file:
 * - debug_query_string
 * - whereToSendOutput
 * - ProcessInterrupts
 * - check_stack_depth
 * - stack_is_too_deep
 * - stack_base_ptr
 * - max_stack_depth_bytes
 * - max_stack_depth
 *--------------------------------------------------------------------
 */

/*-------------------------------------------------------------------------
 *
 * postgres.c
 *	  POSTGRES C Backend Interface
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/tcop/postgres.c
 *
 * NOTES
 *	  this is the "main" module of the postgres backend and
 *	  hence the main module of the "traffic cop".
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <unistd.h>
#include <sys/socket.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#include <sys/time.h>
#include <sys/resource.h>
#endif

#ifndef HAVE_GETRUSAGE
#include "rusagestub.h"
#endif

#include "access/parallel.h"
#include "access/printtup.h"
#include "access/xact.h"
#include "catalog/pg_type.h"
#include "commands/async.h"
#include "commands/prepare.h"
#include "common/pg_prng.h"
#include "jit/jit.h"
#include "libpq/libpq.h"
#include "libpq/pqformat.h"
#include "libpq/pqsignal.h"
#include "mb/pg_wchar.h"
#include "mb/stringinfo_mb.h"
#include "miscadmin.h"
#include "nodes/print.h"
#include "optimizer/optimizer.h"
#include "parser/analyze.h"
#include "parser/parser.h"
#include "pg_getopt.h"
#include "pg_trace.h"
#include "pgstat.h"
#include "postmaster/autovacuum.h"
#include "postmaster/interrupt.h"
#include "postmaster/postmaster.h"
#include "replication/logicallauncher.h"
#include "replication/logicalworker.h"
#include "replication/slot.h"
#include "replication/walsender.h"
#include "rewrite/rewriteHandler.h"
#include "storage/bufmgr.h"
#include "storage/ipc.h"
#include "storage/pmsignal.h"
#include "storage/proc.h"
#include "storage/procsignal.h"
#include "storage/sinval.h"
#include "tcop/fastpath.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "tcop/utility.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/ps_status.h"
#include "utils/snapmgr.h"
#include "utils/timeout.h"
#include "utils/timestamp.h"

/* ----------------
 *		global variables
 * ----------------
 */
__thread const char *debug_query_string;
 /* client-supplied query string */

/* Note: whereToSendOutput is initialized for the bootstrap/standalone case */
__thread CommandDest whereToSendOutput = DestDebug;


/* flag for logging end of session */




/* GUC variable for maximum stack depth (measured in kilobytes) */
__thread int			max_stack_depth = 100;


/* wait N seconds to allow attach from a debugger */


/* Time between checks that the client is still connected. */


/* ----------------
 *		private typedefs etc
 * ----------------
 */

/* type of argument for bind_param_error_callback */
typedef struct BindParamCbData
{
	const char *portalName;
	int			paramno;		/* zero-based param number, or -1 initially */
	const char *paramval;		/* textual input string, if available */
} BindParamCbData;

/* ----------------
 *		private variables
 * ----------------
 */

/* max_stack_depth converted to bytes for speed of checking */
static __thread long max_stack_depth_bytes = 100 * 1024L;


/*
 * Stack base pointer -- initialized by PostmasterMain and inherited by
 * subprocesses (but see also InitPostmasterChild).
 */
static __thread char *stack_base_ptr = NULL;


/*
 * On IA64 we also have to remember the register stack base.
 */
#if defined(__ia64__) || defined(__ia64)
static char *register_stack_base_ptr = NULL;
#endif

/*
 * Flag to keep track of whether we have started a transaction.
 * For extended query protocol this has to be remembered across messages.
 */


/*
 * Flag to indicate that we are doing the outer loop's read-from-client,
 * as opposed to any random read from client that might happen within
 * commands like COPY FROM STDIN.
 */


/*
 * Flags to implement skip-till-Sync-after-error behavior for messages of
 * the extended query protocol.
 */



/*
 * If an unnamed prepared statement exists, it's stored here.
 * We keep it separate from the hashtable kept by commands/prepare.c
 * in order to reduce overhead for short-lived queries.
 */


/* assorted command-line switches */
	/* -D switch */
	/* -E switch */
	/* -j switch */

/* whether or not, and why, we were canceled by conflict with recovery */




/* reused buffer to pass to SendRowDescriptionMessage() */



/* ----------------------------------------------------------------
 *		decls for routines only used in this file
 * ----------------------------------------------------------------
 */
static int	InteractiveBackend(StringInfo inBuf);
static int	interactive_getc(void);
static int	SocketBackend(StringInfo inBuf);
static int	ReadCommand(StringInfo inBuf);
static void forbidden_in_wal_sender(char firstchar);
static bool check_log_statement(List *stmt_list);
static int	errdetail_execute(List *raw_parsetree_list);
static int	errdetail_params(ParamListInfo params);
static int	errdetail_abort(void);
static int	errdetail_recovery_conflict(void);
static void bind_param_error_callback(void *arg);
static void start_xact_command(void);
static void finish_xact_command(void);
static bool IsTransactionExitStmt(Node *parsetree);
static bool IsTransactionExitStmtList(List *pstmts);
static bool IsTransactionStmtList(List *pstmts);
static void drop_unnamed_stmt(void);
static void log_disconnections(int code, Datum arg);
static void enable_statement_timeout(void);
static void disable_statement_timeout(void);


/* ----------------------------------------------------------------
 *		routines to obtain user input
 * ----------------------------------------------------------------
 */

/* ----------------
 *	InteractiveBackend() is called for user interactive connections
 *
 *	the string entered by the user is placed in its parameter inBuf,
 *	and we act like a Q message was received.
 *
 *	EOF is returned if end-of-file input is seen; time to shut down.
 * ----------------
 */



/*
 * interactive_getc -- collect one character from stdin
 *
 * Even though we are not reading from a "client" process, we still want to
 * respond to signals, particularly SIGTERM/SIGQUIT.
 */


/* ----------------
 *	SocketBackend()		Is called for frontend-backend connections
 *
 *	Returns the message type code, and loads message body data into inBuf.
 *
 *	EOF is returned if the connection is lost.
 * ----------------
 */


/* ----------------
 *		ReadCommand reads a command from either the frontend or
 *		standard input, places it in inBuf, and returns the
 *		message type code (first byte of the message).
 *		EOF is returned if end of file.
 * ----------------
 */


/*
 * ProcessClientReadInterrupt() - Process interrupts specific to client reads
 *
 * This is called just before and after low-level reads.
 * 'blocked' is true if no data was available to read and we plan to retry,
 * false if about to read or done reading.
 *
 * Must preserve errno!
 */


/*
 * ProcessClientWriteInterrupt() - Process interrupts specific to client writes
 *
 * This is called just before and after low-level writes.
 * 'blocked' is true if no data could be written and we plan to retry,
 * false if about to write or done writing.
 *
 * Must preserve errno!
 */


/*
 * Do raw parsing (only).
 *
 * A list of parsetrees (RawStmt nodes) is returned, since there might be
 * multiple commands in the given string.
 *
 * NOTE: for interactive queries, it is important to keep this routine
 * separate from the analysis & rewrite stages.  Analysis and rewriting
 * cannot be done in an aborted transaction, since they require access to
 * database tables.  So, we rely on the raw parser to determine whether
 * we've seen a COMMIT or ABORT command; when we are in abort state, other
 * commands are not processed any further than the raw parse stage.
 */
#ifdef COPY_PARSE_PLAN_TREES
#endif

/*
 * Given a raw parsetree (gram.y output), and optionally information about
 * types of parameter symbols ($n), perform parse analysis and rule rewriting.
 *
 * A list of Query nodes is returned, since either the analyzer or the
 * rewriter might expand one query to several.
 *
 * NOTE: for reasons mentioned above, this must be separate from raw parsing.
 */


/*
 * Do parse analysis and rewriting.  This is the same as
 * pg_analyze_and_rewrite_fixedparams except that it's okay to deduce
 * information about $n symbol datatypes from context.
 */


/*
 * Do parse analysis and rewriting.  This is the same as
 * pg_analyze_and_rewrite_fixedparams except that, instead of a fixed list of
 * parameter datatypes, a parser callback is supplied that can do
 * external-parameter resolution and possibly other things.
 */


/*
 * Perform rewriting of a query produced by parse analysis.
 *
 * Note: query must just have come from the parser, because we do not do
 * AcquireRewriteLocks() on it.
 */
#ifdef COPY_PARSE_PLAN_TREES
#endif
#ifdef WRITE_READ_PARSE_PLAN_TREES
#endif


/*
 * Generate a plan for a single already-rewritten query.
 * This is a thin wrapper around planner() and takes the same parameters.
 */
#ifdef COPY_PARSE_PLAN_TREES
#ifdef NOT_USED
#endif
#endif
#ifdef WRITE_READ_PARSE_PLAN_TREES
#ifdef NOT_USED
#endif
#endif

/*
 * Generate plans for a list of already-rewritten queries.
 *
 * For normal optimizable statements, invoke the planner.  For utility
 * statements, just make a wrapper PlannedStmt node.
 *
 * The result is a list of PlannedStmt nodes.
 */



/*
 * exec_simple_query
 *
 * Execute a "simple Query" protocol message.
 */


/*
 * exec_parse_message
 *
 * Execute a "Parse" protocol message.
 */


/*
 * exec_bind_message
 *
 * Process a "Bind" message to create a portal from a prepared statement
 */


/*
 * exec_execute_message
 *
 * Process an "Execute" message for a portal
 */


/*
 * check_log_statement
 *		Determine whether command should be logged because of log_statement
 *
 * stmt_list can be either raw grammar output or a list of planned
 * statements
 */


/*
 * check_log_duration
 *		Determine whether current command's duration should be logged
 *		We also check if this statement in this transaction must be logged
 *		(regardless of its duration).
 *
 * Returns:
 *		0 if no logging is needed
 *		1 if just the duration should be logged
 *		2 if duration and query details should be logged
 *
 * If logging is needed, the duration in msec is formatted into msec_str[],
 * which must be a 32-byte buffer.
 *
 * was_logged should be true if caller already logged query details (this
 * essentially prevents 2 from being returned).
 */


/*
 * errdetail_execute
 *
 * Add an errdetail() line showing the query referenced by an EXECUTE, if any.
 * The argument is the raw parsetree list.
 */


/*
 * errdetail_params
 *
 * Add an errdetail() line showing bind-parameter data, if available.
 * Note that this is only used for statement logging, so it is controlled
 * by log_parameter_max_length not log_parameter_max_length_on_error.
 */


/*
 * errdetail_abort
 *
 * Add an errdetail() line showing abort reason, if any.
 */


/*
 * errdetail_recovery_conflict
 *
 * Add an errdetail() line showing conflict source.
 */


/*
 * bind_param_error_callback
 *
 * Error context callback used while parsing parameters in a Bind message
 */


/*
 * exec_describe_statement_message
 *
 * Process a "Describe" message for a prepared statement
 */


/*
 * exec_describe_portal_message
 *
 * Process a "Describe" message for a portal
 */



/*
 * Convenience routines for starting/committing a single command.
 */


#ifdef MEMORY_CONTEXT_CHECKING
#endif
#ifdef SHOW_MEMORY_STATS
#endif


/*
 * Convenience routines for checking whether a statement is one of the
 * ones that we allow in transaction-aborted state.
 */

/* Test a bare parsetree */


/* Test a list that contains PlannedStmt nodes */


/* Test a list that contains PlannedStmt nodes */


/* Release any existing unnamed prepared statement */



/* --------------------------------
 *		signal handler routines used in PostgresMain()
 * --------------------------------
 */

/*
 * quickdie() occurs when signaled SIGQUIT by the postmaster.
 *
 * Either some backend has bought the farm, or we've been told to shut down
 * "immediately"; so we need to stop what we're doing and exit.
 */


/*
 * Shutdown signal from postmaster: abort transaction and exit
 * at soonest convenient time
 */


/*
 * Query-cancel signal from postmaster: abort current transaction
 * at soonest convenient time
 */


/* signal handler for floating point exception */


/*
 * RecoveryConflictInterrupt: out-of-line portion of recovery conflict
 * handling following receipt of SIGUSR1. Designed to be similar to die()
 * and StatementCancelHandler(). Called only by a normal user backend
 * that begins a transaction during recovery.
 */


/*
 * ProcessInterrupts: out-of-line portion of CHECK_FOR_INTERRUPTS() macro
 *
 * If an interrupt condition is pending, and it's safe to service it,
 * then clear the flag and accept the interrupt.  Called only when
 * InterruptPending is true.
 *
 * Note: if INTERRUPTS_CAN_BE_PROCESSED() is true, then ProcessInterrupts
 * is guaranteed to clear the InterruptPending flag before returning.
 * (This is not the same as guaranteeing that it's still clear when we
 * return; another interrupt could have arrived.  But we promise that
 * any pre-existing one will have been serviced.)
 */
void ProcessInterrupts(void) {}



/*
 * IA64-specific code to fetch the AR.BSP register for stack depth checks.
 *
 * We currently support gcc, icc, and HP-UX's native compiler here.
 *
 * Note: while icc accepts gcc asm blocks on x86[_64], this is not true on
 * ia64 (at least not in icc versions before 12.x).  So we have to carry a
 * separate implementation for it.
 */
#if defined(__ia64__) || defined(__ia64)

#if defined(__hpux) && !defined(__GNUC__) && !defined(__INTEL_COMPILER)
/* Assume it's HP-UX native compiler */
#include <ia64/sys/inline.h>
#define ia64_get_bsp() ((char *) (_Asm_mov_from_ar(_AREG_BSP, _NO_FENCE)))
#elif defined(__INTEL_COMPILER)
/* icc */
#include <asm/ia64regs.h>
#define ia64_get_bsp() ((char *) __getReg(_IA64_REG_AR_BSP))
#else
/* gcc */
static __inline__ char *
ia64_get_bsp(void)
{
	char	   *ret;

	/* the ;; is a "stop", seems to be required before fetching BSP */
	__asm__ __volatile__(
						 ";;\n"
						 "	mov	%0=ar.bsp	\n"
:						 "=r"(ret));

	return ret;
}
#endif
#endif							/* IA64 */


/*
 * set_stack_base: set up reference point for stack depth checking
 *
 * Returns the old reference point, if any.
 */
#ifndef HAVE__BUILTIN_FRAME_ADDRESS
#endif
#if defined(__ia64__) || defined(__ia64)
#else
#endif
#ifdef HAVE__BUILTIN_FRAME_ADDRESS
#else
#endif
#if defined(__ia64__) || defined(__ia64)
#endif

/*
 * restore_stack_base: restore reference point for stack depth checking
 *
 * This can be used after set_stack_base() to restore the old value. This
 * is currently only used in PL/Java. When PL/Java calls a backend function
 * from different thread, the thread's stack is at a different location than
 * the main thread's stack, so it sets the base pointer before the call, and
 * restores it afterwards.
 */
#if defined(__ia64__) || defined(__ia64)
#else
#endif

/*
 * check_stack_depth/stack_is_too_deep: check for excessively deep recursion
 *
 * This should be called someplace in any recursive routine that might possibly
 * recurse deep enough to overflow the stack.  Most Unixen treat stack
 * overflow as an unrecoverable SIGSEGV, so we want to error out ourselves
 * before hitting the hardware limit.
 *
 * check_stack_depth() just throws an error summarily.  stack_is_too_deep()
 * can be used by code that wants to handle the error condition itself.
 */
void
check_stack_depth(void)
{
	if (stack_is_too_deep())
	{
		ereport(ERROR,
				(errcode(ERRCODE_STATEMENT_TOO_COMPLEX),
				 errmsg("stack depth limit exceeded"),
				 errhint("Increase the configuration parameter \"max_stack_depth\" (currently %dkB), "
						 "after ensuring the platform's stack depth limit is adequate.",
						 max_stack_depth)));
	}
}

bool
stack_is_too_deep(void)
{
	char		stack_top_loc;
	long		stack_depth;

	/*
	 * Compute distance from reference point to my local variables
	 */
	stack_depth = (long) (stack_base_ptr - &stack_top_loc);

	/*
	 * Take abs value, since stacks grow up on some machines, down on others
	 */
	if (stack_depth < 0)
		stack_depth = -stack_depth;

	/*
	 * Trouble?
	 *
	 * The test on stack_base_ptr prevents us from erroring out if called
	 * during process setup or in a non-backend process.  Logically it should
	 * be done first, but putting it here avoids wasting cycles during normal
	 * cases.
	 */
	if (stack_depth > max_stack_depth_bytes &&
		stack_base_ptr != NULL)
		return true;

	/*
	 * On IA64 there is a separate "register" stack that requires its own
	 * independent check.  For this, we have to measure the change in the
	 * "BSP" pointer from PostgresMain to here.  Logic is just as above,
	 * except that we know IA64's register stack grows up.
	 *
	 * Note we assume that the same max_stack_depth applies to both stacks.
	 */
#if defined(__ia64__) || defined(__ia64)
	stack_depth = (long) (ia64_get_bsp() - register_stack_base_ptr);

	if (stack_depth > max_stack_depth_bytes &&
		register_stack_base_ptr != NULL)
		return true;
#endif							/* IA64 */

	return false;
}

/* GUC check hook for max_stack_depth */


/* GUC assign hook for max_stack_depth */



/*
 * set_debug_options --- apply "-d N" command line option
 *
 * -d is not quite the same as setting log_min_messages because it enables
 * other output options.
 */









/* ----------------------------------------------------------------
 * process_postgres_switches
 *	   Parse command line arguments for backends
 *
 * This is called twice, once for the "secure" options coming from the
 * postmaster or command line, and once for the "insecure" options coming
 * from the client's startup packet.  The latter have the same syntax but
 * may be restricted in what they can do.
 *
 * argv[0] is ignored in either case (it's assumed to be the program name).
 *
 * ctx is PGC_POSTMASTER for secure options, PGC_BACKEND for insecure options
 * coming from the client, or PGC_SU_BACKEND for insecure options coming from
 * a superuser client.
 *
 * If a database name is present in the command line arguments, it's
 * returned into *dbname (this is allowed only if *dbname is initially NULL).
 * ----------------------------------------------------------------
 */
#ifdef HAVE_INT_OPTERR
#endif
#ifdef HAVE_INT_OPTRESET
#endif


/*
 * PostgresSingleUserMain
 *     Entry point for single user mode. argc/argv are the command line
 *     arguments to be used.
 *
 * Performs single user specific setup then calls PostgresMain() to actually
 * process queries. Single user mode specific setup should go here, rather
 * than PostgresMain() or InitPostgres() when reasonably possible.
 */



/* ----------------------------------------------------------------
 * PostgresMain
 *	   postgres main loop -- all backends, interactive or otherwise loop here
 *
 * dbname is the name of the database to connect to, username is the
 * PostgreSQL user name to be used for the session.
 *
 * NB: Single user mode specific setup should go to PostgresSingleUserMain()
 * if reasonably possible.
 * ----------------------------------------------------------------
 */


/*
 * Throw an error if we're a WAL sender process.
 *
 * This is used to forbid anything else than simple query protocol messages
 * in a WAL sender process.  'firstchar' specifies what kind of a forbidden
 * message was received, and is used to construct the error message.
 */



/*
 * Obtain platform stack depth limit (in bytes)
 *
 * Return -1 if unknown
 */
#if defined(HAVE_GETRLIMIT) && defined(RLIMIT_STACK)
#else							/* no getrlimit */
#if defined(WIN32) || defined(__CYGWIN__)
#else							/* not windows ... give up */
#endif
#endif







#if defined(HAVE_GETRUSAGE)
#if defined(__darwin__)
#else
#endif
#endif							/* HAVE_GETRUSAGE */

/*
 * on_proc_exit handler to log end of session
 */


/*
 * Start statement timeout timer, if enabled.
 *
 * If there's already a timeout running, don't restart the timer.  That
 * enables compromises between accuracy of timeouts and cost of starting a
 * timeout.
 */


/*
 * Disable statement timeout, if active.
 */

