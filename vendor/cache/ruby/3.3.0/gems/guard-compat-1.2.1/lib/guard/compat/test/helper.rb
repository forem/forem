# Minimal stub allowing a plugin to work

require 'guard/compat/plugin'

module Guard
  # Monkey patch Plugin to just keep the interface
  class Plugin
    attr_reader :options

    alias_method :old_initialize, :initialize

    def initialize(options = {})
      @options = options
    end

    remove_method(:old_initialize)
  end

  # Stub, but allow real Notifier to be used, because e.g. guard-minitest uses
  # is while guard-process is being tested
  unless Guard.const_defined?('Notifier')
    module Notifier
      # NOTE: do not implement anything here, so using any UI methods
      # causes tests to fail
    end
  end

  # Stub, but allow real UI to be used, because e.g. guard-minitest uses it
  # through using Guard::Notifier
  unless Guard.const_defined?('UI')
    module UI
      # NOTE: do not implement anything here, so using any UI methods
      # causes tests to fail
    end
  end
end
