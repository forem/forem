require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

require "forwardable"

require "guard/ui"
require "guard/internals/session"
require "guard/internals/state"
require "guard/guardfile/evaluator"

module Guard
  # @deprecated Every method in this module is deprecated
  module Deprecated
    module Guard
      def self.add_deprecated(klass)
        klass.send(:extend, ClassMethods)
      end

      module ClassMethods
        MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-EOS.gsub(/^\s*/, "")
          For more information on how to upgrade for Guard 2.0, please head
          over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
        EOS

        # @deprecated Use `Guard.plugins(filter)` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        GUARDS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guards(filter)' is deprecated.

          Please use 'Guard.plugins(filter)' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        EOS

        def guards(filter = nil)
          ::Guard::UI.deprecation(GUARDS)
          ::Guard.state.session.plugins.all(filter)
        end

        # @deprecated Use `Guard.add_plugin(name, options = {})` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        ADD_GUARD = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.add_guard(name, options = {})' is
          deprecated.

          Please use 'Guard.add_plugin(name, options = {})' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        EOS

        def add_guard(*args)
          ::Guard::UI.deprecation(ADD_GUARD)
          add_plugin(*args)
        end

        # @deprecated Use
        #   `Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
        #   fail_gracefully)` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        GET_GUARD_CLASS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.get_guard_class(name, fail_gracefully
          = false)' is deprecated and is now always on.

          Please use 'Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
          fail_gracefully)' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        EOS

        def get_guard_class(name, fail_gracefully = false)
          UI.deprecation(GET_GUARD_CLASS)
          PluginUtil.new(name).plugin_class(fail_gracefully: fail_gracefully)
        end

        # @deprecated Use `Guard::PluginUtil.new(name).plugin_location` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        LOCATE_GUARD = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.locate_guard(name)' is deprecated.

          Please use 'Guard::PluginUtil.new(name).plugin_location' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        EOS

        def locate_guard(name)
          UI.deprecation(LOCATE_GUARD)
          PluginUtil.new(name).plugin_location
        end

        # @deprecated Use `Guard::PluginUtil.plugin_names` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        # Deprecator message for the `Guard.guard_gem_names` method
        GUARD_GEM_NAMES = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guard_gem_names' is deprecated.

          Please use 'Guard::PluginUtil.plugin_names' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        EOS

        def guard_gem_names
          UI.deprecation(GUARD_GEM_NAMES)
          PluginUtil.plugin_names
        end

        RUNNING = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that Guard.running was
          never initialized or used internally.
        EOS

        def running
          UI.deprecation(RUNNING)
          nil
        end

        LOCK = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that this accessor was
          never initialized or used internally.
        EOS
        def lock
          UI.deprecation(LOCK)
        end

        LISTENER_ASSIGN = <<-EOS.gsub(/^\s*/, "")
          listener= should not be used
        EOS

        def listener=(_)
          UI.deprecation(LISTENER_ASSIGN)
          ::Guard.listener
        end

        EVALUATOR = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def evaluator
          UI.deprecation(EVALUATOR)
          options = ::Guard.state.session.evaluator_options
          ::Guard::Guardfile::Evaluator.new(options)
        end

        RESET_EVALUATOR = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def reset_evaluator(_options)
          UI.deprecation(RESET_EVALUATOR)
        end

        RUNNER = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def runner
          UI.deprecation(RUNNER)
          ::Guard::Runner.new
        end

        EVALUATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def evaluate_guardfile
          UI.deprecation(EVALUATE_GUARDFILE)
          options = ::Guard.state.session.evaluator_options
          evaluator = ::Guard::Guardfile::Evaluator.new(options)
          evaluator.evaluate
          msg = "No plugins found in Guardfile, please add at least one."
          ::Guard::UI.error msg if _pluginless_guardfile?
        end

        OPTIONS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.9.0 Guard.options is deprecated and ideally you
          should be able to set specific options through an API or a DSL
          method. Feel free to add feature requests if there's something
          missing.
        EOS

        def options
          UI.deprecation(OPTIONS)

          Class.new(Hash) do
            def initialize
              super(to_hash)
            end

            def to_hash
              session = ::Guard.state.session
              {
                clear: session.clearing?,
                debug: session.debug?,
                watchdir: Array(session.watchdirs).map(&:to_s),
                notify: session.notify_options[:notify],
                no_interactions: (session.interactor_name == :sleep)
              }
            end

            extend Forwardable
            delegate [:to_a, :keys] => :to_hash
            delegate [:include?] => :keys

            def fetch(key, *args)
              hash = to_hash
              verify_key!(hash, key)
              hash.fetch(key, *args)
            end

            def []=(key, value)
              case key
              when :clear
                ::Guard.state.session.clearing(value)
              else
                msg = "Oops! Guard.option[%s]= is unhandled or unsupported." \
                  "Please file an issue if you rely on this option working."
                fail NotImplementedError, format(msg, key)
              end
            end

            private

            def verify_key!(hash, key)
              return if hash.key?(key)
              msg = "Oops! Guard.option[%s] is unhandled or unsupported." \
                "Please file an issue if you rely on this option working."
              fail NotImplementedError, format(msg, key)
            end
          end.new
        end

        ADD_GROUP = <<-EOS.gsub(/^\s*/, "")
          add_group is deprecated since 2.10.0 in favor of
          Guard.state.session.groups.add
        EOS

        def add_group(name, options = {})
          UI.deprecation(ADD_GROUP)
          ::Guard.state.session.groups.add(name, options)
        end

        ADD_PLUGIN = <<-EOS.gsub(/^\s*/, "")
          add_plugin is deprecated since 2.10.0 in favor of
          Guard.state.session.plugins.add
        EOS

        def add_plugin(name, options = {})
          UI.deprecation(ADD_PLUGIN)
          ::Guard.state.session.plugins.add(name, options)
        end

        GROUP = <<-EOS.gsub(/^\s*/, "")
          group is deprecated since 2.10.0 in favor of
          Guard.state.session.group.add(filter).first
        EOS

        def group(filter)
          UI.deprecation(GROUP)
          ::Guard.state.session.groups.all(filter).first
        end

        PLUGIN = <<-EOS.gsub(/^\s*/, "")
          plugin is deprecated since 2.10.0 in favor of
          Guard.state.session.group.add(filter).first
        EOS

        def plugin(filter)
          UI.deprecation(PLUGIN)
          ::Guard.state.session.plugins.all(filter).first
        end

        GROUPS = <<-EOS.gsub(/^\s*/, "")
          group is deprecated since 2.10.0 in favor of
          Guard.state.session.groups.all(filter)
        EOS

        def groups(filter)
          UI.deprecation(GROUPS)
          ::Guard.state.session.groups.all(filter)
        end

        PLUGINS = <<-EOS.gsub(/^\s*/, "")
          plugins is deprecated since 2.10.0 in favor of
          Guard.state.session.plugins.all(filter)
        EOS

        def plugins(filter)
          UI.deprecation(PLUGINS)
          ::Guard.state.session.plugins.all(filter)
        end

        SCOPE = <<-EOS.gsub(/^\s*/, "")
          scope is deprecated since 2.10.0 in favor of
          Guard.state.scope.to_hash
        EOS

        def scope
          UI.deprecation(SCOPE)
          ::Guard.state.scope.to_hash
        end

        SCOPE_ASSIGN = <<-EOS.gsub(/^\s*/, "")
          scope= is deprecated since 2.10.0 in favor of
          Guard.state.scope.to_hash
        EOS

        def scope=(scope)
          UI.deprecation(SCOPE_ASSIGN)
          ::Guard.state.scope.from_interactor(scope)
        end
      end
    end
  end
end
