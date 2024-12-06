// Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
// This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2021-Present Datadog, Inc.

#ifndef DDOG_COMMON_H
#define DDOG_COMMON_H

#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#if defined(_MSC_VER)
#define DDOG_CHARSLICE_C(string) \
/* NOTE: Compilation fails if you pass in a char* instead of a literal */ {.ptr = "" string, .len = sizeof(string) - 1}
#else
#define DDOG_CHARSLICE_C(string) \
/* NOTE: Compilation fails if you pass in a char* instead of a literal */ ((ddog_CharSlice){ .ptr = "" string, .len = sizeof(string) - 1 })
#endif

#if defined __GNUC__
#  define DDOG_GNUC_VERSION(major) __GNUC__ >= major
#else
#  define DDOG_GNUC_VERSION(major) (0)
#endif

#if defined __has_attribute
#  define DDOG_HAS_ATTRIBUTE(attribute, major) __has_attribute(attribute)
#else
#  define DDOG_HAS_ATTRIBUTE(attribute, major) DDOG_GNUC_VERSION(major)
#endif

#if defined(__cplusplus) && (__cplusplus >= 201703L)
#  define DDOG_CHECK_RETURN [[nodiscard]]
#elif defined(_Check_return_) /* SAL */
#  define DDOG_CHECK_RETURN _Check_return_
#elif DDOG_HAS_ATTRIBUTE(warn_unused_result, 4)
#  define DDOG_CHECK_RETURN __attribute__((__warn_unused_result__))
#else
#  define DDOG_CHECK_RETURN
#endif

typedef struct ddog_Endpoint ddog_Endpoint;

typedef struct ddog_Tag ddog_Tag;

/**
 * Holds the raw parts of a Rust Vec; it should only be created from Rust,
 * never from C.
 */
typedef struct ddog_Vec_U8 {
  const uint8_t *ptr;
  uintptr_t len;
  uintptr_t capacity;
} ddog_Vec_U8;

/**
 * Please treat this as opaque; do not reach into it, and especially don't
 * write into it! The most relevant APIs are:
 * * `ddog_Error_message`, to get the message as a slice.
 * * `ddog_Error_drop`.
 */
typedef struct ddog_Error {
  /**
   * This is a String stuffed into the vec.
   */
  struct ddog_Vec_U8 message;
} ddog_Error;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_Slice_CChar {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const char *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_Slice_CChar;

typedef struct ddog_Slice_CChar ddog_CharSlice;

/**
 * Holds the raw parts of a Rust Vec; it should only be created from Rust,
 * never from C.
 */
typedef struct ddog_Vec_Tag {
  const struct ddog_Tag *ptr;
  uintptr_t len;
  uintptr_t capacity;
} ddog_Vec_Tag;

typedef enum ddog_Vec_Tag_PushResult_Tag {
  DDOG_VEC_TAG_PUSH_RESULT_OK,
  DDOG_VEC_TAG_PUSH_RESULT_ERR,
} ddog_Vec_Tag_PushResult_Tag;

typedef struct ddog_Vec_Tag_PushResult {
  ddog_Vec_Tag_PushResult_Tag tag;
  union {
    struct {
      struct ddog_Error err;
    };
  };
} ddog_Vec_Tag_PushResult;

typedef struct ddog_Vec_Tag_ParseResult {
  struct ddog_Vec_Tag tags;
  struct ddog_Error *error_message;
} ddog_Vec_Tag_ParseResult;

typedef struct ddog_CancellationToken ddog_CancellationToken;

typedef struct ddog_prof_Exporter ddog_prof_Exporter;

typedef struct ddog_prof_ProfiledEndpointsStats ddog_prof_ProfiledEndpointsStats;

typedef struct ddog_prof_Exporter_Request ddog_prof_Exporter_Request;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_Slice_U8 {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const uint8_t *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_Slice_U8;

/**
 * Use to represent bytes -- does not need to be valid UTF-8.
 */
typedef struct ddog_Slice_U8 ddog_ByteSlice;

typedef struct ddog_prof_Exporter_File {
  ddog_CharSlice name;
  ddog_ByteSlice file;
} ddog_prof_Exporter_File;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_prof_Exporter_Slice_File {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const struct ddog_prof_Exporter_File *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_prof_Exporter_Slice_File;

typedef enum ddog_Endpoint_Tag {
  DDOG_ENDPOINT_AGENT,
  DDOG_ENDPOINT_AGENTLESS,
} ddog_Endpoint_Tag;

typedef struct ddog_Endpoint_ddog_prof_Agentless_Body {
  ddog_CharSlice _0;
  ddog_CharSlice _1;
} ddog_Endpoint_ddog_prof_Agentless_Body;

typedef struct ddog_Endpoint {
  ddog_Endpoint_Tag tag;
  union {
    struct {
      ddog_CharSlice agent;
    };
    ddog_Endpoint_ddog_prof_Agentless_Body AGENTLESS;
  };
} ddog_Endpoint;

typedef enum ddog_prof_Exporter_NewResult_Tag {
  DDOG_PROF_EXPORTER_NEW_RESULT_OK,
  DDOG_PROF_EXPORTER_NEW_RESULT_ERR,
} ddog_prof_Exporter_NewResult_Tag;

typedef struct ddog_prof_Exporter_NewResult {
  ddog_prof_Exporter_NewResult_Tag tag;
  union {
    struct {
      struct ddog_prof_Exporter *ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Exporter_NewResult;

typedef enum ddog_prof_Exporter_Request_BuildResult_Tag {
  DDOG_PROF_EXPORTER_REQUEST_BUILD_RESULT_OK,
  DDOG_PROF_EXPORTER_REQUEST_BUILD_RESULT_ERR,
} ddog_prof_Exporter_Request_BuildResult_Tag;

typedef struct ddog_prof_Exporter_Request_BuildResult {
  ddog_prof_Exporter_Request_BuildResult_Tag tag;
  union {
    struct {
      struct ddog_prof_Exporter_Request *ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Exporter_Request_BuildResult;

/**
 * Represents time since the Unix Epoch in seconds plus nanoseconds.
 */
typedef struct ddog_Timespec {
  int64_t seconds;
  uint32_t nanoseconds;
} ddog_Timespec;

typedef struct ddog_HttpStatus {
  uint16_t code;
} ddog_HttpStatus;

typedef enum ddog_prof_Exporter_SendResult_Tag {
  DDOG_PROF_EXPORTER_SEND_RESULT_HTTP_RESPONSE,
  DDOG_PROF_EXPORTER_SEND_RESULT_ERR,
} ddog_prof_Exporter_SendResult_Tag;

typedef struct ddog_prof_Exporter_SendResult {
  ddog_prof_Exporter_SendResult_Tag tag;
  union {
    struct {
      struct ddog_HttpStatus http_response;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Exporter_SendResult;

/**
 * Represents a profile. Do not access its member for any reason, only use
 * the C API functions on this struct.
 */
typedef struct ddog_prof_Profile {
  struct ddog_prof_Profile *inner;
} ddog_prof_Profile;

/**
 * Returned by [ddog_prof_Profile_new].
 */
typedef enum ddog_prof_Profile_NewResult_Tag {
  DDOG_PROF_PROFILE_NEW_RESULT_OK,
  DDOG_PROF_PROFILE_NEW_RESULT_ERR,
} ddog_prof_Profile_NewResult_Tag;

typedef struct ddog_prof_Profile_NewResult {
  ddog_prof_Profile_NewResult_Tag tag;
  union {
    struct {
      struct ddog_prof_Profile ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Profile_NewResult;

typedef struct ddog_prof_ValueType {
  ddog_CharSlice type_;
  ddog_CharSlice unit;
} ddog_prof_ValueType;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_prof_Slice_ValueType {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const struct ddog_prof_ValueType *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_prof_Slice_ValueType;

typedef struct ddog_prof_Period {
  struct ddog_prof_ValueType type_;
  int64_t value;
} ddog_prof_Period;

/**
 * A generic result type for when a profiling operation may fail, but there's
 * nothing to return in the case of success.
 */
typedef enum ddog_prof_Profile_Result_Tag {
  DDOG_PROF_PROFILE_RESULT_OK,
  DDOG_PROF_PROFILE_RESULT_ERR,
} ddog_prof_Profile_Result_Tag;

typedef struct ddog_prof_Profile_Result {
  ddog_prof_Profile_Result_Tag tag;
  union {
    struct {
      /**
       * Do not use the value of Ok. This value only exists to overcome
       * Rust -> C code generation.
       */
      bool ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Profile_Result;

typedef struct ddog_prof_Mapping {
  /**
   * Address at which the binary (or DLL) is loaded into memory.
   */
  uint64_t memory_start;
  /**
   * The limit of the address range occupied by this mapping.
   */
  uint64_t memory_limit;
  /**
   * Offset in the binary that corresponds to the first mapped address.
   */
  uint64_t file_offset;
  /**
   * The object this entry is loaded from.  This can be a filename on
   * disk for the main binary and shared libraries, or virtual
   * abstractions like "[vdso]".
   */
  ddog_CharSlice filename;
  /**
   * A string that uniquely identifies a particular program version
   * with high probability. E.g., for binaries generated by GNU tools,
   * it could be the contents of the .note.gnu.build-id field.
   */
  ddog_CharSlice build_id;
} ddog_prof_Mapping;

typedef struct ddog_prof_Function {
  /**
   * Name of the function, in human-readable form if available.
   */
  ddog_CharSlice name;
  /**
   * Name of the function, as identified by the system.
   * For instance, it can be a C++ mangled name.
   */
  ddog_CharSlice system_name;
  /**
   * Source file containing the function.
   */
  ddog_CharSlice filename;
  /**
   * Line number in source file.
   */
  int64_t start_line;
} ddog_prof_Function;

typedef struct ddog_prof_Location {
  /**
   * todo: how to handle unknown mapping?
   */
  struct ddog_prof_Mapping mapping;
  struct ddog_prof_Function function;
  /**
   * The instruction address for this location, if available.  It
   * should be within [Mapping.memory_start...Mapping.memory_limit]
   * for the corresponding mapping. A non-leaf address may be in the
   * middle of a call instruction. It is up to display tools to find
   * the beginning of the instruction if necessary.
   */
  uint64_t address;
  int64_t line;
} ddog_prof_Location;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_prof_Slice_Location {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const struct ddog_prof_Location *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_prof_Slice_Location;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_Slice_I64 {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const int64_t *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_Slice_I64;

typedef struct ddog_prof_Label {
  ddog_CharSlice key;
  /**
   * At most one of the following must be present
   */
  ddog_CharSlice str;
  int64_t num;
  /**
   * Should only be present when num is present.
   * Specifies the units of num.
   * Use arbitrary string (for example, "requests") as a custom count unit.
   * If no unit is specified, consumer may apply heuristic to deduce the unit.
   * Consumers may also  interpret units like "bytes" and "kilobytes" as memory
   * units and units like "seconds" and "nanoseconds" as time units,
   * and apply appropriate unit conversions to these.
   */
  ddog_CharSlice num_unit;
} ddog_prof_Label;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_prof_Slice_Label {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const struct ddog_prof_Label *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_prof_Slice_Label;

typedef struct ddog_prof_Sample {
  /**
   * The leaf is at locations[0].
   */
  struct ddog_prof_Slice_Location locations;
  /**
   * The type and unit of each value is defined by the corresponding
   * entry in Profile.sample_type. All samples must have the same
   * number of values, the same as the length of Profile.sample_type.
   * When aggregating multiple samples into a single sample, the
   * result has a list of values that is the element-wise sum of the
   * lists of the originals.
   */
  struct ddog_Slice_I64 values;
  /**
   * label includes additional context for this sample. It can include
   * things like a thread id, allocation size, etc
   */
  struct ddog_prof_Slice_Label labels;
} ddog_prof_Sample;

/**
 * Remember, the data inside of each member is potentially coming from FFI,
 * so every operation on it is unsafe!
 */
typedef struct ddog_prof_Slice_Usize {
  /**
   * Must be non-null and suitably aligned for the underlying type.
   */
  const uintptr_t *ptr;
  /**
   * The number of elements (not bytes) that `.ptr` points to.
   */
  uintptr_t len;
} ddog_prof_Slice_Usize;

typedef struct ddog_prof_EncodedProfile {
  struct ddog_Timespec start;
  struct ddog_Timespec end;
  struct ddog_Vec_U8 buffer;
  struct ddog_prof_ProfiledEndpointsStats *endpoints_stats;
} ddog_prof_EncodedProfile;

typedef enum ddog_prof_Profile_SerializeResult_Tag {
  DDOG_PROF_PROFILE_SERIALIZE_RESULT_OK,
  DDOG_PROF_PROFILE_SERIALIZE_RESULT_ERR,
} ddog_prof_Profile_SerializeResult_Tag;

typedef struct ddog_prof_Profile_SerializeResult {
  ddog_prof_Profile_SerializeResult_Tag tag;
  union {
    struct {
      struct ddog_prof_EncodedProfile ok;
    };
    struct {
      struct ddog_Error err;
    };
  };
} ddog_prof_Profile_SerializeResult;

/**
 * # Safety
 * Only pass null or a valid reference to a `ddog_Error`.
 */
void ddog_Error_drop(struct ddog_Error *error);

/**
 * Returns a CharSlice of the error's message that is valid until the error
 * is dropped.
 * # Safety
 * Only pass null or a valid reference to a `ddog_Error`.
 */
ddog_CharSlice ddog_Error_message(const struct ddog_Error *error);

DDOG_CHECK_RETURN struct ddog_Endpoint *ddog_endpoint_from_url(ddog_CharSlice url);

DDOG_CHECK_RETURN struct ddog_Endpoint *ddog_endpoint_from_api_key(ddog_CharSlice api_key);

DDOG_CHECK_RETURN
struct ddog_Error *ddog_endpoint_from_api_key_and_site(ddog_CharSlice api_key,
                                                       ddog_CharSlice site,
                                                       struct ddog_Endpoint **endpoint);

void ddog_endpoint_drop(struct ddog_Endpoint*);

DDOG_CHECK_RETURN struct ddog_Vec_Tag ddog_Vec_Tag_new(void);

void ddog_Vec_Tag_drop(struct ddog_Vec_Tag);

/**
 * Creates a new Tag from the provided `key` and `value` by doing a utf8
 * lossy conversion, and pushes into the `vec`. The strings `key` and `value`
 * are cloned to avoid FFI lifetime issues.
 *
 * # Safety
 * The `vec` must be a valid reference.
 * The CharSlices `key` and `value` must point to at least many bytes as their
 * `.len` properties claim.
 */
DDOG_CHECK_RETURN
struct ddog_Vec_Tag_PushResult ddog_Vec_Tag_push(struct ddog_Vec_Tag *vec,
                                                 ddog_CharSlice key,
                                                 ddog_CharSlice value);

/**
 * # Safety
 * The `string`'s .ptr must point to a valid object at least as large as its
 * .len property.
 */
DDOG_CHECK_RETURN struct ddog_Vec_Tag_ParseResult ddog_Vec_Tag_parse(ddog_CharSlice string);

#endif /* DDOG_COMMON_H */
