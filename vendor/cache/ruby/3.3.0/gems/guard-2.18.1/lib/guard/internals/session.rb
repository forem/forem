require "guard/internals/plugins"
require "guard/internals/groups"

require "guard/options"

module Guard
  # @private api
  module Internals
    # TODO: split into a commandline class and session (plugins, groups)
    # TODO: swap session and metadata
    class Session
      attr_reader :plugins
      attr_reader :groups

      DEFAULT_OPTIONS = {
        clear: false,
        debug: false,
        no_bundler_warning: false,

        # User defined scopes
        group: [],
        plugin: [],

        # Notifier
        notify: true,

        # Interactor
        no_interactions: false,

        # Guardfile options:
        # guardfile_contents
        guardfile: nil,

        # Listener options
        # TODO: rename to watchdirs?
        watchdir: Dir.pwd,
        latency: nil,
        force_polling: false,
        wait_for_delay: nil,
        listen_on: nil
      }

      def cmdline_groups
        @cmdline_groups.dup.freeze
      end

      def cmdline_plugins
        @cmdline_plugins.dup.freeze
      end

      def initialize(new_options)
        @options = Options.new(new_options, DEFAULT_OPTIONS)

        @plugins = Plugins.new
        @groups = Groups.new

        @cmdline_groups = @options[:group]
        @cmdline_plugins = @options[:plugin]

        @clear = @options[:clear]
        @debug = @options[:debug]
        @watchdirs = Array(@options[:watchdir])
        @notify = @options[:notify]
        @interactor_name = @options[:no_interactions] ? :sleep : :pry_wrapper

        @guardfile_plugin_scope = []
        @guardfile_group_scope = []
        @guardfile_ignore = []
        @guardfile_ignore_bang = []

        @guardfile_notifier_options = {}
      end

      def guardfile_scope(scope)
        opts = scope.dup

        groups = Array(opts.delete(:groups))
        group = Array(opts.delete(:group))
        @guardfile_group_scope = Array(groups) + Array(group)

        plugins = Array(opts.delete(:plugins))
        plugin = Array(opts.delete(:plugin))
        @guardfile_plugin_scope = Array(plugins) + Array(plugin)

        fail "Unknown options: #{opts.inspect}" unless opts.empty?
      end

      # TODO: create a EvaluatorResult class?
      attr_reader :guardfile_group_scope
      attr_reader :guardfile_plugin_scope
      attr_accessor :guardfile_ignore_bang

      attr_reader :guardfile_ignore
      def guardfile_ignore=(ignores)
        @guardfile_ignore += Array(ignores).flatten
      end

      def clearing(on)
        @clear = on
      end

      def clearing?
        @clear
      end

      alias :clear? :clearing?

      def debug?
        @debug
      end

      def watchdirs
        @watchdirs_from_guardfile ||= nil
        @watchdirs_from_guardfile || @watchdirs
      end

      # set by Dsl with :directories() command
      def watchdirs=(dirs)
        dirs = [Dir.pwd] if dirs.empty?
        @watchdirs_from_guardfile = dirs.map { |dir| File.expand_path dir }
      end

      def listener_args
        if @options[:listen_on]
          [:on, @options[:listen_on]]
        else
          listener_options = {}
          [:latency, :force_polling, :wait_for_delay].each do |option|
            listener_options[option] = @options[option] if @options[option]
          end
          expanded_watchdirs = watchdirs.map { |dir| File.expand_path dir }
          [:to, *expanded_watchdirs, listener_options]
        end
      end

      def evaluator_options
        opts = { guardfile: @options[:guardfile] }
        # TODO: deprecate :guardfile_contents
        if @options[:guardfile_contents]
          opts[:contents] = @options[:guardfile_contents]
        end
        opts
      end

      def notify_options
        names = @guardfile_notifier_options.keys
        return { notify: false } if names.include?(:off)

        {
          notify: @options[:notify],
          notifiers: @guardfile_notifier_options
        }
      end

      def guardfile_notification=(config)
        @guardfile_notifier_options.merge!(config)
      end

      attr_reader :interactor_name

      # TODO: call this from within action, not within interactor command
      def convert_scope(entries)
        scopes = { plugins: [], groups: [] }
        unknown = []

        entries.each do |entry|
          if plugin = plugins.all(entry).first
            scopes[:plugins] << plugin
          elsif group = groups.all(entry).first
            scopes[:groups] << group
          else
            unknown << entry
          end
        end

        [scopes, unknown]
      end
    end
  end
end
