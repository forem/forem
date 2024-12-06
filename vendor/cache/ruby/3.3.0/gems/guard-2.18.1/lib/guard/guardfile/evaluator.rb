require "guard/config"
require "guard/deprecated/evaluator" unless Guard::Config.new.strict?

require "guard/options"
require "guard/plugin"

require "guard/dsl"
require "guard/dsl_reader"

module Guard
  module Guardfile
    # This class is responsible for evaluating the Guardfile. It delegates to
    # Guard::Dsl for the actual objects generation from the Guardfile content.
    #
    # @see Guard::Dsl
    #
    # TODO: rename this to a Locator or Loader or something
    class Evaluator
      Deprecated::Evaluator.add_deprecated(self) unless Config.new.strict?

      DEFAULT_GUARDFILES = %w(
        guardfile.rb
        Guardfile
        ~/.Guardfile
      ).freeze

      ERROR_NO_GUARDFILE = "No Guardfile found,"\
        " please create one with `guard init`."

      attr_reader :options, :guardfile_path

      ERROR_NO_PLUGINS = "No Guard plugins found in Guardfile,"\
        " please add at least one."

      class Error < RuntimeError
      end

      class NoGuardfileError < Error
      end

      class NoCustomGuardfile < Error
      end

      class NoPluginsError < Error
      end

      def guardfile_source
        @source
      end

      # Initializes a new Guard::Guardfile::Evaluator object.
      #
      # @option opts [String] guardfile the path to a valid Guardfile
      # @option opts [String] contents a string representing the
      # content of a valid Guardfile
      #
      def initialize(opts = {})
        @type = nil
        @path = nil
        @user_config = nil

        opts = _from_deprecated(opts)

        if opts[:contents]
          @type = :inline
          @contents = opts[:contents]
        elsif opts[:guardfile]
          @type = :custom
          @path = Pathname.new(opts[:guardfile]) # may be updated by _read
        end
      end

      # Evaluates the DSL methods in the `Guardfile`.
      #
      # @example Programmatically evaluate a Guardfile
      #   Guard::Guardfile::Evaluator.new.evaluate
      #
      # @example Programmatically evaluate a Guardfile with a custom Guardfile
      # path
      #
      #   options = { guardfile: '/Users/guardfile/MyAwesomeGuardfile' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate
      #
      # @example Programmatically evaluate a Guardfile with an inline Guardfile
      #
      #   options = { contents: 'guard :rspec' }
      #   Guard::Guardfile::Evaluator.new(options).evaluate
      #
      def evaluate
        inline? || _use_provided || _use_default!

        contents = _guardfile_contents
        fail NoPluginsError, ERROR_NO_PLUGINS unless /guard/m =~ contents

        Dsl.new.evaluate(contents, @path || "", 1)
      end

      # Tests if the current `Guardfile` contains a specific Guard plugin.
      #
      # @example Programmatically test if a Guardfile contains a specific Guard
      # plugin
      #
      #   File.read('Guardfile')
      #   => "guard :rspec"
      #
      #   Guard::Guardfile::Evaluator.new.guardfile_include?('rspec)
      #   => true
      #
      # @param [String] plugin_name the name of the Guard
      # @return [Boolean] whether the Guard plugin has been declared
      #
      # TODO: rename this method to it matches RSpec examples better
      def guardfile_include?(plugin_name)
        reader = DslReader.new
        reader.evaluate(@contents, @path || "", 1)
        reader.plugin_names.include?(plugin_name)
      end

      attr_reader :path

      def custom?
        @type == :custom
      end

      # Gets the content of the `Guardfile` concatenated with the global
      # user configuration file.
      #
      # @example Programmatically get the content of the current Guardfile
      #   Guard::Guardfile::Evaluator.new.guardfile_contents
      #   => "guard :rspec"
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents
        config = File.read(_user_config_path) if File.exist?(_user_config_path)
        [_guardfile_contents_without_user_config, config].compact.join("\n")
      end

      def inline?
        @type == :inline
      end

      private

      def _guardfile_contents_without_user_config
        @guardfile_contents || ""
      end

      def _instance_eval_guardfile(contents)
        Dsl.new.evaluate(contents, @guardfile_path || "", 1)
      rescue => ex
        UI.error "Invalid Guardfile, original error is:\n#{ $! }"
        raise ex
      end

      def _fetch_guardfile_contents
        _use_inline || _use_provided || _use_default
        @evaluated = true

        return if _guardfile_contents_usable?
        UI.error "No Guard plugins found in Guardfile,"\
          " please add at least one."
      end

      def _use_inline
        source_from_option = @source.nil? && options[:guardfile_contents]
        inline = @source == :inline

        return false unless source_from_option || inline

        @source = :inline
        @guardfile_contents = options[:guardfile_contents]

        UI.info "Using inline Guardfile."
        true
      end

      def _use_provided
        return unless custom?
        @path, @contents = _read(@path)
        true
      rescue Errno::ENOENT
        fail NoCustomGuardfile, "No Guardfile exists at #{ @path }."
      end

      def _use_default!
        DEFAULT_GUARDFILES.each do |guardfile|
          begin
            @path, @contents = _read(guardfile)
            @type = :default
            break
          rescue Errno::ENOENT
            if guardfile == DEFAULT_GUARDFILES.last
              fail NoGuardfileError, ERROR_NO_GUARDFILE
            end
          end
        end
      end

      def _read(path)
        full_path = Pathname.new(path.to_s).expand_path
        [full_path, full_path.read]
      rescue Errno::ENOENT
        fail
      rescue SystemCallError => e
        UI.error "Error reading file #{full_path}:"
        UI.error e.inspect
        UI.error e.backtrace
        abort
      end

      def _guardfile_contents
        @user_config ||= Pathname.new("~/.guard.rb").expand_path.read
        [@contents, @user_config].compact.join("\n")
      rescue Errno::ENOENT
        @contents || ""
      end

      def _guardfile_contents_usable?
        guardfile_contents && guardfile_contents =~ /guard/m
      end

      def _from_deprecated(opts)
        res = opts.dup
        if opts.key?(:guardfile_contents)
          res[:contents] = opts[:guardfile_contents]
        end
        res
      end
    end
  end
end
