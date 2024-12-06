/*-------------------------------------------------------------------------
 *
 * walreceiver.h
 *	  Exports from replication/walreceiverfuncs.c.
 *
 * Portions Copyright (c) 2010-2022, PostgreSQL Global Development Group
 *
 * src/include/replication/walreceiver.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _WALRECEIVER_H
#define _WALRECEIVER_H

#include "access/xlog.h"
#include "access/xlogdefs.h"
#include "getaddrinfo.h"		/* for NI_MAXHOST */
#include "pgtime.h"
#include "port/atomics.h"
#include "replication/logicalproto.h"
#include "replication/walsender.h"
#include "storage/condition_variable.h"
#include "storage/latch.h"
#include "storage/spin.h"
#include "utils/tuplestore.h"

/* user-settable parameters */
extern PGDLLIMPORT int wal_receiver_status_interval;
extern PGDLLIMPORT int wal_receiver_timeout;
extern PGDLLIMPORT bool hot_standby_feedback;

/*
 * MAXCONNINFO: maximum size of a connection string.
 *
 * XXX: Should this move to pg_config_manual.h?
 */
#define MAXCONNINFO		1024

/* Can we allow the standby to accept replication connection from another standby? */
#define AllowCascadeReplication() (EnableHotStandby && max_wal_senders > 0)

/*
 * Values for WalRcv->walRcvState.
 */
typedef enum
{
	WALRCV_STOPPED,				/* stopped and mustn't start up again */
	WALRCV_STARTING,			/* launched, but the process hasn't
								 * initialized yet */
	WALRCV_STREAMING,			/* walreceiver is streaming */
	WALRCV_WAITING,				/* stopped streaming, waiting for orders */
	WALRCV_RESTARTING,			/* asked to restart streaming */
	WALRCV_STOPPING				/* requested to stop, but still running */
} WalRcvState;

/* Shared memory area for management of walreceiver process */
typedef struct
{
	/*
	 * PID of currently active walreceiver process, its current state and
	 * start time (actually, the time at which it was requested to be
	 * started).
	 */
	pid_t		pid;
	WalRcvState walRcvState;
	ConditionVariable walRcvStoppedCV;
	pg_time_t	startTime;

	/*
	 * receiveStart and receiveStartTLI indicate the first byte position and
	 * timeline that will be received. When startup process starts the
	 * walreceiver, it sets these to the point where it wants the streaming to
	 * begin.
	 */
	XLogRecPtr	receiveStart;
	TimeLineID	receiveStartTLI;

	/*
	 * flushedUpto-1 is the last byte position that has already been received,
	 * and receivedTLI is the timeline it came from.  At the first startup of
	 * walreceiver, these are set to receiveStart and receiveStartTLI. After
	 * that, walreceiver updates these whenever it flushes the received WAL to
	 * disk.
	 */
	XLogRecPtr	flushedUpto;
	TimeLineID	receivedTLI;

	/*
	 * latestChunkStart is the starting byte position of the current "batch"
	 * of received WAL.  It's actually the same as the previous value of
	 * flushedUpto before the last flush to disk.  Startup process can use
	 * this to detect whether it's keeping up or not.
	 */
	XLogRecPtr	latestChunkStart;

	/*
	 * Time of send and receive of any message received.
	 */
	TimestampTz lastMsgSendTime;
	TimestampTz lastMsgReceiptTime;

	/*
	 * Latest reported end of WAL on the sender
	 */
	XLogRecPtr	latestWalEnd;
	TimestampTz latestWalEndTime;

	/*
	 * connection string; initially set to connect to the primary, and later
	 * clobbered to hide security-sensitive fields.
	 */
	char		conninfo[MAXCONNINFO];

	/*
	 * Host name (this can be a host name, an IP address, or a directory path)
	 * and port number of the active replication connection.
	 */
	char		sender_host[NI_MAXHOST];
	int			sender_port;

	/*
	 * replication slot name; is also used for walreceiver to connect with the
	 * primary
	 */
	char		slotname[NAMEDATALEN];

	/*
	 * If it's a temporary replication slot, it needs to be recreated when
	 * connecting.
	 */
	bool		is_temp_slot;

	/* set true once conninfo is ready to display (obfuscated pwds etc) */
	bool		ready_to_display;

	/*
	 * Latch used by startup process to wake up walreceiver after telling it
	 * where to start streaming (after setting receiveStart and
	 * receiveStartTLI), and also to tell it to send apply feedback to the
	 * primary whenever specially marked commit records are applied. This is
	 * normally mapped to procLatch when walreceiver is running.
	 */
	Latch	   *latch;

	slock_t		mutex;			/* locks shared variables shown above */

	/*
	 * Like flushedUpto, but advanced after writing and before flushing,
	 * without the need to acquire the spin lock.  Data can be read by another
	 * process up to this point, but shouldn't be used for data integrity
	 * purposes.
	 */
	pg_atomic_uint64 writtenUpto;

	/*
	 * force walreceiver reply?  This doesn't need to be locked; memory
	 * barriers for ordering are sufficient.  But we do need atomic fetch and
	 * store semantics, so use sig_atomic_t.
	 */
	sig_atomic_t force_reply;	/* used as a bool */
} WalRcvData;

extern PGDLLIMPORT WalRcvData *WalRcv;

typedef struct
{
	bool		logical;		/* True if this is logical replication stream,
								 * false if physical stream.  */
	char	   *slotname;		/* Name of the replication slot or NULL. */
	XLogRecPtr	startpoint;		/* LSN of starting point. */

	union
	{
		struct
		{
			TimeLineID	startpointTLI;	/* Starting timeline */
		}			physical;
		struct
		{
			uint32		proto_version;	/* Logical protocol version */
			List	   *publication_names;	/* String list of publications */
			bool		binary; /* Ask publisher to use binary */
			bool		streaming;	/* Streaming of large transactions */
			bool		twophase;	/* Streaming of two-phase transactions at
									 * prepare time */
		}			logical;
	}			proto;
} WalRcvStreamOptions;

struct WalReceiverConn;
typedef struct WalReceiverConn WalReceiverConn;

/*
 * Status of walreceiver query execution.
 *
 * We only define statuses that are currently used.
 */
typedef enum
{
	WALRCV_ERROR,				/* There was error when executing the query. */
	WALRCV_OK_COMMAND,			/* Query executed utility or replication
								 * command. */
	WALRCV_OK_TUPLES,			/* Query returned tuples. */
	WALRCV_OK_COPY_IN,			/* Query started COPY FROM. */
	WALRCV_OK_COPY_OUT,			/* Query started COPY TO. */
	WALRCV_OK_COPY_BOTH			/* Query started COPY BOTH replication
								 * protocol. */
} WalRcvExecStatus;

/*
 * Return value for walrcv_exec, returns the status of the execution and
 * tuples if any.
 */
typedef struct WalRcvExecResult
{
	WalRcvExecStatus status;
	int			sqlstate;
	char	   *err;
	Tuplestorestate *tuplestore;
	TupleDesc	tupledesc;
} WalRcvExecResult;

/* WAL receiver - libpqwalreceiver hooks */

/*
 * walrcv_connect_fn
 *
 * Establish connection to a cluster.  'logical' is true if the
 * connection is logical, and false if the connection is physical.
 * 'appname' is a name associated to the connection, to use for example
 * with fallback_application_name or application_name.  Returns the
 * details about the connection established, as defined by
 * WalReceiverConn for each WAL receiver module.  On error, NULL is
 * returned with 'err' including the error generated.
 */
typedef WalReceiverConn *(*walrcv_connect_fn) (const char *conninfo,
											   bool logical,
											   const char *appname,
											   char **err);

/*
 * walrcv_check_conninfo_fn
 *
 * Parse and validate the connection string given as of 'conninfo'.
 */
typedef void (*walrcv_check_conninfo_fn) (const char *conninfo);

/*
 * walrcv_get_conninfo_fn
 *
 * Returns a user-displayable conninfo string.  Note that any
 * security-sensitive fields should be obfuscated.
 */
typedef char *(*walrcv_get_conninfo_fn) (WalReceiverConn *conn);

/*
 * walrcv_get_senderinfo_fn
 *
 * Provide information of the WAL sender this WAL receiver is connected
 * to, as of 'sender_host' for the host of the sender and 'sender_port'
 * for its port.
 */
typedef void (*walrcv_get_senderinfo_fn) (WalReceiverConn *conn,
										  char **sender_host,
										  int *sender_port);

/*
 * walrcv_identify_system_fn
 *
 * Run IDENTIFY_SYSTEM on the cluster connected to and validate the
 * identity of the cluster.  Returns the system ID of the cluster
 * connected to.  'primary_tli' is the timeline ID of the sender.
 */
typedef char *(*walrcv_identify_system_fn) (WalReceiverConn *conn,
											TimeLineID *primary_tli);

/*
 * walrcv_server_version_fn
 *
 * Returns the version number of the cluster connected to.
 */
typedef int (*walrcv_server_version_fn) (WalReceiverConn *conn);

/*
 * walrcv_readtimelinehistoryfile_fn
 *
 * Fetch from cluster the timeline history file for timeline 'tli'.
 * Returns the name of the timeline history file as of 'filename', its
 * contents as of 'content' and its 'size'.
 */
typedef void (*walrcv_readtimelinehistoryfile_fn) (WalReceiverConn *conn,
												   TimeLineID tli,
												   char **filename,
												   char **content,
												   int *size);

/*
 * walrcv_startstreaming_fn
 *
 * Start streaming WAL data from given streaming options.  Returns true
 * if the connection has switched successfully to copy-both mode and false
 * if the server received the command and executed it successfully, but
 * didn't switch to copy-mode.
 */
typedef bool (*walrcv_startstreaming_fn) (WalReceiverConn *conn,
										  const WalRcvStreamOptions *options);

/*
 * walrcv_endstreaming_fn
 *
 * Stop streaming of WAL data.  Returns the next timeline ID of the cluster
 * connected to in 'next_tli', or 0 if there was no report.
 */
typedef void (*walrcv_endstreaming_fn) (WalReceiverConn *conn,
										TimeLineID *next_tli);

/*
 * walrcv_receive_fn
 *
 * Receive a message available from the WAL stream.  'buffer' is a pointer
 * to a buffer holding the message received.  Returns the length of the data,
 * 0 if no data is available yet ('wait_fd' is a socket descriptor which can
 * be waited on before a retry), and -1 if the cluster ended the COPY.
 */
typedef int (*walrcv_receive_fn) (WalReceiverConn *conn,
								  char **buffer,
								  pgsocket *wait_fd);

/*
 * walrcv_send_fn
 *
 * Send a message of size 'nbytes' to the WAL stream with 'buffer' as
 * contents.
 */
typedef void (*walrcv_send_fn) (WalReceiverConn *conn,
								const char *buffer,
								int nbytes);

/*
 * walrcv_create_slot_fn
 *
 * Create a new replication slot named 'slotname'.  'temporary' defines
 * if the slot is temporary.  'snapshot_action' defines the behavior wanted
 * for an exported snapshot (see replication protocol for more details).
 * 'lsn' includes the LSN position at which the created slot became
 * consistent.  Returns the name of the exported snapshot for a logical
 * slot, or NULL for a physical slot.
 */
typedef char *(*walrcv_create_slot_fn) (WalReceiverConn *conn,
										const char *slotname,
										bool temporary,
										bool two_phase,
										CRSSnapshotAction snapshot_action,
										XLogRecPtr *lsn);

/*
 * walrcv_get_backend_pid_fn
 *
 * Returns the PID of the remote backend process.
 */
typedef pid_t (*walrcv_get_backend_pid_fn) (WalReceiverConn *conn);

/*
 * walrcv_exec_fn
 *
 * Send generic queries (and commands) to the remote cluster.  'nRetTypes'
 * is the expected number of returned attributes, and 'retTypes' an array
 * including their type OIDs.  Returns the status of the execution and
 * tuples if any.
 */
typedef WalRcvExecResult *(*walrcv_exec_fn) (WalReceiverConn *conn,
											 const char *query,
											 const int nRetTypes,
											 const Oid *retTypes);

/*
 * walrcv_disconnect_fn
 *
 * Disconnect with the cluster.
 */
typedef void (*walrcv_disconnect_fn) (WalReceiverConn *conn);

typedef struct WalReceiverFunctionsType
{
	walrcv_connect_fn walrcv_connect;
	walrcv_check_conninfo_fn walrcv_check_conninfo;
	walrcv_get_conninfo_fn walrcv_get_conninfo;
	walrcv_get_senderinfo_fn walrcv_get_senderinfo;
	walrcv_identify_system_fn walrcv_identify_system;
	walrcv_server_version_fn walrcv_server_version;
	walrcv_readtimelinehistoryfile_fn walrcv_readtimelinehistoryfile;
	walrcv_startstreaming_fn walrcv_startstreaming;
	walrcv_endstreaming_fn walrcv_endstreaming;
	walrcv_receive_fn walrcv_receive;
	walrcv_send_fn walrcv_send;
	walrcv_create_slot_fn walrcv_create_slot;
	walrcv_get_backend_pid_fn walrcv_get_backend_pid;
	walrcv_exec_fn walrcv_exec;
	walrcv_disconnect_fn walrcv_disconnect;
} WalReceiverFunctionsType;

extern PGDLLIMPORT WalReceiverFunctionsType *WalReceiverFunctions;

#define walrcv_connect(conninfo, logical, appname, err) \
	WalReceiverFunctions->walrcv_connect(conninfo, logical, appname, err)
#define walrcv_check_conninfo(conninfo) \
	WalReceiverFunctions->walrcv_check_conninfo(conninfo)
#define walrcv_get_conninfo(conn) \
	WalReceiverFunctions->walrcv_get_conninfo(conn)
#define walrcv_get_senderinfo(conn, sender_host, sender_port) \
	WalReceiverFunctions->walrcv_get_senderinfo(conn, sender_host, sender_port)
#define walrcv_identify_system(conn, primary_tli) \
	WalReceiverFunctions->walrcv_identify_system(conn, primary_tli)
#define walrcv_server_version(conn) \
	WalReceiverFunctions->walrcv_server_version(conn)
#define walrcv_readtimelinehistoryfile(conn, tli, filename, content, size) \
	WalReceiverFunctions->walrcv_readtimelinehistoryfile(conn, tli, filename, content, size)
#define walrcv_startstreaming(conn, options) \
	WalReceiverFunctions->walrcv_startstreaming(conn, options)
#define walrcv_endstreaming(conn, next_tli) \
	WalReceiverFunctions->walrcv_endstreaming(conn, next_tli)
#define walrcv_receive(conn, buffer, wait_fd) \
	WalReceiverFunctions->walrcv_receive(conn, buffer, wait_fd)
#define walrcv_send(conn, buffer, nbytes) \
	WalReceiverFunctions->walrcv_send(conn, buffer, nbytes)
#define walrcv_create_slot(conn, slotname, temporary, two_phase, snapshot_action, lsn) \
	WalReceiverFunctions->walrcv_create_slot(conn, slotname, temporary, two_phase, snapshot_action, lsn)
#define walrcv_get_backend_pid(conn) \
	WalReceiverFunctions->walrcv_get_backend_pid(conn)
#define walrcv_exec(conn, exec, nRetTypes, retTypes) \
	WalReceiverFunctions->walrcv_exec(conn, exec, nRetTypes, retTypes)
#define walrcv_disconnect(conn) \
	WalReceiverFunctions->walrcv_disconnect(conn)

static inline void
walrcv_clear_result(WalRcvExecResult *walres)
{
	if (!walres)
		return;

	if (walres->err)
		pfree(walres->err);

	if (walres->tuplestore)
		tuplestore_end(walres->tuplestore);

	if (walres->tupledesc)
		FreeTupleDesc(walres->tupledesc);

	pfree(walres);
}

/* prototypes for functions in walreceiver.c */
extern void WalReceiverMain(void) pg_attribute_noreturn();
extern void ProcessWalRcvInterrupts(void);

/* prototypes for functions in walreceiverfuncs.c */
extern Size WalRcvShmemSize(void);
extern void WalRcvShmemInit(void);
extern void ShutdownWalRcv(void);
extern bool WalRcvStreaming(void);
extern bool WalRcvRunning(void);
extern void RequestXLogStreaming(TimeLineID tli, XLogRecPtr recptr,
								 const char *conninfo, const char *slotname,
								 bool create_temp_slot);
extern XLogRecPtr GetWalRcvFlushRecPtr(XLogRecPtr *latestChunkStart, TimeLineID *receiveTLI);
extern XLogRecPtr GetWalRcvWriteRecPtr(void);
extern int	GetReplicationApplyDelay(void);
extern int	GetReplicationTransferLatency(void);
extern void WalRcvForceReply(void);

#endif							/* _WALRECEIVER_H */
