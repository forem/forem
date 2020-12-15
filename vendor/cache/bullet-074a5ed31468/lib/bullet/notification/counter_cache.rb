# frozen_string_literal: true

module Bullet
  module Notification
    class CounterCache < Base
      def body
        klazz_associations_str
      end

      def title
        'Need Counter Cache'
      end
    end
  end
end
