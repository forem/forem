/*-------------------------------------------------------------------------
 *
 * File and directory permission definitions
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/common/file_perm.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef FILE_PERM_H
#define FILE_PERM_H

#include <sys/stat.h>

/*
 * Mode mask for data directory permissions that only allows the owner to
 * read/write directories and files.
 *
 * This is the default.
 */
#define PG_MODE_MASK_OWNER		    (S_IRWXG | S_IRWXO)

/*
 * Mode mask for data directory permissions that also allows group read/execute.
 */
#define PG_MODE_MASK_GROUP			(S_IWGRP | S_IRWXO)

/* Default mode for creating directories */
#define PG_DIR_MODE_OWNER			S_IRWXU

/* Mode for creating directories that allows group read/execute */
#define PG_DIR_MODE_GROUP			(S_IRWXU | S_IRGRP | S_IXGRP)

/* Default mode for creating files */
#define PG_FILE_MODE_OWNER		    (S_IRUSR | S_IWUSR)

/* Mode for creating files that allows group read */
#define PG_FILE_MODE_GROUP			(S_IRUSR | S_IWUSR | S_IRGRP)

/* Modes for creating directories and files in the data directory */
extern PGDLLIMPORT int pg_dir_create_mode;
extern PGDLLIMPORT int pg_file_create_mode;

/* Mode mask to pass to umask() */
extern PGDLLIMPORT int pg_mode_mask;

/* Set permissions and mask based on the provided mode */
extern void SetDataDirectoryCreatePerm(int dataDirMode);

/* Set permissions and mask based on the mode of the data directory */
extern bool GetDataDirectoryCreatePerm(const char *dataDir);

#endif							/* FILE_PERM_H */
