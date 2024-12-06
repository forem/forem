/*-------------------------------------------------------------------------
 *
 * fd.h
 *	  Virtual file descriptor definitions.
 *
 *
 * Portions Copyright (c) 1996-2022, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/storage/fd.h
 *
 *-------------------------------------------------------------------------
 */

/*
 * calls:
 *
 *	File {Close, Read, Write, Size, Sync}
 *	{Path Name Open, Allocate, Free} File
 *
 * These are NOT JUST RENAMINGS OF THE UNIX ROUTINES.
 * Use them for all file activity...
 *
 *	File fd;
 *	fd = PathNameOpenFile("foo", O_RDONLY);
 *
 *	AllocateFile();
 *	FreeFile();
 *
 * Use AllocateFile, not fopen, if you need a stdio file (FILE*); then
 * use FreeFile, not fclose, to close it.  AVOID using stdio for files
 * that you intend to hold open for any length of time, since there is
 * no way for them to share kernel file descriptors with other files.
 *
 * Likewise, use AllocateDir/FreeDir, not opendir/closedir, to allocate
 * open directories (DIR*), and OpenTransientFile/CloseTransientFile for an
 * unbuffered file descriptor.
 *
 * If you really can't use any of the above, at least call AcquireExternalFD
 * or ReserveExternalFD to report any file descriptors that are held for any
 * length of time.  Failure to do so risks unnecessary EMFILE errors.
 */
#ifndef FD_H
#define FD_H

#include <dirent.h>

typedef enum RecoveryInitSyncMethod
{
	RECOVERY_INIT_SYNC_METHOD_FSYNC,
	RECOVERY_INIT_SYNC_METHOD_SYNCFS
}			RecoveryInitSyncMethod;

struct iovec;					/* avoid including port/pg_iovec.h here */

typedef int File;


/* GUC parameter */
extern PGDLLIMPORT int max_files_per_process;
extern PGDLLIMPORT bool data_sync_retry;
extern PGDLLIMPORT int recovery_init_sync_method;

/*
 * This is private to fd.c, but exported for save/restore_backend_variables()
 */
extern PGDLLIMPORT int max_safe_fds;

/*
 * On Windows, we have to interpret EACCES as possibly meaning the same as
 * ENOENT, because if a file is unlinked-but-not-yet-gone on that platform,
 * that's what you get.  Ugh.  This code is designed so that we don't
 * actually believe these cases are okay without further evidence (namely,
 * a pending fsync request getting canceled ... see ProcessSyncRequests).
 */
#ifndef WIN32
#define FILE_POSSIBLY_DELETED(err)	((err) == ENOENT)
#else
#define FILE_POSSIBLY_DELETED(err)	((err) == ENOENT || (err) == EACCES)
#endif

/*
 * O_DIRECT is not standard, but almost every Unix has it.  We translate it
 * to the appropriate Windows flag in src/port/open.c.  We simulate it with
 * fcntl(F_NOCACHE) on macOS inside fd.c's open() wrapper.  We use the name
 * PG_O_DIRECT rather than defining O_DIRECT in that case (probably not a good
 * idea on a Unix).
 */
#if defined(O_DIRECT)
#define		PG_O_DIRECT O_DIRECT
#elif defined(F_NOCACHE)
#define		PG_O_DIRECT 0x80000000
#define		PG_O_DIRECT_USE_F_NOCACHE
#else
#define		PG_O_DIRECT 0
#endif

/*
 * prototypes for functions in fd.c
 */

/* Operations on virtual Files --- equivalent to Unix kernel file ops */
extern File PathNameOpenFile(const char *fileName, int fileFlags);
extern File PathNameOpenFilePerm(const char *fileName, int fileFlags, mode_t fileMode);
extern File OpenTemporaryFile(bool interXact);
extern void FileClose(File file);
extern int	FilePrefetch(File file, off_t offset, int amount, uint32 wait_event_info);
extern int	FileRead(File file, char *buffer, int amount, off_t offset, uint32 wait_event_info);
extern int	FileWrite(File file, char *buffer, int amount, off_t offset, uint32 wait_event_info);
extern int	FileSync(File file, uint32 wait_event_info);
extern off_t FileSize(File file);
extern int	FileTruncate(File file, off_t offset, uint32 wait_event_info);
extern void FileWriteback(File file, off_t offset, off_t nbytes, uint32 wait_event_info);
extern char *FilePathName(File file);
extern int	FileGetRawDesc(File file);
extern int	FileGetRawFlags(File file);
extern mode_t FileGetRawMode(File file);

/* Operations used for sharing named temporary files */
extern File PathNameCreateTemporaryFile(const char *name, bool error_on_failure);
extern File PathNameOpenTemporaryFile(const char *path, int mode);
extern bool PathNameDeleteTemporaryFile(const char *name, bool error_on_failure);
extern void PathNameCreateTemporaryDir(const char *base, const char *name);
extern void PathNameDeleteTemporaryDir(const char *name);
extern void TempTablespacePath(char *path, Oid tablespace);

/* Operations that allow use of regular stdio --- USE WITH CAUTION */
extern FILE *AllocateFile(const char *name, const char *mode);
extern int	FreeFile(FILE *file);

/* Operations that allow use of pipe streams (popen/pclose) */
extern FILE *OpenPipeStream(const char *command, const char *mode);
extern int	ClosePipeStream(FILE *file);

/* Operations to allow use of the <dirent.h> library routines */
extern DIR *AllocateDir(const char *dirname);
extern struct dirent *ReadDir(DIR *dir, const char *dirname);
extern struct dirent *ReadDirExtended(DIR *dir, const char *dirname,
									  int elevel);
extern int	FreeDir(DIR *dir);

/* Operations to allow use of a plain kernel FD, with automatic cleanup */
extern int	OpenTransientFile(const char *fileName, int fileFlags);
extern int	OpenTransientFilePerm(const char *fileName, int fileFlags, mode_t fileMode);
extern int	CloseTransientFile(int fd);

/* If you've really really gotta have a plain kernel FD, use this */
extern int	BasicOpenFile(const char *fileName, int fileFlags);
extern int	BasicOpenFilePerm(const char *fileName, int fileFlags, mode_t fileMode);

/* Use these for other cases, and also for long-lived BasicOpenFile FDs */
extern bool AcquireExternalFD(void);
extern void ReserveExternalFD(void);
extern void ReleaseExternalFD(void);

/* Make a directory with default permissions */
extern int	MakePGDirectory(const char *directoryName);

/* Miscellaneous support routines */
extern void InitFileAccess(void);
extern void InitTemporaryFileAccess(void);
extern void set_max_safe_fds(void);
extern void closeAllVfds(void);
extern void SetTempTablespaces(Oid *tableSpaces, int numSpaces);
extern bool TempTablespacesAreSet(void);
extern int	GetTempTablespaces(Oid *tableSpaces, int numSpaces);
extern Oid	GetNextTempTableSpace(void);
extern void AtEOXact_Files(bool isCommit);
extern void AtEOSubXact_Files(bool isCommit, SubTransactionId mySubid,
							  SubTransactionId parentSubid);
extern void RemovePgTempFiles(void);
extern void RemovePgTempFilesInDir(const char *tmpdirname, bool missing_ok,
								   bool unlink_all);
extern bool looks_like_temp_rel_name(const char *name);

extern int	pg_fsync(int fd);
extern int	pg_fsync_no_writethrough(int fd);
extern int	pg_fsync_writethrough(int fd);
extern int	pg_fdatasync(int fd);
extern void pg_flush_data(int fd, off_t offset, off_t amount);
extern ssize_t pg_pwritev_with_retry(int fd,
									 const struct iovec *iov,
									 int iovcnt,
									 off_t offset);
extern int	pg_truncate(const char *path, off_t length);
extern void fsync_fname(const char *fname, bool isdir);
extern int	fsync_fname_ext(const char *fname, bool isdir, bool ignore_perm, int elevel);
extern int	durable_rename(const char *oldfile, const char *newfile, int loglevel);
extern int	durable_unlink(const char *fname, int loglevel);
extern int	durable_rename_excl(const char *oldfile, const char *newfile, int loglevel);
extern void SyncDataDirectory(void);
extern int	data_sync_elevel(int elevel);

/* Filename components */
#define PG_TEMP_FILES_DIR "pgsql_tmp"
#define PG_TEMP_FILE_PREFIX "pgsql_tmp"

#endif							/* FD_H */
