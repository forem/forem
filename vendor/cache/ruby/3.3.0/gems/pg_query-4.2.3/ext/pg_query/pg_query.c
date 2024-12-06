#include "pg_query.h"
#include "pg_query_internal.h"

#include <mb/pg_wchar.h>
#include <utils/memutils.h>
#include <utils/memdebug.h>

#include <pthread.h>
#include <signal.h>

const char* progname = "pg_query";

__thread sig_atomic_t pg_query_initialized = 0;

static pthread_key_t pg_query_thread_exit_key;
static void pg_query_thread_exit(void *key);

void pg_query_init(void)
{
	if (pg_query_initialized != 0) return;
	pg_query_initialized = 1;

	MemoryContextInit();
	SetDatabaseEncoding(PG_UTF8);

	pthread_key_create(&pg_query_thread_exit_key, pg_query_thread_exit);
	pthread_setspecific(pg_query_thread_exit_key, TopMemoryContext);
}

void pg_query_free_top_memory_context(MemoryContext context)
{
	AssertArg(MemoryContextIsValid(context));

	/*
	 * After this, no memory contexts are valid anymore, so ensure that
	 * the current context is the top-level context.
	 */
	Assert(TopMemoryContext == CurrentMemoryContext);

	MemoryContextDeleteChildren(context);

	/* Clean up the aset.c freelist, to leave no unused context behind */
	AllocSetDeleteFreeList(context);

	context->methods->delete_context(context);

	VALGRIND_DESTROY_MEMPOOL(context);

	/* Without this, Valgrind will complain */
	free(context);

	/* Reset pointers */
	TopMemoryContext = NULL;
	CurrentMemoryContext = NULL;
	ErrorContext = NULL;
}

static void pg_query_thread_exit(void *key)
{
	MemoryContext context = (MemoryContext) key;
	pg_query_free_top_memory_context(context);
}

void pg_query_exit(void)
{
	pg_query_free_top_memory_context(TopMemoryContext);
}

MemoryContext pg_query_enter_memory_context()
{
	MemoryContext ctx = NULL;

	pg_query_init();

	Assert(CurrentMemoryContext == TopMemoryContext);
	ctx = AllocSetContextCreate(TopMemoryContext,
								"pg_query",
								ALLOCSET_DEFAULT_SIZES);
	MemoryContextSwitchTo(ctx);

	return ctx;
}

void pg_query_exit_memory_context(MemoryContext ctx)
{
	// Return to previous PostgreSQL memory context
	MemoryContextSwitchTo(TopMemoryContext);

	MemoryContextDelete(ctx);
	ctx = NULL;
}

void pg_query_free_error(PgQueryError *error)
{
	free(error->message);
	free(error->funcname);
	free(error->filename);

	if (error->context) {
		free(error->context);
	}

	free(error);
}
