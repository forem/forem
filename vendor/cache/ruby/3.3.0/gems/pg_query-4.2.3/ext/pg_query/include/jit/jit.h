/*-------------------------------------------------------------------------
 * jit.h
 *	  Provider independent JIT infrastructure.
 *
 * Copyright (c) 2016-2022, PostgreSQL Global Development Group
 *
 * src/include/jit/jit.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef JIT_H
#define JIT_H

#include "executor/instrument.h"
#include "utils/resowner.h"


/* Flags determining what kind of JIT operations to perform */
#define PGJIT_NONE     0
#define PGJIT_PERFORM  (1 << 0)
#define PGJIT_OPT3     (1 << 1)
#define PGJIT_INLINE   (1 << 2)
#define PGJIT_EXPR	   (1 << 3)
#define PGJIT_DEFORM   (1 << 4)


typedef struct JitInstrumentation
{
	/* number of emitted functions */
	size_t		created_functions;

	/* accumulated time to generate code */
	instr_time	generation_counter;

	/* accumulated time for inlining */
	instr_time	inlining_counter;

	/* accumulated time for optimization */
	instr_time	optimization_counter;

	/* accumulated time for code emission */
	instr_time	emission_counter;
} JitInstrumentation;

/*
 * DSM structure for accumulating jit instrumentation of all workers.
 */
typedef struct SharedJitInstrumentation
{
	int			num_workers;
	JitInstrumentation jit_instr[FLEXIBLE_ARRAY_MEMBER];
} SharedJitInstrumentation;

typedef struct JitContext
{
	/* see PGJIT_* above */
	int			flags;

	ResourceOwner resowner;

	JitInstrumentation instr;
} JitContext;

typedef struct JitProviderCallbacks JitProviderCallbacks;

extern void _PG_jit_provider_init(JitProviderCallbacks *cb);
typedef void (*JitProviderInit) (JitProviderCallbacks *cb);
typedef void (*JitProviderResetAfterErrorCB) (void);
typedef void (*JitProviderReleaseContextCB) (JitContext *context);
struct ExprState;
typedef bool (*JitProviderCompileExprCB) (struct ExprState *state);

struct JitProviderCallbacks
{
	JitProviderResetAfterErrorCB reset_after_error;
	JitProviderReleaseContextCB release_context;
	JitProviderCompileExprCB compile_expr;
};


/* GUCs */
extern PGDLLIMPORT bool jit_enabled;
extern PGDLLIMPORT char *jit_provider;
extern PGDLLIMPORT bool jit_debugging_support;
extern PGDLLIMPORT bool jit_dump_bitcode;
extern PGDLLIMPORT bool jit_expressions;
extern PGDLLIMPORT bool jit_profiling_support;
extern PGDLLIMPORT bool jit_tuple_deforming;
extern PGDLLIMPORT double jit_above_cost;
extern PGDLLIMPORT double jit_inline_above_cost;
extern PGDLLIMPORT double jit_optimize_above_cost;


extern void jit_reset_after_error(void);
extern void jit_release_context(JitContext *context);

/*
 * Functions for attempting to JIT code. Callers must accept that these might
 * not be able to perform JIT (i.e. return false).
 */
extern bool jit_compile_expr(struct ExprState *state);
extern void InstrJitAgg(JitInstrumentation *dst, JitInstrumentation *add);


#endif							/* JIT_H */
