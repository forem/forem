require 'mkmf'

IS_MSWIN = !RbConfig::CONFIG['host_os'].match(/mswin/).nil?
IS_MINGW = !RbConfig::CONFIG['host_os'].match(/mingw/).nil?
IS_DARWIN = !RbConfig::CONFIG['host_os'].match(/darwin/).nil?

# If we are on versions of Ruby before 2.7 then we need to copy in the experimental C++ support
# added in Ruby 2.7
unless MakeMakefile.methods.include?(:[])

  # Ruby 2.6 makes this declaration which is not valid with C++17
  # void rb_mem_clear(register VALUE*, register long);
  if !IS_MSWIN
    $CXXFLAGS += " " << "-Wno-register"
  end

  MakeMakefile::CONFTEST_C = "#{CONFTEST}.cc"

  MakeMakefile.module_eval do
    CONFTEST_C = "#{CONFTEST}.cc"
    def cc_config(opt="")
      conf = RbConfig::CONFIG.merge('hdrdir' => $hdrdir.quote, 'srcdir' => $srcdir.quote,
                                    'arch_hdrdir' => $arch_hdrdir.quote,
                                    'top_srcdir' => $top_srcdir.quote)
      conf
    end

    def link_config(ldflags, opt="", libpath=$DEFLIBPATH|$LIBPATH)
      librubyarg = $extmk ? $LIBRUBYARG_STATIC : "$(LIBRUBYARG)"
      conf = RbConfig::CONFIG.merge('hdrdir' => $hdrdir.quote,
                                    'src' => "#{conftest_source}",
                                    'arch_hdrdir' => $arch_hdrdir.quote,
                                    'top_srcdir' => $top_srcdir.quote,
                                    'INCFLAGS' => "#$INCFLAGS",
                                    'CPPFLAGS' => "#$CPPFLAGS",
                                    'CFLAGS' => "#$CFLAGS",
                                    'ARCH_FLAG' => "#$ARCH_FLAG",
                                    'LDFLAGS' => "#$LDFLAGS #{ldflags}",
                                    'LOCAL_LIBS' => "#$LOCAL_LIBS #$libs",
                                    'LIBS' => "#{librubyarg} #{opt} #$LIBS")
      conf['LIBPATH'] = libpathflag(libpath.map {|s| RbConfig::expand(s.dup, conf)})
      conf
    end

    @lang = Hash.new(self)

    def self.[](name)
      @lang.fetch(name)
    end

    def self.[]=(name, mod)
      @lang[name] = mod
    end

    MakeMakefile["C++"] = Module.new do
      include MakeMakefile
      extend self

      CONFTEST_CXX = "#{CONFTEST}.#{config_string('CXX_EXT') || CXX_EXT[0]}"

      TRY_LINK_CXX = config_string('TRY_LINK_CXX') ||
        ((cmd = TRY_LINK.gsub(/\$\(C(?:C|(FLAGS))\)/, '$(CXX\1)')) != TRY_LINK && cmd) ||
        "$(CXX) #{OUTFLAG}#{CONFTEST}#{$EXEEXT} $(INCFLAGS) $(CPPFLAGS) " \
                     "$(CXXFLAGS) $(src) $(LIBPATH) $(LDFLAGS) $(ARCH_FLAG) $(LOCAL_LIBS) $(LIBS)"

      def have_devel?
        unless defined? @have_devel
          @have_devel = true
          @have_devel = try_link(MAIN_DOES_NOTHING)
        end
        @have_devel
      end

      def conftest_source
        CONFTEST_CXX
      end

      def cc_command(opt="")
        conf = cc_config(opt)
        RbConfig::expand("$(CXX) #$INCFLAGS #$CPPFLAGS #$CXXFLAGS #$ARCH_FLAG #{opt} -c #{CONFTEST_CXX}",
                         conf)
      end

      def link_command(ldflags, *opts)
        conf = link_config(ldflags, *opts)
        RbConfig::expand(TRY_LINK_CXX.dup, conf)
      end
    end
  end
end

# The cpp_command is not overwritten in the experimental mkmf C++ support.
# See https://bugs.ruby-lang.org/issues/17578
MakeMakefile['C++'].module_eval do
  def cpp_command(outfile, opt="")
    conf = cc_config(opt)
    if $universal and (arch_flag = conf['ARCH_FLAG']) and !arch_flag.empty?
      conf['ARCH_FLAG'] = arch_flag.gsub(/(?:\G|\s)-arch\s+\S+/, '')
    end
    RbConfig::expand("$(CXX) -E #$INCFLAGS #$CPPFLAGS #$CFLAGS #{opt} #{CONFTEST_CXX} #{outfile}",
                     conf)
  end
end

# Now pull in the C++ support
include MakeMakefile['C++']

# Rice needs c++17.
if IS_MSWIN
  $CXXFLAGS += " /std:c++17 /EHsc /permissive- /bigobj"
  $CPPFLAGS += " -D_ALLOW_KEYWORD_MACROS -D_CRT_SECURE_NO_DEPRECATE -D_CRT_NONSTDC_NO_DEPRECATE"
elsif IS_MINGW
  $CXXFLAGS += " -std=c++17 -Wa,-mbig-obj"
else
  $CXXFLAGS += " -std=c++17"
end

# Rice needs to include its header. Let's setup the include path
# to make this easy
path = File.expand_path(File.join(__dir__, '../include'))

unless find_header('rice/rice.hpp', path)
  raise("Could not find rice/rice.hpp header")
end

if IS_DARWIN
  have_library('c++')
elsif !IS_MSWIN
  have_library('stdc++')
end