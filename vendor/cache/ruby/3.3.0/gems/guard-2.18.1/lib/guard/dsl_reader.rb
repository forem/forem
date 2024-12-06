require "guard/dsl"

module Guard
  # TODO: this should probably be a base class for Dsl instead (in Guard 3.x)
  class DslReader < Dsl
    attr_reader :plugin_names

    def initialize
      super
      @plugin_names = []
    end

    def guard(name, _options = {})
      @plugin_names << name.to_s
    end

    # Stub everything else
    def notification(_notifier, _opts = {})
    end

    def interactor(_options)
    end

    def group(*_args)
    end

    def watch(_pattern, &_action)
    end

    def callback(*_args, &_block)
    end

    def ignore(*_regexps)
    end

    def ignore!(*_regexps)
    end

    def logger(_options)
    end

    def scope(_scope = {})
    end

    def directories(_directories)
    end

    def clearing(_on)
    end
  end
end
