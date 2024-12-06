/*-------------------------------------------------------------------------
 *
 * dbcommands.h
 *		Database management commands (create/drop database).
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/dbcommands.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef DBCOMMANDS_H
#define DBCOMMANDS_H

#include "access/xlogreader.h"
#include "catalog/objectaddress.h"
#include "lib/stringinfo.h"
#include "parser/parse_node.h"

extern Oid	createdb(ParseState *pstate, const CreatedbStmt *stmt);
extern void dropdb(const char *dbname, bool missing_ok, bool force);
extern void DropDatabase(ParseState *pstate, DropdbStmt *stmt);
extern ObjectAddress RenameDatabase(const char *oldname, const char *newname);
extern Oid	AlterDatabase(ParseState *pstate, AlterDatabaseStmt *stmt, bool isTopLevel);
extern ObjectAddress AlterDatabaseRefreshColl(AlterDatabaseRefreshCollStmt *stmt);
extern Oid	AlterDatabaseSet(AlterDatabaseSetStmt *stmt);
extern ObjectAddress AlterDatabaseOwner(const char *dbname, Oid newOwnerId);

extern Oid	get_database_oid(const char *dbname, bool missing_ok);
extern char *get_database_name(Oid dbid);

extern void check_encoding_locale_matches(int encoding, const char *collate, const char *ctype);

#endif							/* DBCOMMANDS_H */
