
SHELL = /bin/sh

# V=0 quiet, V=1 verbose.  other values don't work.
V = 0
V0 = $(V:0=)
Q1 = $(V:1=)
Q = $(Q1:0=@)
ECHO1 = $(V:1=@ :)
ECHO = $(ECHO1:0=@ echo)
NULLCMD = :

#### Start of system configuration section. ####

srcdir = .
topdir = /home/organicelectronics/.rbenv/versions/3.3.0/include/ruby-3.3.0
hdrdir = $(topdir)
arch_hdrdir = /home/organicelectronics/.rbenv/versions/3.3.0/include/ruby-3.3.0/x86_64-linux
PATH_SEPARATOR = :
VPATH = $(srcdir):$(arch_hdrdir)/ruby:$(hdrdir)/ruby
prefix = $(DESTDIR)/home/organicelectronics/.rbenv/versions/3.3.0
rubysitearchprefix = $(rubylibprefix)/$(sitearch)
rubyarchprefix = $(rubylibprefix)/$(arch)
rubylibprefix = $(libdir)/$(RUBY_BASE_NAME)
exec_prefix = $(prefix)
vendorarchhdrdir = $(vendorhdrdir)/$(sitearch)
sitearchhdrdir = $(sitehdrdir)/$(sitearch)
rubyarchhdrdir = $(rubyhdrdir)/$(arch)
vendorhdrdir = $(rubyhdrdir)/vendor_ruby
sitehdrdir = $(rubyhdrdir)/site_ruby
rubyhdrdir = $(includedir)/$(RUBY_VERSION_NAME)
vendorarchdir = $(vendorlibdir)/$(sitearch)
vendorlibdir = $(vendordir)/$(ruby_version)
vendordir = $(rubylibprefix)/vendor_ruby
sitearchdir = $(sitelibdir)/$(sitearch)
sitelibdir = $(sitedir)/$(ruby_version)
sitedir = $(rubylibprefix)/site_ruby
rubyarchdir = $(rubylibdir)/$(arch)
rubylibdir = $(rubylibprefix)/$(ruby_version)
sitearchincludedir = $(includedir)/$(sitearch)
archincludedir = $(includedir)/$(arch)
sitearchlibdir = $(libdir)/$(sitearch)
archlibdir = $(libdir)/$(arch)
ridir = $(datarootdir)/$(RI_BASE_NAME)
mandir = $(datarootdir)/man
localedir = $(datarootdir)/locale
libdir = $(exec_prefix)/lib
psdir = $(docdir)
pdfdir = $(docdir)
dvidir = $(docdir)
htmldir = $(docdir)
infodir = $(datarootdir)/info
docdir = $(datarootdir)/doc/$(PACKAGE)
oldincludedir = $(DESTDIR)/usr/include
includedir = $(prefix)/include
runstatedir = $(localstatedir)/run
localstatedir = $(prefix)/var
sharedstatedir = $(prefix)/com
sysconfdir = $(prefix)/etc
datadir = $(datarootdir)
datarootdir = $(prefix)/share
libexecdir = $(exec_prefix)/libexec
sbindir = $(exec_prefix)/sbin
bindir = $(exec_prefix)/bin
archdir = $(rubyarchdir)


CC_WRAPPER = 
CC = gcc
CXX = g++
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -Wl,-rpath,$(libdir) -L$(libdir) -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -Wl,-rpath,$(libdir) -L$(libdir) -l$(RUBY_SO_NAME)-static $(MAINLIBS)
empty =
OUTFLAG = -o $(empty)
COUTFLAG = -o $(empty)
CSRCFLAG = $(empty)

RUBY_EXTCONF_H = 
cflags   = $(optflags) $(debugflags) $(warnflags)
cxxflags = 
optflags = -O3 -fno-fast-math
debugflags = -ggdb3
warnflags = -Wall -Wextra -Wdeprecated-declarations -Wdiv-by-zero -Wduplicated-cond -Wimplicit-function-declaration -Wimplicit-int -Wpointer-arith -Wwrite-strings -Wold-style-definition -Wimplicit-fallthrough=0 -Wmissing-noreturn -Wno-cast-function-type -Wno-constant-logical-operand -Wno-long-long -Wno-missing-field-initializers -Wno-overlength-strings -Wno-packed-bitfield-compat -Wno-parentheses-equality -Wno-self-assign -Wno-tautological-compare -Wno-unused-parameter -Wno-unused-value -Wsuggest-attribute=format -Wsuggest-attribute=noreturn -Wunused-variable -Wmisleading-indentation -Wundef
cppflags = 
CCDLFLAGS = -fPIC
CFLAGS   = $(CCDLFLAGS) $(cflags)  -fPIC -fvisibility=hidden -O3 -Wall -fno-strict-aliasing -fwrapv -fstack-protector -Wno-unused-function -Wno-unused-variable -Wno-clobbered -Wno-sign-compare -Wno-discarded-qualifiers  -Wno-deprecated-non-prototype -Wno-unknown-warning-option -g $(ARCH_FLAG)
INCFLAGS = -I. -I/home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/include -I$(arch_hdrdir) -I$(hdrdir)/ruby/backward -I$(hdrdir) -I$(srcdir)
DEFS     = 
CPPFLAGS =   $(DEFS) $(cppflags)
CXXFLAGS = $(CCDLFLAGS)  $(ARCH_FLAG)
ldflags  = -L. -fstack-protector-strong -rdynamic -Wl,-export-dynamic -Wl,--no-as-needed
dldflags = -Wl,--compress-debug-sections=zlib -Wl,--retain-symbols-file=/home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_ruby.sym 
ARCH_FLAG = 
DLDFLAGS = $(ldflags) $(dldflags) $(ARCH_FLAG)
LDSHARED = $(CC) -shared
LDSHAREDXX = $(CXX) -shared
AR = gcc-ar
EXEEXT = 

RUBY_INSTALL_NAME = $(RUBY_BASE_NAME)
RUBY_SO_NAME = ruby
RUBYW_INSTALL_NAME = 
RUBY_VERSION_NAME = $(RUBY_BASE_NAME)-$(ruby_version)
RUBYW_BASE_NAME = rubyw
RUBY_BASE_NAME = ruby

arch = x86_64-linux
sitearch = $(arch)
ruby_version = 3.3.0
ruby = $(bindir)/$(RUBY_BASE_NAME)
RUBY = $(ruby)
BUILTRUBY = $(bindir)/$(RUBY_BASE_NAME)
ruby_headers = $(hdrdir)/ruby.h $(hdrdir)/ruby/backward.h $(hdrdir)/ruby/ruby.h $(hdrdir)/ruby/defines.h $(hdrdir)/ruby/missing.h $(hdrdir)/ruby/intern.h $(hdrdir)/ruby/st.h $(hdrdir)/ruby/subst.h $(arch_hdrdir)/ruby/config.h

RM = rm -f
RM_RF = rm -fr
RMDIRS = rmdir --ignore-fail-on-non-empty -p
MAKEDIRS = /usr/bin/mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp
TOUCH = exit >

#### End of system configuration section. ####

preload = 
libpath = . $(libdir)
LIBPATH =  -L. -L$(libdir) -Wl,-rpath,$(libdir)
DEFFILE = 

CLEANFILES = mkmf.log
DISTCLEANFILES = 
DISTCLEANDIRS = 

extout = 
extout_prefix = 
target_prefix = /pg_query
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED)  -lm -lpthread  -lc
ORIG_SRCS = guc-file.c pg_query.c pg_query.pb-c.c pg_query_deparse.c pg_query_fingerprint.c pg_query_json_plpgsql.c pg_query_normalize.c pg_query_outfuncs_json.c pg_query_outfuncs_protobuf.c pg_query_parse.c pg_query_parse_plpgsql.c pg_query_readfuncs_protobuf.c pg_query_ruby.c pg_query_scan.c pg_query_split.c postgres_deparse.c protobuf-c.c src_backend_catalog_namespace.c src_backend_catalog_pg_proc.c src_backend_commands_define.c src_backend_nodes_bitmapset.c src_backend_nodes_copyfuncs.c src_backend_nodes_equalfuncs.c src_backend_nodes_extensible.c src_backend_nodes_list.c src_backend_nodes_makefuncs.c src_backend_nodes_nodeFuncs.c src_backend_nodes_value.c src_backend_parser_gram.c src_backend_parser_parser.c src_backend_parser_scan.c src_backend_parser_scansup.c src_backend_postmaster_postmaster.c src_backend_storage_ipc_ipc.c src_backend_storage_lmgr_s_lock.c src_backend_tcop_postgres.c src_backend_utils_activity_pgstat_database.c src_backend_utils_adt_datum.c src_backend_utils_adt_expandeddatum.c src_backend_utils_adt_format_type.c src_backend_utils_adt_ruleutils.c src_backend_utils_error_assert.c src_backend_utils_error_elog.c src_backend_utils_fmgr_fmgr.c src_backend_utils_hash_dynahash.c src_backend_utils_init_globals.c src_backend_utils_mb_mbutils.c src_backend_utils_misc_guc.c src_backend_utils_mmgr_aset.c src_backend_utils_mmgr_mcxt.c src_common_encnames.c src_common_hashfn.c src_common_keywords.c src_common_kwlookup.c src_common_pg_prng.c src_common_psprintf.c src_common_string.c src_common_stringinfo.c src_common_wchar.c src_pl_plpgsql_src_pl_comp.c src_pl_plpgsql_src_pl_funcs.c src_pl_plpgsql_src_pl_gram.c src_pl_plpgsql_src_pl_handler.c src_pl_plpgsql_src_pl_scanner.c src_port_pg_bitutils.c src_port_pgsleep.c src_port_pgstrcasecmp.c src_port_qsort.c src_port_snprintf.c src_port_strerror.c src_port_strnlen.c xxhash.c
SRCS = $(ORIG_SRCS) guc-file.c pg_query.c pg_query.pb-c.c pg_query_deparse.c pg_query_fingerprint.c pg_query_json_plpgsql.c pg_query_normalize.c pg_query_outfuncs_json.c pg_query_outfuncs_protobuf.c pg_query_parse.c pg_query_parse_plpgsql.c pg_query_readfuncs_protobuf.c pg_query_ruby.c pg_query_scan.c pg_query_split.c postgres_deparse.c protobuf-c.c src_backend_catalog_namespace.c src_backend_catalog_pg_proc.c src_backend_commands_define.c src_backend_nodes_bitmapset.c src_backend_nodes_copyfuncs.c src_backend_nodes_equalfuncs.c src_backend_nodes_extensible.c src_backend_nodes_list.c src_backend_nodes_makefuncs.c src_backend_nodes_nodeFuncs.c src_backend_nodes_value.c src_backend_parser_gram.c src_backend_parser_parser.c src_backend_parser_scan.c src_backend_parser_scansup.c src_backend_postmaster_postmaster.c src_backend_storage_ipc_ipc.c src_backend_storage_lmgr_s_lock.c src_backend_tcop_postgres.c src_backend_utils_activity_pgstat_database.c src_backend_utils_adt_datum.c src_backend_utils_adt_expandeddatum.c src_backend_utils_adt_format_type.c src_backend_utils_adt_ruleutils.c src_backend_utils_error_assert.c src_backend_utils_error_elog.c src_backend_utils_fmgr_fmgr.c src_backend_utils_hash_dynahash.c src_backend_utils_init_globals.c src_backend_utils_mb_mbutils.c src_backend_utils_misc_guc.c src_backend_utils_mmgr_aset.c src_backend_utils_mmgr_mcxt.c src_common_encnames.c src_common_hashfn.c src_common_keywords.c src_common_kwlookup.c src_common_pg_prng.c src_common_psprintf.c src_common_string.c src_common_stringinfo.c src_common_wchar.c src_pl_plpgsql_src_pl_comp.c src_pl_plpgsql_src_pl_funcs.c src_pl_plpgsql_src_pl_gram.c src_pl_plpgsql_src_pl_handler.c src_pl_plpgsql_src_pl_scanner.c src_port_pg_bitutils.c src_port_pgsleep.c src_port_pgstrcasecmp.c src_port_qsort.c src_port_snprintf.c src_port_strerror.c src_port_strnlen.c xxhash.c
OBJS = /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/guc-file.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query.pb-c.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_deparse.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_fingerprint.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_json_plpgsql.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_normalize.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_outfuncs_json.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_outfuncs_protobuf.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_parse.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_parse_plpgsql.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_readfuncs_protobuf.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_ruby.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_scan.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/pg_query_split.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/postgres_deparse.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/protobuf-c.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_catalog_namespace.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_catalog_pg_proc.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_commands_define.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_bitmapset.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_copyfuncs.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_equalfuncs.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_extensible.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_list.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_makefuncs.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_nodeFuncs.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_nodes_value.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_parser_gram.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_parser_parser.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_parser_scan.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_parser_scansup.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_postmaster_postmaster.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_storage_ipc_ipc.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_storage_lmgr_s_lock.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_tcop_postgres.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_activity_pgstat_database.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_adt_datum.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_adt_expandeddatum.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_adt_format_type.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_adt_ruleutils.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_error_assert.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_error_elog.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_fmgr_fmgr.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_hash_dynahash.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_init_globals.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_mb_mbutils.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_misc_guc.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_mmgr_aset.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_backend_utils_mmgr_mcxt.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_encnames.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_hashfn.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_keywords.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_kwlookup.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_pg_prng.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_psprintf.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_string.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_stringinfo.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_common_wchar.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_pl_plpgsql_src_pl_comp.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_pl_plpgsql_src_pl_funcs.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_pl_plpgsql_src_pl_gram.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_pl_plpgsql_src_pl_handler.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_pl_plpgsql_src_pl_scanner.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_pg_bitutils.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_pgsleep.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_pgstrcasecmp.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_qsort.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_snprintf.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_strerror.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/src_port_strnlen.o /home/organicelectronics/forem/vendor/cache/ruby/3.3.0/gems/pg_query-4.2.3/ext/pg_query/xxhash.o
HDRS = $(srcdir)/pg_query_fingerprint.h $(srcdir)/pg_query_internal.h $(srcdir)/pg_query_json_plpgsql.h $(srcdir)/pg_query_outfuncs.h $(srcdir)/pg_query_readfuncs.h $(srcdir)/postgres_deparse.h $(srcdir)/src_common_kwlist_d.h $(srcdir)/src_pl_plpgsql_src_pl_reserved_kwlist_d.h $(srcdir)/src_pl_plpgsql_src_pl_unreserved_kwlist_d.h
LOCAL_HDRS = 
TARGET = pg_query
TARGET_NAME = pg_query
TARGET_ENTRY = Init_$(TARGET_NAME)
DLLIB = $(TARGET).so
EXTSTATIC = 
STATIC_LIB = 

TIMESTAMP_DIR = .
BINDIR        = $(bindir)
RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)
HDRDIR        = $(sitehdrdir)$(target_prefix)
ARCHHDRDIR    = $(sitearchhdrdir)$(target_prefix)
TARGET_SO_DIR =
TARGET_SO     = $(TARGET_SO_DIR)$(DLLIB)
CLEANLIBS     = $(TARGET_SO) false
CLEANOBJS     = $(OBJS) *.bak
TARGET_SO_DIR_TIMESTAMP = $(TIMESTAMP_DIR)/.sitearchdir.-.pg_query.time

all:    $(DLLIB)
static: $(STATIC_LIB)
.PHONY: all install static install-so install-rb
.PHONY: clean clean-so clean-static clean-rb

clean-static::
clean-rb-default::
clean-rb::
clean-so::
clean: clean-so clean-static clean-rb-default clean-rb
		-$(Q)$(RM_RF) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES) .*.time

distclean-rb-default::
distclean-rb::
distclean-so::
distclean-static::
distclean: clean distclean-so distclean-static distclean-rb-default distclean-rb
		-$(Q)$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
		-$(Q)$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)
		-$(Q)$(RMDIRS) $(DISTCLEANDIRS) 2> /dev/null || true

realclean: distclean
install: install-so install-rb

install-so: $(DLLIB) $(TARGET_SO_DIR_TIMESTAMP)
	$(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
clean-static::
	-$(Q)$(RM) $(STATIC_LIB)
install-rb: pre-install-rb do-install-rb install-rb-default
install-rb-default: pre-install-rb-default do-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
do-install-rb:
do-install-rb-default:
pre-install-rb-default:
	@$(NULLCMD)
$(TARGET_SO_DIR_TIMESTAMP):
	$(Q) $(MAKEDIRS) $(@D) $(RUBYARCHDIR)
	$(Q) $(TOUCH) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .mm .cxx .cpp .o .S

.cc.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cc.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.mm.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.mm.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.cxx.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cxx.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.cpp.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.cpp.S:
	$(ECHO) translating $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.c.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.c.S:
	$(ECHO) translating $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

.m.o:
	$(ECHO) compiling $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<

.m.S:
	$(ECHO) translating $(<)
	$(Q) $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(COUTFLAG)$@ -S $(CSRCFLAG)$<

$(TARGET_SO): $(OBJS) Makefile
	$(ECHO) linking shared-object pg_query/$(DLLIB)
	-$(Q)$(RM) $(@)
	$(Q) $(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)



$(OBJS): $(HDRS) $(ruby_headers)
