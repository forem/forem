module Rpush
  module Client
    module Redis
      module Wns
        class BadgeNotification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Wns::Notification

          def skip_data_validation?
            true
          end
        end
      end
    end
  end
end
