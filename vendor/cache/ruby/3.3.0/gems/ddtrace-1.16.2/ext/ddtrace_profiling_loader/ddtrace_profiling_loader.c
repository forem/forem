#include <stdbool.h>
#include <dlfcn.h>
#include <ruby.h>

// Why this exists:
//
// The Datadog::Profiling::Loader exists because when Ruby loads a native extension (using `require`), it uses
// `dlopen(..., RTLD_LAZY | RTLD_GLOBAL)` (https://github.com/ruby/ruby/blob/67950a4c0a884bdb78d9beb4405ebf7459229b21/dln.c#L362).
// This means that every symbol exposed directly or indirectly by that native extension becomes visible to every other
// extension in the Ruby process. This can cause issues, see https://github.com/rubyjs/mini_racer/pull/179.
//
// Instead of `RTLD_LAZY | RTLD_GLOBAL`, we want to call `dlopen` with `RTLD_LAZY | RTLD_LOCAL | RTLD_DEEPBIND` when
// loading the profiling native extension, to avoid leaking any unintended symbols (`RTLD_LOCAL`) and avoid picking
// up other's symbols (`RTLD_DEEPBIND`).
//
// But Ruby's extension loading mechanism is not configurable -- there's no way to tell it to use different flags when
// calling `dlopen`. To get around this, this file (ddtrace_profiling_loader.c) introduces another extension
// (profiling loader) which has only a single responsibility: mimic Ruby's extension loading mechanism, but when calling
// `dlopen` use a different set of flags.
// This idea was shamelessly stolen from @lloeki's work in https://github.com/rubyjs/mini_racer/pull/179, big thanks!
//
// Extra note: Currently (May 2022), that we know of, the profiling native extension only exposes one potentially
// problematic symbol: `rust_eh_personality` (coming from libdatadog).
// Future versions of Rust have been patched not to expose this
// (see https://github.com/rust-lang/rust/pull/95604#issuecomment-1108563434) so we may want to revisit the need
// for this loader in the future, and perhaps delete it if we no longer require its services :)

#ifndef RTLD_DEEPBIND
  #define RTLD_DEEPBIND 0
#endif

// Used to mark function arguments that are deliberately left unused
#ifdef __GNUC__
  #define DDTRACE_UNUSED  __attribute__((unused))
#else
  #define DDTRACE_UNUSED
#endif

static VALUE ok_symbol = Qnil; // :ok in Ruby
static VALUE error_symbol = Qnil; // :error in Ruby

static VALUE _native_load(DDTRACE_UNUSED VALUE self, VALUE ruby_path, VALUE ruby_init_name);
static bool failed_to_load(void *handle, VALUE *failure_details);
static bool incompatible_library(void *handle, VALUE *failure_details);
static bool failed_to_initialize(void *handle, char *init_name, VALUE *failure_details);
static void set_failure_from_dlerror(VALUE *failure_details);
static void unload_failed_library(void *handle);

#define DDTRACE_EXPORT __attribute__ ((visibility ("default")))

void DDTRACE_EXPORT Init_ddtrace_profiling_loader(void) {
  VALUE datadog_module = rb_define_module("Datadog");
  VALUE profiling_module = rb_define_module_under(datadog_module, "Profiling");
  VALUE loader_module = rb_define_module_under(profiling_module, "Loader");
  rb_define_singleton_method(loader_module, "_native_load", _native_load, 2);

  ok_symbol = ID2SYM(rb_intern_const("ok"));
  error_symbol = ID2SYM(rb_intern_const("error"));
}

static VALUE _native_load(DDTRACE_UNUSED VALUE self, VALUE ruby_path, VALUE ruby_init_name) {
  Check_Type(ruby_path, T_STRING);
  Check_Type(ruby_init_name, T_STRING);

  char *path = StringValueCStr(ruby_path);
  char *init_name = StringValueCStr(ruby_init_name);

  void *handle = dlopen(path, RTLD_LAZY | RTLD_LOCAL | RTLD_DEEPBIND);

  VALUE failure_details = Qnil;

  if (
    failed_to_load(handle, &failure_details) ||
    incompatible_library(handle, &failure_details) ||
    failed_to_initialize(handle, init_name, &failure_details)
  ) {
    return rb_ary_new_from_args(2, error_symbol, failure_details);
  }

  return rb_ary_new_from_args(2, ok_symbol, Qnil);
}

static bool failed_to_load(void *handle, VALUE *failure_details) {
  if (handle == NULL) {
    set_failure_from_dlerror(failure_details);
    return true;
  } else {
    return false;
  }
}

static bool incompatible_library(void *handle, VALUE *failure_details) {
  // The library being loaded may be linked to a different libruby than the current executing Ruby.
  // We check if this is the case by checking if a well-known symbol resolves to a common address.

  void *xmalloc_from_library = dlsym(handle, "ruby_xmalloc");

  if (xmalloc_from_library == NULL) {
    // This happens when ruby is built without a `libruby.so` by using `--disable-shared` at compilation time.
    // In this situation, no conflict between libruby version is possible.
    return false;
  }

  if (xmalloc_from_library != &ruby_xmalloc) {
    *failure_details = rb_str_new_cstr("library was compiled and linked to a different Ruby version");
    unload_failed_library(handle);
    return true;
  } else {
    return false;
  }
}

static bool failed_to_initialize(void *handle, char *init_name, VALUE *failure_details) {
  void (*initialization_function)(void) = dlsym(handle, init_name);

  if (initialization_function == NULL) {
    set_failure_from_dlerror(failure_details);
    unload_failed_library(handle);
    return true;
  } else {
    (*initialization_function)();
    return false;
  }
}

static void set_failure_from_dlerror(VALUE *failure_details) {
  char *failure = dlerror();
  *failure_details = failure == NULL ? Qnil : rb_str_new_cstr(failure);
}

static void unload_failed_library(void *handle) {
  // Note: According to the Ruby VM sources, this may fail with a segfault on really old versions of macOS (< 10.11)
  dlclose(handle);
}
