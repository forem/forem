module NetHttp2

  module Callbacks

    def on(event, &block)
      raise ArgumentError, 'on event must provide a block' unless block_given?

      @callback_events        ||= {}
      @callback_events[event] ||= []
      @callback_events[event] << block
    end

    def emit(event, arg)
      return unless @callback_events && @callback_events[event]
      @callback_events[event].each { |b| b.call(arg) }
    end

    def callback_events
      @callback_events || {}
    end
  end
end
