# rubocop:disable Style/GlobalVars

require 'digest'
require 'mkmf'
require 'open-uri'
require 'pathname'

$objs = Dir.glob(File.join(__dir__, '*.c')).map { |f| Pathname.new(f).sub_ext('.o').to_s }

# -Wno-deprecated-non-prototype avoids warnings on Clang 15.0+, this can be removed in Postgres 16:
# https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=1c27d16e6e5c1f463bbe1e9ece88dda811235165
$CFLAGS << " -fvisibility=hidden -O3 -Wall -fno-strict-aliasing -fwrapv -fstack-protector -Wno-unused-function -Wno-unused-variable -Wno-clobbered -Wno-sign-compare -Wno-discarded-qualifiers  -Wno-deprecated-non-prototype -Wno-unknown-warning-option -g"

$INCFLAGS = "-I#{File.join(__dir__, 'include')} " + $INCFLAGS

SYMFILE =
  if RUBY_PLATFORM =~ /freebsd/
    File.join(__dir__, 'pg_query_ruby_freebsd.sym')
  else
    File.join(__dir__, 'pg_query_ruby.sym')
  end

if RUBY_PLATFORM =~ /darwin/
  $DLDFLAGS << " -Wl,-exported_symbols_list #{SYMFILE}" unless defined?(::Rubinius)
else
  $DLDFLAGS << " -Wl,--retain-symbols-file=#{SYMFILE}"
end

create_makefile 'pg_query/pg_query'
