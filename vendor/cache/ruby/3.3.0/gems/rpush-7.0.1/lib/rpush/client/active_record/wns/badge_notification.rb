module Rpush
  module Client
    module ActiveRecord
      module Wns
        class BadgeNotification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Wns::Notification

          def skip_data_validation?
            true
          end
        end
      end
    end
  end
end
