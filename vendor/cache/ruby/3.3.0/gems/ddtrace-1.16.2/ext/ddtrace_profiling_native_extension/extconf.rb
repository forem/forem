# rubocop:disable Style/StderrPuts
# rubocop:disable Style/GlobalVars

require_relative 'native_extension_helpers'

SKIPPED_REASON_FILE = "#{__dir__}/skipped_reason.txt".freeze
# Not a problem if the file doesn't exist or we can't delete it
File.delete(SKIPPED_REASON_FILE) rescue nil

def skip_building_extension!(reason)
  fail_install_if_missing_extension =
    Datadog::Profiling::NativeExtensionHelpers.fail_install_if_missing_extension?

  $stderr.puts(
    Datadog::Profiling::NativeExtensionHelpers::Supported.failure_banner_for(
      **reason,
      fail_install: fail_install_if_missing_extension,
    )
  )

  File.write(
    SKIPPED_REASON_FILE,
    Datadog::Profiling::NativeExtensionHelpers::Supported.render_skipped_reason_file(**reason),
  )

  if fail_install_if_missing_extension
    require 'mkmf'
    Logging.message(
      '[ddtrace] Failure cause: ' \
      "#{Datadog::Profiling::NativeExtensionHelpers::Supported.render_skipped_reason_file(**reason)}\n"
    )
  else
    File.write('Makefile', 'all install clean: # dummy makefile that does nothing')
  end

  exit
end

unless Datadog::Profiling::NativeExtensionHelpers::Supported.supported?
  skip_building_extension!(Datadog::Profiling::NativeExtensionHelpers::Supported.unsupported_reason)
end

$stderr.puts(
  %(
+------------------------------------------------------------------------------+
| ** Preparing to build the ddtrace profiling native extension... **           |
|                                                                              |
| If you run into any failures during this step, you can set the               |
| `DD_PROFILING_NO_EXTENSION` environment variable to `true` e.g.              |
| `$ DD_PROFILING_NO_EXTENSION=true bundle install` to skip this step.         |
|                                                                              |
| If you disable this extension, the Datadog Continuous Profiler will          |
| not be available, but all other ddtrace features will work fine!             |
|                                                                              |
| If you needed to use this, please tell us why on                             |
| <https://github.com/DataDog/dd-trace-rb/issues/new> so we can fix it :\)      |
|                                                                              |
| Thanks for using ddtrace! You rock!                                          |
+------------------------------------------------------------------------------+

)
)

# NOTE: we MUST NOT require 'mkmf' before we check the #skip_building_extension? because the require triggers checks
# that may fail on an environment not properly setup for building Ruby extensions.
require 'mkmf'

Logging.message("[ddtrace] Using compiler:\n")
xsystem("#{CONFIG['CC']} -v")
Logging.message("[ddtrace] End of compiler information\n")

# mkmf on modern Rubies actually has an append_cflags that does something similar
# (see https://github.com/ruby/ruby/pull/5760), but as usual we need a bit more boilerplate to deal with legacy Rubies
def add_compiler_flag(flag)
  if try_cflags(flag)
    $CFLAGS << ' ' << flag
  else
    $stderr.puts("WARNING: '#{flag}' not accepted by compiler, skipping it")
  end
end

# Because we can't control what compiler versions our customers use, shipping with -Werror by default is a no-go.
# But we can enable it in CI, so that we quickly spot any new warnings that just got introduced.
#
# @ivoanjo TODO: 3.3.0-preview releases are causing issues in CI because `have_header('vm_core.h')` below triggers warnings;
# I've chosen to disable `-Werror` for this Ruby version for now, and we can revisit this on a later 3.3 release.
add_compiler_flag '-Werror' if ENV['DDTRACE_CI'] == 'true' && !RUBY_DESCRIPTION.include?('3.3.0preview')

# Older gcc releases may not default to C99 and we need to ask for this. This is also used:
# * by upstream Ruby -- search for gnu99 in the codebase
# * by msgpack, another ddtrace dependency
#   (https://github.com/msgpack/msgpack-ruby/blob/18ce08f6d612fe973843c366ac9a0b74c4e50599/ext/msgpack/extconf.rb#L8)
add_compiler_flag '-std=gnu99'

# Gets really noisy when we include the MJIT header, let's omit it (TODO: Use #pragma GCC diagnostic instead?)
add_compiler_flag '-Wno-unused-function'

# Allow defining variables at any point in a function
add_compiler_flag '-Wno-declaration-after-statement'

# If we forget to include a Ruby header, the function call may still appear to work, but then
# cause a segfault later. Let's ensure that never happens.
add_compiler_flag '-Werror-implicit-function-declaration'

# Warn on unused parameters to functions. Use `DDTRACE_UNUSED` to mark things as known-to-not-be-used.
add_compiler_flag '-Wunused-parameter'

# The native extension is not intended to expose any symbols/functions for other native libraries to use;
# the sole exception being `Init_ddtrace_profiling_native_extension` which needs to be visible for Ruby to call it when
# it `dlopen`s the library.
#
# By setting this compiler flag, we tell it to assume that everything is private unless explicitly stated.
# For more details see https://gcc.gnu.org/wiki/Visibility
add_compiler_flag '-fvisibility=hidden'

# Avoid legacy C definitions
add_compiler_flag '-Wold-style-definition'

# Enable all other compiler warnings
add_compiler_flag '-Wall'
add_compiler_flag '-Wextra'

if RUBY_PLATFORM.include?('linux')
  # Supposedly, the correct way to do this is
  # ```
  # have_library 'pthread'
  # have_func 'pthread_getcpuclockid'
  # ```
  # but a) it broke the build on Windows, b) on older Ruby versions (2.2 and below) and c) It's slower to build
  # so instead we just assume that we have the function we need on Linux, and nowhere else
  $defs << '-DHAVE_PTHREAD_GETCPUCLOCKID'
end

# On older Rubies, we did not need to include the ractor header (this was built into the MJIT header)
$defs << '-DNO_RACTOR_HEADER_INCLUDE' if RUBY_VERSION < '3.3'

# On older Rubies, some of the Ractor internal APIs were directly accessible
$defs << '-DUSE_RACTOR_INTERNAL_APIS_DIRECTLY' if RUBY_VERSION < '3.3'

# On older Rubies, there was no struct rb_native_thread. See private_vm_api_acccess.c for details.
$defs << '-DNO_RB_NATIVE_THREAD' if RUBY_VERSION < '3.2'

# On older Rubies, there was no struct rb_thread_sched (it was struct rb_global_vm_lock_struct)
$defs << '-DNO_RB_THREAD_SCHED' if RUBY_VERSION < '3.2'

# On older Rubies, the first_lineno inside a location was a VALUE and not a int (https://github.com/ruby/ruby/pull/6430)
$defs << '-DNO_INT_FIRST_LINENO' if RUBY_VERSION < '3.2'

# On older Rubies, "pop" was not a primitive operation
$defs << '-DNO_PRIMITIVE_POP' if RUBY_VERSION < '3.2'

# On older Rubies, there was no tid member in the internal thread structure
$defs << '-DNO_THREAD_TID' if RUBY_VERSION < '3.1'

# On older Rubies, we need to use a backported version of this function. See private_vm_api_access.h for details.
$defs << '-DUSE_BACKPORTED_RB_PROFILE_FRAME_METHOD_NAME' if RUBY_VERSION < '3'

# On older Rubies, there are no Ractors
$defs << '-DNO_RACTORS' if RUBY_VERSION < '3'

# On older Rubies, objects would not move
$defs << '-DNO_T_MOVED' if RUBY_VERSION < '2.7'

# On older Rubies, rb_global_vm_lock_struct did not include the owner field
$defs << '-DNO_GVL_OWNER' if RUBY_VERSION < '2.6'

# On older Rubies, there was no thread->invoke_arg
$defs << '-DNO_THREAD_INVOKE_ARG' if RUBY_VERSION < '2.6'

# On older Rubies, we need to use rb_thread_t instead of rb_execution_context_t
$defs << '-DUSE_THREAD_INSTEAD_OF_EXECUTION_CONTEXT' if RUBY_VERSION < '2.5'

# On older Rubies, extensions can't use GET_VM()
$defs << '-DNO_GET_VM' if RUBY_VERSION < '2.5'

# On older Rubies...
if RUBY_VERSION < '2.4'
  # ...we need to use RUBY_VM_NORMAL_ISEQ_P instead of VM_FRAME_RUBYFRAME_P
  $defs << '-DUSE_ISEQ_P_INSTEAD_OF_RUBYFRAME_P'
  # ...we use a legacy copy of rb_vm_frame_method_entry
  $defs << '-DUSE_LEGACY_RB_VM_FRAME_METHOD_ENTRY'
end

# If we got here, libdatadog is available and loaded
ENV['PKG_CONFIG_PATH'] = "#{ENV['PKG_CONFIG_PATH']}:#{Libdatadog.pkgconfig_folder}"
Logging.message("[ddtrace] PKG_CONFIG_PATH set to #{ENV['PKG_CONFIG_PATH'].inspect}\n")
$stderr.puts("Using libdatadog #{Libdatadog::VERSION} from #{Libdatadog.pkgconfig_folder}")

unless pkg_config('datadog_profiling_with_rpath')
  Logging.message("[ddtrace] Ruby detected the pkg-config command is #{$PKGCONFIG.inspect}\n")

  skip_building_extension!(
    if Datadog::Profiling::NativeExtensionHelpers::Supported.pkg_config_missing?
      Datadog::Profiling::NativeExtensionHelpers::Supported::PKG_CONFIG_IS_MISSING
    else
      # Less specific error message
      Datadog::Profiling::NativeExtensionHelpers::Supported::FAILED_TO_CONFIGURE_LIBDATADOG
    end
  )
end

unless have_type('atomic_int', ['stdatomic.h'])
  skip_building_extension!(Datadog::Profiling::NativeExtensionHelpers::Supported::COMPILER_ATOMIC_MISSING)
end

# See comments on the helper method being used for why we need to additionally set this.
# The extremely excessive escaping around ORIGIN below seems to be correct and was determined after a lot of
# experimentation. We need to get these special characters across a lot of tools untouched...
$LDFLAGS += \
  ' -Wl,-rpath,$$$\\\\{ORIGIN\\}/' \
  "#{Datadog::Profiling::NativeExtensionHelpers.libdatadog_folder_relative_to_native_lib_folder}"
Logging.message("[ddtrace] After pkg-config $LDFLAGS were set to: #{$LDFLAGS.inspect}\n")

# Tag the native extension library with the Ruby version and Ruby platform.
# This makes it easier for development (avoids "oops I forgot to rebuild when I switched my Ruby") and ensures that
# the wrong library is never loaded.
# When requiring, we need to use the exact same string, including the version and the platform.
EXTENSION_NAME = "ddtrace_profiling_native_extension.#{RUBY_VERSION}_#{RUBY_PLATFORM}".freeze

if Datadog::Profiling::NativeExtensionHelpers::CAN_USE_MJIT_HEADER
  mjit_header_file_name = "rb_mjit_min_header-#{RUBY_VERSION}.h"

  # Validate that the mjit header can actually be compiled on this system. We learned via
  # https://github.com/DataDog/dd-trace-rb/issues/1799 and https://github.com/DataDog/dd-trace-rb/issues/1792
  # that even if the header seems to exist, it may not even compile.
  # `have_macro` actually tries to compile a file that mentions the given macro, so if this passes, we should be good to
  # use the MJIT header.
  # Finally, the `COMMON_HEADERS` conflict with the MJIT header so we need to temporarily disable them for this check.
  original_common_headers = MakeMakefile::COMMON_HEADERS
  MakeMakefile::COMMON_HEADERS = ''.freeze
  unless have_macro('RUBY_MJIT_H', mjit_header_file_name)
    skip_building_extension!(Datadog::Profiling::NativeExtensionHelpers::Supported::COMPILATION_BROKEN)
  end
  MakeMakefile::COMMON_HEADERS = original_common_headers

  $defs << "-DRUBY_MJIT_HEADER='\"#{mjit_header_file_name}\"'"

  # NOTE: This needs to come after all changes to $defs
  create_header

  create_makefile EXTENSION_NAME
else
  # The MJIT header was introduced on 2.6 and removed on 3.3; for other Rubies we rely on
  # the debase-ruby_core_source gem to get access to private VM headers.
  # This gem ships source code copies of these VM headers for the different Ruby VM versions;
  # see https://github.com/ruby-debug/debase-ruby_core_source for details

  create_header

  require 'debase/ruby_core_source'
  dir_config('ruby') # allow user to pass in non-standard core include directory

  Debase::RubyCoreSource
    .create_makefile_with_core(
      proc do
        have_header('vm_core.h') &&
        have_header('iseq.h') &&
        (RUBY_VERSION < '3.3' || have_header('ractor_core.h'))
      end,
      EXTENSION_NAME,
    )
end

# rubocop:enable Style/GlobalVars
# rubocop:enable Style/StderrPuts
