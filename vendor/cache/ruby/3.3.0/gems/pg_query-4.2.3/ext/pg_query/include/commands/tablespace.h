/*-------------------------------------------------------------------------
 *
 * tablespace.h
 *		Tablespace management commands (create/drop tablespace).
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/commands/tablespace.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef TABLESPACE_H
#define TABLESPACE_H

#include "access/xlogreader.h"
#include "catalog/objectaddress.h"
#include "lib/stringinfo.h"
#include "nodes/parsenodes.h"

extern PGDLLIMPORT bool allow_in_place_tablespaces;

/* XLOG stuff */
#define XLOG_TBLSPC_CREATE		0x00
#define XLOG_TBLSPC_DROP		0x10

typedef struct xl_tblspc_create_rec
{
	Oid			ts_id;
	char		ts_path[FLEXIBLE_ARRAY_MEMBER]; /* null-terminated string */
} xl_tblspc_create_rec;

typedef struct xl_tblspc_drop_rec
{
	Oid			ts_id;
} xl_tblspc_drop_rec;

typedef struct TableSpaceOpts
{
	int32		vl_len_;		/* varlena header (do not touch directly!) */
	float8		random_page_cost;
	float8		seq_page_cost;
	int			effective_io_concurrency;
	int			maintenance_io_concurrency;
} TableSpaceOpts;

extern Oid	CreateTableSpace(CreateTableSpaceStmt *stmt);
extern void DropTableSpace(DropTableSpaceStmt *stmt);
extern ObjectAddress RenameTableSpace(const char *oldname, const char *newname);
extern Oid	AlterTableSpaceOptions(AlterTableSpaceOptionsStmt *stmt);

extern void TablespaceCreateDbspace(Oid spcNode, Oid dbNode, bool isRedo);

extern Oid	GetDefaultTablespace(char relpersistence, bool partitioned);

extern void PrepareTempTablespaces(void);

extern Oid	get_tablespace_oid(const char *tablespacename, bool missing_ok);
extern char *get_tablespace_name(Oid spc_oid);

extern bool directory_is_empty(const char *path);
extern void remove_tablespace_symlink(const char *linkloc);

extern void tblspc_redo(XLogReaderState *rptr);
extern void tblspc_desc(StringInfo buf, XLogReaderState *rptr);
extern const char *tblspc_identify(uint8 info);

#endif							/* TABLESPACE_H */
