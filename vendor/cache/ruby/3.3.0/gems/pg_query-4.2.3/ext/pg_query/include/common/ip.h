/*-------------------------------------------------------------------------
 *
 * ip.h
 *	  Definitions for IPv6-aware network access.
 *
 * These definitions are used by both frontend and backend code.
 *
 * Copyright (c) 2003-2022, PostgreSQL Global Development Group
 *
 * src/include/common/ip.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef IP_H
#define IP_H

#include "getaddrinfo.h"		/* pgrminclude ignore */
#include "libpq/pqcomm.h"		/* pgrminclude ignore */


extern int	pg_getaddrinfo_all(const char *hostname, const char *servname,
							   const struct addrinfo *hintp,
							   struct addrinfo **result);
extern void pg_freeaddrinfo_all(int hint_ai_family, struct addrinfo *ai);

extern int	pg_getnameinfo_all(const struct sockaddr_storage *addr, int salen,
							   char *node, int nodelen,
							   char *service, int servicelen,
							   int flags);

#endif							/* IP_H */
