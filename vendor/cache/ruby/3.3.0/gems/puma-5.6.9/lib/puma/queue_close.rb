class ClosedQueueError < StandardError; end
module Puma

  # Queue#close was added in Ruby 2.3.
  # Add a simple implementation for earlier Ruby versions.
  #
  module QueueClose
    def close
      num_waiting.times {push nil}
      @closed = true
    end
    def closed?
      @closed ||= false
    end
    def push(object)
      raise ClosedQueueError if closed?
      super
    end
    alias << push
    def pop(non_block=false)
      return nil if !non_block && closed? && empty?
      super
    end
  end
  ::Queue.prepend QueueClose
end
