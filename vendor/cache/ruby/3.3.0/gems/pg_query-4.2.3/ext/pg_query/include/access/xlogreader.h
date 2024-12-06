/*-------------------------------------------------------------------------
 *
 * xlogreader.h
 *		Definitions for the generic XLog reading facility
 *
 * Portions Copyright (c) 2013-2022, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *		src/include/access/xlogreader.h
 *
 * NOTES
 *		See the definition of the XLogReaderState struct for instructions on
 *		how to use the XLogReader infrastructure.
 *
 *		The basic idea is to allocate an XLogReaderState via
 *		XLogReaderAllocate(), position the reader to the first record with
 *		XLogBeginRead() or XLogFindNextRecord(), and call XLogReadRecord()
 *		until it returns NULL.
 *
 *		Callers supply a page_read callback if they want to call
 *		XLogReadRecord or XLogFindNextRecord; it can be passed in as NULL
 *		otherwise.  The WALRead function can be used as a helper to write
 *		page_read callbacks, but it is not mandatory; callers that use it,
 *		must supply segment_open callbacks.  The segment_close callback
 *		must always be supplied.
 *
 *		After reading a record with XLogReadRecord(), it's decomposed into
 *		the per-block and main data parts, and the parts can be accessed
 *		with the XLogRec* macros and functions. You can also decode a
 *		record that's already constructed in memory, without reading from
 *		disk, by calling the DecodeXLogRecord() function.
 *-------------------------------------------------------------------------
 */
#ifndef XLOGREADER_H
#define XLOGREADER_H

#ifndef FRONTEND
#include "access/transam.h"
#endif

#include "access/xlogrecord.h"
#include "storage/buf.h"

/* WALOpenSegment represents a WAL segment being read. */
typedef struct WALOpenSegment
{
	int			ws_file;		/* segment file descriptor */
	XLogSegNo	ws_segno;		/* segment number */
	TimeLineID	ws_tli;			/* timeline ID of the currently open file */
} WALOpenSegment;

/* WALSegmentContext carries context information about WAL segments to read */
typedef struct WALSegmentContext
{
	char		ws_dir[MAXPGPATH];
	int			ws_segsize;
} WALSegmentContext;

typedef struct XLogReaderState XLogReaderState;

/* Function type definitions for various xlogreader interactions */
typedef int (*XLogPageReadCB) (XLogReaderState *xlogreader,
							   XLogRecPtr targetPagePtr,
							   int reqLen,
							   XLogRecPtr targetRecPtr,
							   char *readBuf);
typedef void (*WALSegmentOpenCB) (XLogReaderState *xlogreader,
								  XLogSegNo nextSegNo,
								  TimeLineID *tli_p);
typedef void (*WALSegmentCloseCB) (XLogReaderState *xlogreader);

typedef struct XLogReaderRoutine
{
	/*
	 * Data input callback
	 *
	 * This callback shall read at least reqLen valid bytes of the xlog page
	 * starting at targetPagePtr, and store them in readBuf.  The callback
	 * shall return the number of bytes read (never more than XLOG_BLCKSZ), or
	 * -1 on failure.  The callback shall sleep, if necessary, to wait for the
	 * requested bytes to become available.  The callback will not be invoked
	 * again for the same page unless more than the returned number of bytes
	 * are needed.
	 *
	 * targetRecPtr is the position of the WAL record we're reading.  Usually
	 * it is equal to targetPagePtr + reqLen, but sometimes xlogreader needs
	 * to read and verify the page or segment header, before it reads the
	 * actual WAL record it's interested in.  In that case, targetRecPtr can
	 * be used to determine which timeline to read the page from.
	 *
	 * The callback shall set ->seg.ws_tli to the TLI of the file the page was
	 * read from.
	 */
	XLogPageReadCB page_read;

	/*
	 * Callback to open the specified WAL segment for reading.  ->seg.ws_file
	 * shall be set to the file descriptor of the opened segment.  In case of
	 * failure, an error shall be raised by the callback and it shall not
	 * return.
	 *
	 * "nextSegNo" is the number of the segment to be opened.
	 *
	 * "tli_p" is an input/output argument. WALRead() uses it to pass the
	 * timeline in which the new segment should be found, but the callback can
	 * use it to return the TLI that it actually opened.
	 */
	WALSegmentOpenCB segment_open;

	/*
	 * WAL segment close callback.  ->seg.ws_file shall be set to a negative
	 * number.
	 */
	WALSegmentCloseCB segment_close;
} XLogReaderRoutine;

#define XL_ROUTINE(...) &(XLogReaderRoutine){__VA_ARGS__}

typedef struct
{
	/* Is this block ref in use? */
	bool		in_use;

	/* Identify the block this refers to */
	RelFileNode rnode;
	ForkNumber	forknum;
	BlockNumber blkno;

	/* Prefetching workspace. */
	Buffer		prefetch_buffer;

	/* copy of the fork_flags field from the XLogRecordBlockHeader */
	uint8		flags;

	/* Information on full-page image, if any */
	bool		has_image;		/* has image, even for consistency checking */
	bool		apply_image;	/* has image that should be restored */
	char	   *bkp_image;
	uint16		hole_offset;
	uint16		hole_length;
	uint16		bimg_len;
	uint8		bimg_info;

	/* Buffer holding the rmgr-specific data associated with this block */
	bool		has_data;
	char	   *data;
	uint16		data_len;
	uint16		data_bufsz;
} DecodedBkpBlock;

/*
 * The decoded contents of a record.  This occupies a contiguous region of
 * memory, with main_data and blocks[n].data pointing to memory after the
 * members declared here.
 */
typedef struct DecodedXLogRecord
{
	/* Private member used for resource management. */
	size_t		size;			/* total size of decoded record */
	bool		oversized;		/* outside the regular decode buffer? */
	struct DecodedXLogRecord *next; /* decoded record queue link */

	/* Public members. */
	XLogRecPtr	lsn;			/* location */
	XLogRecPtr	next_lsn;		/* location of next record */
	XLogRecord	header;			/* header */
	RepOriginId record_origin;
	TransactionId toplevel_xid; /* XID of top-level transaction */
	char	   *main_data;		/* record's main data portion */
	uint32		main_data_len;	/* main data portion's length */
	int			max_block_id;	/* highest block_id in use (-1 if none) */
	DecodedBkpBlock blocks[FLEXIBLE_ARRAY_MEMBER];
} DecodedXLogRecord;

struct XLogReaderState
{
	/*
	 * Operational callbacks
	 */
	XLogReaderRoutine routine;

	/* ----------------------------------------
	 * Public parameters
	 * ----------------------------------------
	 */

	/*
	 * System identifier of the xlog files we're about to read.  Set to zero
	 * (the default value) if unknown or unimportant.
	 */
	uint64		system_identifier;

	/*
	 * Opaque data for callbacks to use.  Not used by XLogReader.
	 */
	void	   *private_data;

	/*
	 * Start and end point of last record read.  EndRecPtr is also used as the
	 * position to read next.  Calling XLogBeginRead() sets EndRecPtr to the
	 * starting position and ReadRecPtr to invalid.
	 *
	 * Start and end point of last record returned by XLogReadRecord().  These
	 * are also available as record->lsn and record->next_lsn.
	 */
	XLogRecPtr	ReadRecPtr;		/* start of last record read */
	XLogRecPtr	EndRecPtr;		/* end+1 of last record read */

	/*
	 * Set at the end of recovery: the start point of a partial record at the
	 * end of WAL (InvalidXLogRecPtr if there wasn't one), and the start
	 * location of its first contrecord that went missing.
	 */
	XLogRecPtr	abortedRecPtr;
	XLogRecPtr	missingContrecPtr;
	/* Set when XLP_FIRST_IS_OVERWRITE_CONTRECORD is found */
	XLogRecPtr	overwrittenRecPtr;


	/* ----------------------------------------
	 * Decoded representation of current record
	 *
	 * Use XLogRecGet* functions to investigate the record; these fields
	 * should not be accessed directly.
	 * ----------------------------------------
	 * Start and end point of the last record read and decoded by
	 * XLogReadRecordInternal().  NextRecPtr is also used as the position to
	 * decode next.  Calling XLogBeginRead() sets NextRecPtr and EndRecPtr to
	 * the requested starting position.
	 */
	XLogRecPtr	DecodeRecPtr;	/* start of last record decoded */
	XLogRecPtr	NextRecPtr;		/* end+1 of last record decoded */
	XLogRecPtr	PrevRecPtr;		/* start of previous record decoded */

	/* Last record returned by XLogReadRecord(). */
	DecodedXLogRecord *record;

	/* ----------------------------------------
	 * private/internal state
	 * ----------------------------------------
	 */

	/*
	 * Buffer for decoded records.  This is a circular buffer, though
	 * individual records can't be split in the middle, so some space is often
	 * wasted at the end.  Oversized records that don't fit in this space are
	 * allocated separately.
	 */
	char	   *decode_buffer;
	size_t		decode_buffer_size;
	bool		free_decode_buffer; /* need to free? */
	char	   *decode_buffer_head; /* data is read from the head */
	char	   *decode_buffer_tail; /* new data is written at the tail */

	/*
	 * Queue of records that have been decoded.  This is a linked list that
	 * usually consists of consecutive records in decode_buffer, but may also
	 * contain oversized records allocated with palloc().
	 */
	DecodedXLogRecord *decode_queue_head;	/* oldest decoded record */
	DecodedXLogRecord *decode_queue_tail;	/* newest decoded record */

	/*
	 * Buffer for currently read page (XLOG_BLCKSZ bytes, valid up to at least
	 * readLen bytes)
	 */
	char	   *readBuf;
	uint32		readLen;

	/* last read XLOG position for data currently in readBuf */
	WALSegmentContext segcxt;
	WALOpenSegment seg;
	uint32		segoff;

	/*
	 * beginning of prior page read, and its TLI.  Doesn't necessarily
	 * correspond to what's in readBuf; used for timeline sanity checks.
	 */
	XLogRecPtr	latestPagePtr;
	TimeLineID	latestPageTLI;

	/* beginning of the WAL record being read. */
	XLogRecPtr	currRecPtr;
	/* timeline to read it from, 0 if a lookup is required */
	TimeLineID	currTLI;

	/*
	 * Safe point to read to in currTLI if current TLI is historical
	 * (tliSwitchPoint) or InvalidXLogRecPtr if on current timeline.
	 *
	 * Actually set to the start of the segment containing the timeline switch
	 * that ends currTLI's validity, not the LSN of the switch its self, since
	 * we can't assume the old segment will be present.
	 */
	XLogRecPtr	currTLIValidUntil;

	/*
	 * If currTLI is not the most recent known timeline, the next timeline to
	 * read from when currTLIValidUntil is reached.
	 */
	TimeLineID	nextTLI;

	/*
	 * Buffer for current ReadRecord result (expandable), used when a record
	 * crosses a page boundary.
	 */
	char	   *readRecordBuf;
	uint32		readRecordBufSize;

	/* Buffer to hold error message */
	char	   *errormsg_buf;
	bool		errormsg_deferred;

	/*
	 * Flag to indicate to XLogPageReadCB that it should not block waiting for
	 * data.
	 */
	bool		nonblocking;
};

/*
 * Check if XLogNextRecord() has any more queued records or an error to return.
 */
static inline bool
XLogReaderHasQueuedRecordOrError(XLogReaderState *state)
{
	return (state->decode_queue_head != NULL) || state->errormsg_deferred;
}

/* Get a new XLogReader */
extern XLogReaderState *XLogReaderAllocate(int wal_segment_size,
										   const char *waldir,
										   XLogReaderRoutine *routine,
										   void *private_data);
extern XLogReaderRoutine *LocalXLogReaderRoutine(void);

/* Free an XLogReader */
extern void XLogReaderFree(XLogReaderState *state);

/* Optionally provide a circular decoding buffer to allow readahead. */
extern void XLogReaderSetDecodeBuffer(XLogReaderState *state,
									  void *buffer,
									  size_t size);

/* Position the XLogReader to given record */
extern void XLogBeginRead(XLogReaderState *state, XLogRecPtr RecPtr);
extern XLogRecPtr XLogFindNextRecord(XLogReaderState *state, XLogRecPtr RecPtr);

/* Return values from XLogPageReadCB. */
typedef enum XLogPageReadResult
{
	XLREAD_SUCCESS = 0,			/* record is successfully read */
	XLREAD_FAIL = -1,			/* failed during reading a record */
	XLREAD_WOULDBLOCK = -2		/* nonblocking mode only, no data */
} XLogPageReadResult;

/* Read the next XLog record. Returns NULL on end-of-WAL or failure */
extern struct XLogRecord *XLogReadRecord(XLogReaderState *state,
										 char **errormsg);

/* Consume the next record or error. */
extern DecodedXLogRecord *XLogNextRecord(XLogReaderState *state,
										 char **errormsg);

/* Release the previously returned record, if necessary. */
extern XLogRecPtr XLogReleasePreviousRecord(XLogReaderState *state);

/* Try to read ahead, if there is data and space. */
extern DecodedXLogRecord *XLogReadAhead(XLogReaderState *state,
										bool nonblocking);

/* Validate a page */
extern bool XLogReaderValidatePageHeader(XLogReaderState *state,
										 XLogRecPtr recptr, char *phdr);

/* Forget error produced by XLogReaderValidatePageHeader(). */
extern void XLogReaderResetError(XLogReaderState *state);

/*
 * Error information from WALRead that both backend and frontend caller can
 * process.  Currently only errors from pg_pread can be reported.
 */
typedef struct WALReadError
{
	int			wre_errno;		/* errno set by the last pg_pread() */
	int			wre_off;		/* Offset we tried to read from. */
	int			wre_req;		/* Bytes requested to be read. */
	int			wre_read;		/* Bytes read by the last read(). */
	WALOpenSegment wre_seg;		/* Segment we tried to read from. */
} WALReadError;

extern bool WALRead(XLogReaderState *state,
					char *buf, XLogRecPtr startptr, Size count,
					TimeLineID tli, WALReadError *errinfo);

/* Functions for decoding an XLogRecord */

extern size_t DecodeXLogRecordRequiredSpace(size_t xl_tot_len);
extern bool DecodeXLogRecord(XLogReaderState *state,
							 DecodedXLogRecord *decoded,
							 XLogRecord *record,
							 XLogRecPtr lsn,
							 char **errmsg);

/*
 * Macros that provide access to parts of the record most recently returned by
 * XLogReadRecord() or XLogNextRecord().
 */
#define XLogRecGetTotalLen(decoder) ((decoder)->record->header.xl_tot_len)
#define XLogRecGetPrev(decoder) ((decoder)->record->header.xl_prev)
#define XLogRecGetInfo(decoder) ((decoder)->record->header.xl_info)
#define XLogRecGetRmid(decoder) ((decoder)->record->header.xl_rmid)
#define XLogRecGetXid(decoder) ((decoder)->record->header.xl_xid)
#define XLogRecGetOrigin(decoder) ((decoder)->record->record_origin)
#define XLogRecGetTopXid(decoder) ((decoder)->record->toplevel_xid)
#define XLogRecGetData(decoder) ((decoder)->record->main_data)
#define XLogRecGetDataLen(decoder) ((decoder)->record->main_data_len)
#define XLogRecHasAnyBlockRefs(decoder) ((decoder)->record->max_block_id >= 0)
#define XLogRecMaxBlockId(decoder) ((decoder)->record->max_block_id)
#define XLogRecGetBlock(decoder, i) (&(decoder)->record->blocks[(i)])
#define XLogRecHasBlockRef(decoder, block_id)			\
	(((decoder)->record->max_block_id >= (block_id)) &&	\
	 ((decoder)->record->blocks[block_id].in_use))
#define XLogRecHasBlockImage(decoder, block_id)		\
	((decoder)->record->blocks[block_id].has_image)
#define XLogRecBlockImageApply(decoder, block_id)		\
	((decoder)->record->blocks[block_id].apply_image)

#ifndef FRONTEND
extern FullTransactionId XLogRecGetFullXid(XLogReaderState *record);
#endif

extern bool RestoreBlockImage(XLogReaderState *record, uint8 block_id, char *page);
extern char *XLogRecGetBlockData(XLogReaderState *record, uint8 block_id, Size *len);
extern void XLogRecGetBlockTag(XLogReaderState *record, uint8 block_id,
							   RelFileNode *rnode, ForkNumber *forknum,
							   BlockNumber *blknum);
extern bool XLogRecGetBlockTagExtended(XLogReaderState *record, uint8 block_id,
									   RelFileNode *rnode, ForkNumber *forknum,
									   BlockNumber *blknum,
									   Buffer *prefetch_buffer);

#endif							/* XLOGREADER_H */
