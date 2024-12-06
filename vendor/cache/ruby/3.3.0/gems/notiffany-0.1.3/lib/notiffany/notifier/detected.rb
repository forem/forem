require "nenv"
require "yaml"

require_relative "emacs"
require_relative "file"
require_relative "gntp"
require_relative "growl"
require_relative "libnotify"
require_relative "notifysend"
require_relative "rb_notifu"
require_relative "terminal_notifier"
require_relative "terminal_title"
require_relative "tmux"

module Notiffany
  class Notifier
    # @private api

    # TODO: use a socket instead of passing env variables to child processes
    # (currently probably only used by guard-cucumber anyway)
    YamlEnvStorage = Nenv::Builder.build do
      create_method(:notifiers=) { |data| YAML.dump(data || []) }
      create_method(:notifiers) { |data| data ? YAML.load(data) : [] }
    end

    # @private api
    class Detected
      NO_SUPPORTED_NOTIFIERS = "Notiffany could not detect any of the"\
        " supported notification libraries."

      class NoneAvailableError < RuntimeError
      end

      class UnknownNotifier < RuntimeError
        def initialize(name)
          super
          @name = name
        end

        attr_reader :name

        def message
          "Unknown notifier: #{@name.inspect}"
        end
      end

      def initialize(supported, env_namespace, logger)
        @supported = supported
        @environment = YamlEnvStorage.new(env_namespace)
        @logger = logger
      end

      def reset
        @environment.notifiers = []
      end

      def detect
        return unless _notifiers.empty?
        @supported.each do |group|
          group.detect do |name, _|
            begin
              _add(name, {})
              true
            rescue Notifier::Base::UnavailableError => e
              @logger.debug "Notiffany: #{name} not available (#{e.message})."
              false
            end
          end
        end

        fail NoneAvailableError, NO_SUPPORTED_NOTIFIERS if _notifiers.empty?
      end

      def available
        @available ||= _notifiers.map do |entry|
          _to_module(entry[:name]).new(entry[:options])
        end
      end

      # Called when user has notifier-specific config.
      # Honor the config by warning if something is wrong
      def add(name, opts)
        _add(name, opts)
      rescue Notifier::Base::UnavailableError => e
        @logger.warning("Notiffany: #{name} not available (#{e.message}).")
      end

      private

      def _add(name, opts)
        @available = nil
        all = _notifiers

        # Silently skip if it's already available, because otherwise
        # we'd have to do :turn_off, then configure, then :turn_on
        names = all.map(&:first).map(&:last)
        unless names.include?(name)
          fail UnknownNotifier, name unless (klass = _to_module(name))

          klass.new(opts) # raises if unavailable
          @environment.notifiers = all << { name: name, options: opts }
        end

        # Just overwrite the options (without turning the notifier off or on),
        # so those options will be passed in next calls to notify()
        all.each { |item| item[:options] = opts if item[:name] == name }
      end

      def _to_module(name)
        @supported.each do |group|
          next unless (notifier = group.detect { |n, _| n == name })
          return notifier.last
        end
        nil
      end

      def _notifiers
        @environment.notifiers
      end
    end
  end
end
