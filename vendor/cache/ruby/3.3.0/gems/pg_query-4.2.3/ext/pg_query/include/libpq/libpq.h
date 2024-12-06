/*-------------------------------------------------------------------------
 *
 * libpq.h
 *	  POSTGRES LIBPQ buffer structure definitions.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/libpq/libpq.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef LIBPQ_H
#define LIBPQ_H

#include <netinet/in.h>

#include "lib/stringinfo.h"
#include "libpq/libpq-be.h"
#include "storage/latch.h"


/*
 * Callers of pq_getmessage() must supply a maximum expected message size.
 * By convention, if there's not any specific reason to use another value,
 * use PQ_SMALL_MESSAGE_LIMIT for messages that shouldn't be too long, and
 * PQ_LARGE_MESSAGE_LIMIT for messages that can be long.
 */
#define PQ_SMALL_MESSAGE_LIMIT	10000
#define PQ_LARGE_MESSAGE_LIMIT	(MaxAllocSize - 1)

typedef struct
{
	void		(*comm_reset) (void);
	int			(*flush) (void);
	int			(*flush_if_writable) (void);
	bool		(*is_send_pending) (void);
	int			(*putmessage) (char msgtype, const char *s, size_t len);
	void		(*putmessage_noblock) (char msgtype, const char *s, size_t len);
} PQcommMethods;

extern const PGDLLIMPORT PQcommMethods *PqCommMethods;

#define pq_comm_reset() (PqCommMethods->comm_reset())
#define pq_flush() (PqCommMethods->flush())
#define pq_flush_if_writable() (PqCommMethods->flush_if_writable())
#define pq_is_send_pending() (PqCommMethods->is_send_pending())
#define pq_putmessage(msgtype, s, len) \
	(PqCommMethods->putmessage(msgtype, s, len))
#define pq_putmessage_noblock(msgtype, s, len) \
	(PqCommMethods->putmessage_noblock(msgtype, s, len))

/*
 * External functions.
 */

/*
 * prototypes for functions in pqcomm.c
 */
extern PGDLLIMPORT WaitEventSet *FeBeWaitSet;

#define FeBeWaitSetSocketPos 0
#define FeBeWaitSetLatchPos 1
#define FeBeWaitSetNEvents 3

extern int	StreamServerPort(int family, const char *hostName,
							 unsigned short portNumber, const char *unixSocketDir,
							 pgsocket ListenSocket[], int MaxListen);
extern int	StreamConnection(pgsocket server_fd, Port *port);
extern void StreamClose(pgsocket sock);
extern void TouchSocketFiles(void);
extern void RemoveSocketFiles(void);
extern void pq_init(void);
extern int	pq_getbytes(char *s, size_t len);
extern void pq_startmsgread(void);
extern void pq_endmsgread(void);
extern bool pq_is_reading_msg(void);
extern int	pq_getmessage(StringInfo s, int maxlen);
extern int	pq_getbyte(void);
extern int	pq_peekbyte(void);
extern int	pq_getbyte_if_available(unsigned char *c);
extern bool pq_buffer_has_data(void);
extern int	pq_putmessage_v2(char msgtype, const char *s, size_t len);
extern bool pq_check_connection(void);

/*
 * prototypes for functions in be-secure.c
 */
extern PGDLLIMPORT char *ssl_library;
extern PGDLLIMPORT char *ssl_cert_file;
extern PGDLLIMPORT char *ssl_key_file;
extern PGDLLIMPORT char *ssl_ca_file;
extern PGDLLIMPORT char *ssl_crl_file;
extern PGDLLIMPORT char *ssl_crl_dir;
extern PGDLLIMPORT char *ssl_dh_params_file;
extern PGDLLIMPORT char *ssl_passphrase_command;
extern PGDLLIMPORT bool ssl_passphrase_command_supports_reload;
#ifdef USE_SSL
extern PGDLLIMPORT bool ssl_loaded_verify_locations;
#endif

extern int	secure_initialize(bool isServerStart);
extern bool secure_loaded_verify_locations(void);
extern void secure_destroy(void);
extern int	secure_open_server(Port *port);
extern void secure_close(Port *port);
extern ssize_t secure_read(Port *port, void *ptr, size_t len);
extern ssize_t secure_write(Port *port, void *ptr, size_t len);
extern ssize_t secure_raw_read(Port *port, void *ptr, size_t len);
extern ssize_t secure_raw_write(Port *port, const void *ptr, size_t len);

/*
 * prototypes for functions in be-secure-gssapi.c
 */
#ifdef ENABLE_GSS
extern ssize_t secure_open_gssapi(Port *port);
#endif

/* GUCs */
extern PGDLLIMPORT char *SSLCipherSuites;
extern PGDLLIMPORT char *SSLECDHCurve;
extern PGDLLIMPORT bool SSLPreferServerCiphers;
extern PGDLLIMPORT int ssl_min_protocol_version;
extern PGDLLIMPORT int ssl_max_protocol_version;

enum ssl_protocol_versions
{
	PG_TLS_ANY = 0,
	PG_TLS1_VERSION,
	PG_TLS1_1_VERSION,
	PG_TLS1_2_VERSION,
	PG_TLS1_3_VERSION,
};

/*
 * prototypes for functions in be-secure-common.c
 */
extern int	run_ssl_passphrase_command(const char *prompt, bool is_server_start,
									   char *buf, int size);
extern bool check_ssl_key_file_permissions(const char *ssl_key_file,
										   bool isServerStart);

#endif							/* LIBPQ_H */
