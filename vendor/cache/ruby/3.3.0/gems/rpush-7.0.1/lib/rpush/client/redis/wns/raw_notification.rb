module Rpush
  module Client
    module Redis
      module Wns
        class RawNotification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Wns::Notification
        end
      end
    end
  end
end
