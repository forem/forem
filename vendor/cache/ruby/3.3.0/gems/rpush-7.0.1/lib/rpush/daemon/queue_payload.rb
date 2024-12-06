module Rpush
  module Daemon
    class QueuePayload
      attr_reader :batch, :notification

      def initialize(batch, notification = nil)
        @batch = batch
        @notification = notification
      end
    end
  end
end
