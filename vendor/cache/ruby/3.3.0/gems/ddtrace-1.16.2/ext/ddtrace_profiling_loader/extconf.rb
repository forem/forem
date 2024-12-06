# rubocop:disable Style/StderrPuts
# rubocop:disable Style/GlobalVars

if RUBY_ENGINE != 'ruby' || Gem.win_platform?
  $stderr.puts(
    'WARN: Skipping build of ddtrace profiling loader. See ddtrace profiling native extension note for details.'
  )

  File.write('Makefile', 'all install clean: # dummy makefile that does nothing')
  exit
end

require 'mkmf'

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
add_compiler_flag '-Werror' if ENV['DDTRACE_CI'] == 'true'

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
# the sole exception being `Init_ddtrace_profiling_loader` which needs to be visible for Ruby to call it when
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

# Tag the native extension library with the Ruby version and Ruby platform.
# This makes it easier for development (avoids "oops I forgot to rebuild when I switched my Ruby") and ensures that
# the wrong library is never loaded.
# When requiring, we need to use the exact same string, including the version and the platform.
EXTENSION_NAME = "ddtrace_profiling_loader.#{RUBY_VERSION}_#{RUBY_PLATFORM}".freeze

create_makefile(EXTENSION_NAME)

# rubocop:enable Style/GlobalVars
# rubocop:enable Style/StderrPuts
