#include <ruby.h>
#include <ruby/thread.h>

#include "ruby_helpers.h"
#include "private_vm_api_access.h"

void raise_unexpected_type(
  VALUE value,
  const char *value_name,
  const char *type_name,
  const char *file,
  int line,
  const char* function_name
) {
  rb_exc_raise(
    rb_exc_new_str(
      rb_eTypeError,
      rb_sprintf("wrong argument %"PRIsVALUE" for '%s' (expected a %s) at %s:%d:in `%s'",
        rb_inspect(value),
        value_name,
        type_name,
        file,
        line,
        function_name
      )
    )
  );
}

#define MAX_RAISE_MESSAGE_SIZE 256

struct raise_arguments {
  VALUE exception_class;
  char exception_message[MAX_RAISE_MESSAGE_SIZE];
};

static void *trigger_raise(void *raise_arguments) {
  struct raise_arguments *args = (struct raise_arguments *) raise_arguments;
  rb_raise(args->exception_class, "%s", args->exception_message);
}

void grab_gvl_and_raise(VALUE exception_class, const char *format_string, ...) {
  struct raise_arguments args;

  args.exception_class = exception_class;

  va_list format_string_arguments;
  va_start(format_string_arguments, format_string);
  vsnprintf(args.exception_message, MAX_RAISE_MESSAGE_SIZE, format_string, format_string_arguments);

  if (is_current_thread_holding_the_gvl()) {
    rb_raise(
      rb_eRuntimeError,
      "grab_gvl_and_raise called by thread holding the global VM lock. exception_message: '%s'",
      args.exception_message
    );
  }

  rb_thread_call_with_gvl(trigger_raise, &args);

  rb_bug("[ddtrace] Unexpected: Reached the end of grab_gvl_and_raise while raising '%s'\n", args.exception_message);
}

struct syserr_raise_arguments {
  int syserr_errno;
  char exception_message[MAX_RAISE_MESSAGE_SIZE];
};

static void *trigger_syserr_raise(void *syserr_raise_arguments) {
  struct syserr_raise_arguments *args = (struct syserr_raise_arguments *) syserr_raise_arguments;
  rb_syserr_fail(args->syserr_errno, args->exception_message);
}

void grab_gvl_and_raise_syserr(int syserr_errno, const char *format_string, ...) {
  struct syserr_raise_arguments args;

  args.syserr_errno = syserr_errno;

  va_list format_string_arguments;
  va_start(format_string_arguments, format_string);
  vsnprintf(args.exception_message, MAX_RAISE_MESSAGE_SIZE, format_string, format_string_arguments);

  if (is_current_thread_holding_the_gvl()) {
    rb_raise(
      rb_eRuntimeError,
      "grab_gvl_and_raise_syserr called by thread holding the global VM lock. syserr_errno: %d, exception_message: '%s'",
      syserr_errno,
      args.exception_message
    );
  }

  rb_thread_call_with_gvl(trigger_syserr_raise, &args);

  rb_bug("[ddtrace] Unexpected: Reached the end of grab_gvl_and_raise_syserr while raising '%s'\n", args.exception_message);
}

void raise_syserr(
  int syserr_errno,
  bool have_gvl,
  const char *expression,
  const char *file,
  int line,
  const char *function_name
) {
  if (have_gvl) {
    rb_exc_raise(rb_syserr_new_str(syserr_errno, rb_sprintf("Failure returned by '%s' at %s:%d:in `%s'", expression, file, line, function_name)));
  } else {
    grab_gvl_and_raise_syserr(syserr_errno, "Failure returned by '%s' at %s:%d:in `%s'", expression, file, line, function_name);
  }
}
