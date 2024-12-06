require 'honeybadger/backend/null'

module Honeybadger
  module Backend
    class Test < Null
      # The notification list.
      #
      # @example
      #   Test.notifications[:notices] # => [Notice, Notice, ...]
      #
      # @return [Hash] Notifications hash.
      def self.notifications
        @notifications ||= Hash.new {|h,k| h[k] = [] }
      end

      # @api public
      # The check in list.
      #
      # @example
      #   Test.check_ins # => ["foobar", "danny", ...]
      #
      # @return [Array<Object>] List of check ins.
      def self.check_ins
        @check_ins ||= []
      end

      def notifications
        self.class.notifications
      end

      def check_ins
        self.class.check_ins
      end

      def notify(feature, payload)
        notifications[feature] << payload
        super
      end

      def check_in(id)
        check_ins << id
      end
    end
  end
end
