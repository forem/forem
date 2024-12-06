/*-------------------------------------------------------------------------
 *
 * spi.h
 *				Server Programming Interface public declarations
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/executor/spi.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef SPI_H
#define SPI_H

#include "commands/trigger.h"
#include "lib/ilist.h"
#include "parser/parser.h"
#include "utils/portal.h"


typedef struct SPITupleTable
{
	/* Public members */
	TupleDesc	tupdesc;		/* tuple descriptor */
	HeapTuple  *vals;			/* array of tuples */
	uint64		numvals;		/* number of valid tuples */

	/* Private members, not intended for external callers */
	uint64		alloced;		/* allocated length of vals array */
	MemoryContext tuptabcxt;	/* memory context of result table */
	slist_node	next;			/* link for internal bookkeeping */
	SubTransactionId subid;		/* subxact in which tuptable was created */
} SPITupleTable;

/* Optional arguments for SPI_prepare_extended */
typedef struct SPIPrepareOptions
{
	ParserSetupHook parserSetup;
	void	   *parserSetupArg;
	RawParseMode parseMode;
	int			cursorOptions;
} SPIPrepareOptions;

/* Optional arguments for SPI_execute[_plan]_extended */
typedef struct SPIExecuteOptions
{
	ParamListInfo params;
	bool		read_only;
	bool		allow_nonatomic;
	bool		must_return_tuples;
	uint64		tcount;
	DestReceiver *dest;
	ResourceOwner owner;
} SPIExecuteOptions;

/* Optional arguments for SPI_cursor_parse_open */
typedef struct SPIParseOpenOptions
{
	ParamListInfo params;
	int			cursorOptions;
	bool		read_only;
} SPIParseOpenOptions;

/* Plans are opaque structs for standard users of SPI */
typedef struct _SPI_plan *SPIPlanPtr;

#define SPI_ERROR_CONNECT		(-1)
#define SPI_ERROR_COPY			(-2)
#define SPI_ERROR_OPUNKNOWN		(-3)
#define SPI_ERROR_UNCONNECTED	(-4)
#define SPI_ERROR_CURSOR		(-5)	/* not used anymore */
#define SPI_ERROR_ARGUMENT		(-6)
#define SPI_ERROR_PARAM			(-7)
#define SPI_ERROR_TRANSACTION	(-8)
#define SPI_ERROR_NOATTRIBUTE	(-9)
#define SPI_ERROR_NOOUTFUNC		(-10)
#define SPI_ERROR_TYPUNKNOWN	(-11)
#define SPI_ERROR_REL_DUPLICATE (-12)
#define SPI_ERROR_REL_NOT_FOUND (-13)

#define SPI_OK_CONNECT			1
#define SPI_OK_FINISH			2
#define SPI_OK_FETCH			3
#define SPI_OK_UTILITY			4
#define SPI_OK_SELECT			5
#define SPI_OK_SELINTO			6
#define SPI_OK_INSERT			7
#define SPI_OK_DELETE			8
#define SPI_OK_UPDATE			9
#define SPI_OK_CURSOR			10
#define SPI_OK_INSERT_RETURNING 11
#define SPI_OK_DELETE_RETURNING 12
#define SPI_OK_UPDATE_RETURNING 13
#define SPI_OK_REWRITTEN		14
#define SPI_OK_REL_REGISTER		15
#define SPI_OK_REL_UNREGISTER	16
#define SPI_OK_TD_REGISTER		17
#define SPI_OK_MERGE			18

#define SPI_OPT_NONATOMIC		(1 << 0)

/* These used to be functions, now just no-ops for backwards compatibility */
#define SPI_push()	((void) 0)
#define SPI_pop()	((void) 0)
#define SPI_push_conditional()	false
#define SPI_pop_conditional(pushed) ((void) 0)
#define SPI_restore_connection()	((void) 0)

extern PGDLLIMPORT uint64 SPI_processed;
extern PGDLLIMPORT SPITupleTable *SPI_tuptable;
extern PGDLLIMPORT int SPI_result;

extern int	SPI_connect(void);
extern int	SPI_connect_ext(int options);
extern int	SPI_finish(void);
extern int	SPI_execute(const char *src, bool read_only, long tcount);
extern int	SPI_execute_extended(const char *src,
								 const SPIExecuteOptions *options);
extern int	SPI_execute_plan(SPIPlanPtr plan, Datum *Values, const char *Nulls,
							 bool read_only, long tcount);
extern int	SPI_execute_plan_extended(SPIPlanPtr plan,
									  const SPIExecuteOptions *options);
extern int	SPI_execute_plan_with_paramlist(SPIPlanPtr plan,
											ParamListInfo params,
											bool read_only, long tcount);
extern int	SPI_exec(const char *src, long tcount);
extern int	SPI_execp(SPIPlanPtr plan, Datum *Values, const char *Nulls,
					  long tcount);
extern int	SPI_execute_snapshot(SPIPlanPtr plan,
								 Datum *Values, const char *Nulls,
								 Snapshot snapshot,
								 Snapshot crosscheck_snapshot,
								 bool read_only, bool fire_triggers, long tcount);
extern int	SPI_execute_with_args(const char *src,
								  int nargs, Oid *argtypes,
								  Datum *Values, const char *Nulls,
								  bool read_only, long tcount);
extern SPIPlanPtr SPI_prepare(const char *src, int nargs, Oid *argtypes);
extern SPIPlanPtr SPI_prepare_cursor(const char *src, int nargs, Oid *argtypes,
									 int cursorOptions);
extern SPIPlanPtr SPI_prepare_extended(const char *src,
									   const SPIPrepareOptions *options);
extern SPIPlanPtr SPI_prepare_params(const char *src,
									 ParserSetupHook parserSetup,
									 void *parserSetupArg,
									 int cursorOptions);
extern int	SPI_keepplan(SPIPlanPtr plan);
extern SPIPlanPtr SPI_saveplan(SPIPlanPtr plan);
extern int	SPI_freeplan(SPIPlanPtr plan);

extern Oid	SPI_getargtypeid(SPIPlanPtr plan, int argIndex);
extern int	SPI_getargcount(SPIPlanPtr plan);
extern bool SPI_is_cursor_plan(SPIPlanPtr plan);
extern bool SPI_plan_is_valid(SPIPlanPtr plan);
extern const char *SPI_result_code_string(int code);

extern List *SPI_plan_get_plan_sources(SPIPlanPtr plan);
extern CachedPlan *SPI_plan_get_cached_plan(SPIPlanPtr plan);

extern HeapTuple SPI_copytuple(HeapTuple tuple);
extern HeapTupleHeader SPI_returntuple(HeapTuple tuple, TupleDesc tupdesc);
extern HeapTuple SPI_modifytuple(Relation rel, HeapTuple tuple, int natts,
								 int *attnum, Datum *Values, const char *Nulls);
extern int	SPI_fnumber(TupleDesc tupdesc, const char *fname);
extern char *SPI_fname(TupleDesc tupdesc, int fnumber);
extern char *SPI_getvalue(HeapTuple tuple, TupleDesc tupdesc, int fnumber);
extern Datum SPI_getbinval(HeapTuple tuple, TupleDesc tupdesc, int fnumber, bool *isnull);
extern char *SPI_gettype(TupleDesc tupdesc, int fnumber);
extern Oid	SPI_gettypeid(TupleDesc tupdesc, int fnumber);
extern char *SPI_getrelname(Relation rel);
extern char *SPI_getnspname(Relation rel);
extern void *SPI_palloc(Size size);
extern void *SPI_repalloc(void *pointer, Size size);
extern void SPI_pfree(void *pointer);
extern Datum SPI_datumTransfer(Datum value, bool typByVal, int typLen);
extern void SPI_freetuple(HeapTuple pointer);
extern void SPI_freetuptable(SPITupleTable *tuptable);

extern Portal SPI_cursor_open(const char *name, SPIPlanPtr plan,
							  Datum *Values, const char *Nulls, bool read_only);
extern Portal SPI_cursor_open_with_args(const char *name,
										const char *src,
										int nargs, Oid *argtypes,
										Datum *Values, const char *Nulls,
										bool read_only, int cursorOptions);
extern Portal SPI_cursor_open_with_paramlist(const char *name, SPIPlanPtr plan,
											 ParamListInfo params, bool read_only);
extern Portal SPI_cursor_parse_open(const char *name,
									const char *src,
									const SPIParseOpenOptions *options);
extern Portal SPI_cursor_find(const char *name);
extern void SPI_cursor_fetch(Portal portal, bool forward, long count);
extern void SPI_cursor_move(Portal portal, bool forward, long count);
extern void SPI_scroll_cursor_fetch(Portal, FetchDirection direction, long count);
extern void SPI_scroll_cursor_move(Portal, FetchDirection direction, long count);
extern void SPI_cursor_close(Portal portal);

extern int	SPI_register_relation(EphemeralNamedRelation enr);
extern int	SPI_unregister_relation(const char *name);
extern int	SPI_register_trigger_data(TriggerData *tdata);

extern void SPI_start_transaction(void);
extern void SPI_commit(void);
extern void SPI_commit_and_chain(void);
extern void SPI_rollback(void);
extern void SPI_rollback_and_chain(void);

extern void AtEOXact_SPI(bool isCommit);
extern void AtEOSubXact_SPI(bool isCommit, SubTransactionId mySubid);
extern bool SPI_inside_nonatomic_context(void);

#endif							/* SPI_H */
