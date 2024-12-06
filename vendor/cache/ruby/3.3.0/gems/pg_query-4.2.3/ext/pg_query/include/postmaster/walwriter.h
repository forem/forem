/*-------------------------------------------------------------------------
 *
 * walwriter.h
 *	  Exports from postmaster/walwriter.c.
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 *
 * src/include/postmaster/walwriter.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef _WALWRITER_H
#define _WALWRITER_H

/* GUC options */
extern PGDLLIMPORT int WalWriterDelay;
extern PGDLLIMPORT int WalWriterFlushAfter;

extern void WalWriterMain(void) pg_attribute_noreturn();

#endif							/* _WALWRITER_H */
