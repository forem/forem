# frozen_string_literal: true

# Make sure Core is loaded
require "ruby-next"
require "pathname"

module RubyNext
  module Language
    # Module responsible for transpiling a library at load time
    module GemTranspiler
      def self.maybe_transpile(root_dir, lib_dir, target_dir)
        return if File.directory?(target_dir)

        Dir.chdir(root_dir) do
          unless system("bundle exec ruby-next nextify ./#{lib_dir} -o #{target_dir} --min-version=#{RubyNext.current_ruby_version} > /dev/null 2>&1")
            RubyNext.warn "Traspiled files are missing in: #{target_dir}. \n" \
              "Make sure you have gem 'ruby-next' in your Gemfile to auto-transpile the required files from source on load. " \
              "Otherwise the code from #{root_dir} may not work correctly."
          end
        end
      end
    end

    class << self
      unless method_defined?(:runtime?)
        def runtime?
          false
        end
      end

      def setup_gem_load_path(lib_dir = "lib", rbnext_dir: RUBY_NEXT_DIR, transpile: false)
        called_from = caller_locations(1, 1).first.path
        dirname = File.realpath(File.dirname(called_from))

        loop do
          basename = File.basename(dirname)
          raise "Couldn't find gem's load dir: #{lib_dir}" if basename == dirname

          break if basename == lib_dir

          dirname = File.dirname(basename)
        end

        dirname = File.realpath(dirname)

        return if Language.runtime? && Language.watch_dirs.include?(dirname)

        next_dirname = File.join(dirname, rbnext_dir)

        GemTranspiler.maybe_transpile(File.dirname(dirname), lib_dir, next_dirname) if transpile

        current_index = $LOAD_PATH.find_index do |load_path|
          pn = Pathname.new(load_path)
          pn.exist? && pn.realpath.to_s == dirname
        end

        raise "Gem's lib is not in the $LOAD_PATH: #{dirname}" if current_index.nil?

        version = RubyNext.next_ruby_version

        loop do
          break unless version

          version_dir = File.join(next_dirname, version.segments[0..1].join("."))

          if File.exist?(version_dir)
            $LOAD_PATH.insert current_index, version_dir
            current_index += 1
          end

          version = RubyNext.next_ruby_version(version)
        end
      end
    end
  end
end
