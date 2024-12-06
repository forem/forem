#pragma once

#include <ruby.h>
#include <stdbool.h>

#include "helpers.h"

// Processes any pending interruptions, including exceptions to be raised.
// If there's an exception to be raised, it raises it. In that case, this function does not return.
static inline VALUE process_pending_interruptions(DDTRACE_UNUSED VALUE _) {
  rb_thread_check_ints();
  return Qnil;
}

// RB_UNLIKELY is not supported on Ruby 2.3
#ifndef RB_UNLIKELY
  #define RB_UNLIKELY(x) x
#endif

// Calls process_pending_interruptions BUT "rescues" any exceptions to be raised, returning them instead as
// a non-zero `pending_exception`.
//
// Thus, if there's a non-zero `pending_exception`, the caller MUST call `rb_jump_tag(pending_exception)` after any
// needed clean-ups.
//
// Usage example:
//
// ```c
// foo = ruby_xcalloc(...);
// pending_exception = check_if_pending_exception();
// if (pending_exception) {
//   ruby_xfree(foo);
//   rb_jump_tag(pending_exception); // Re-raises exception
// }
// ```
__attribute__((warn_unused_result))
static inline int check_if_pending_exception(void) {
  int pending_exception;
  rb_protect(process_pending_interruptions, Qnil, &pending_exception);
  return pending_exception;
}

#define ADD_QUOTES_HELPER(x) #x
#define ADD_QUOTES(x) ADD_QUOTES_HELPER(x)

// Ruby has a Check_Type(value, type) that is roughly equivalent to this BUT Ruby's version is rather cryptic when it fails
// e.g. "wrong argument type nil (expected String)". This is a replacement that prints more information to help debugging.
#define ENFORCE_TYPE(value, type) \
  { if (RB_UNLIKELY(!RB_TYPE_P(value, type))) raise_unexpected_type(value, ADD_QUOTES(value), ADD_QUOTES(type), __FILE__, __LINE__, __func__); }

#define ENFORCE_BOOLEAN(value) \
  { if (RB_UNLIKELY(value != Qtrue && value != Qfalse)) raise_unexpected_type(value, ADD_QUOTES(value), "true or false", __FILE__, __LINE__, __func__); }

// Called by ENFORCE_TYPE; should not be used directly
NORETURN(void raise_unexpected_type(
  VALUE value,
  const char *value_name,
  const char *type_name,
  const char *file,
  int line,
  const char *function_name
));

#define VALUE_COUNT(array) (sizeof(array) / sizeof(VALUE))

NORETURN(
  void grab_gvl_and_raise(VALUE exception_class, const char *format_string, ...)
  __attribute__ ((format (printf, 2, 3)));
);
NORETURN(
  void grab_gvl_and_raise_syserr(int syserr_errno, const char *format_string, ...)
  __attribute__ ((format (printf, 2, 3)));
);

#define ENFORCE_SUCCESS_GVL(expression) ENFORCE_SUCCESS_HELPER(expression, true)
#define ENFORCE_SUCCESS_NO_GVL(expression) ENFORCE_SUCCESS_HELPER(expression, false)

#define ENFORCE_SUCCESS_HELPER(expression, have_gvl) \
  { int result_syserr_errno = expression; if (RB_UNLIKELY(result_syserr_errno)) raise_syserr(result_syserr_errno, have_gvl, ADD_QUOTES(expression), __FILE__, __LINE__, __func__); }

// Called by ENFORCE_SUCCESS_HELPER; should not be used directly
NORETURN(void raise_syserr(
  int syserr_errno,
  bool have_gvl,
  const char *expression,
  const char *file,
  int line,
  const char *function_name
));
