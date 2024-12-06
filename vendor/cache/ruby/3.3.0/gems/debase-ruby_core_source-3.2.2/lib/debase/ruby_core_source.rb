require 'debase/ruby_core_source/version'
require 'rbconfig'

module Debase
  module RubyCoreSource
    REVISION_MAP = {
        # Add pre-release version here since they do not have patchlevel to refer to.
        # Revision can be found at `revision.h` of ruby sources.
        # Format of this hash:
        # <RUBY_REVISION> => '<sources directory name>', e.g. `61243 => 'ruby-2.5.0-rc1'`
    }

    def self.create_makefile_with_core(hdrs, name)
      # First, see if the gem already has the needed headers
      if hdrs.call
        create_makefile(name)
        return true
      end

      ruby_dir = if RUBY_PATCHLEVEL < 0
        REVISION_MAP[RUBY_REVISION] or "ruby-#{RUBY_VERSION}"
      else
        "ruby-#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      end

      # Check if core headers were already downloaded; if so, use them
      if RbConfig::CONFIG["rubyhdrdir"]
        dest_dir = RbConfig::CONFIG["rubyhdrdir"] + "/" + ruby_dir
        with_cppflags("-I" + dest_dir) {
          if hdrs.call
            create_makefile(name)
            return true
          end
        }
      end

      # Look for sources that ship with gem
      dest_dir = deduce_packaged_source_dir(ruby_dir)
      no_source_abort(ruby_dir) unless File.directory?(dest_dir)

      with_cppflags("-I" + dest_dir) {
        if hdrs.call
          create_makefile(name)
          return true
        end
      }
      return false
    end

    def self.deduce_packaged_source_dir(ruby_dir)
      prefix = File.dirname(__FILE__) + '/ruby_core_source/'
      expected_directory = prefix + ruby_dir
      if (RUBY_REVISION.is_a? String or RUBY_REVISION > 0) and File.directory?(expected_directory)
        expected_directory
      else
        # Fallback to an older version.
        ruby_version = Gem::Version.new(RUBY_VERSION)
        path, = Dir.glob(prefix + 'ruby-*').
          select { |d| File.directory?(d) }.
          map { |d| [d, ruby_source_dir_version(d)] }.
          sort { |(_, v1), (_, v2)| -(v1 <=> v2) }.
          find { |(_, v)| v <= ruby_version }

        version = File.basename(path)
        fallback_source_warning(ruby_dir, version)
        path
      end
    end

    def self.ruby_source_dir_version(dir)
      match = /ruby-([0-9\.]+)-((p|rc|preview)[0-9]+)\z/.match(dir)
      Gem::Version.new("#{match[1]}.#{match[2]}")
    end

    def self.fallback_source_warning(ruby_version, fallback_version)
      warn <<-STR
**************************************************************************
No source for #{ruby_version} (revision #{RUBY_REVISION}) provided with
debase-ruby_core_source gem. Falling back to #{fallback_version}.
**************************************************************************
STR
    end

    def self.no_source_abort(ruby_version)
      abort <<-STR
Makefile creation failed
**************************************************************************
No source for #{ruby_version} provided with debase-ruby_core_source gem.
**************************************************************************
STR
    end
  end
end
