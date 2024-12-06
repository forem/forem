require 'drb/drb'

module StripeMock
  class ErrorQueue
    include DRb::DRbUndumped
    extend DRb::DRbUndumped

    def initialize
      @queue = []
    end

    def queue(error, handler_names)
      @queue << handler_names.map {|n| [n, error]}
    end

    def error_for_handler_name(handler_name)
      return nil if @queue.count == 0
      triggers = @queue.first
      (triggers.assoc(:all) || triggers.assoc(handler_name) || [])[1]
    end

    def dequeue
      @queue.shift
    end

  end
end
