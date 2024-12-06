module Rpush
  module Client
    module Redis
      module Apns
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
        end
      end
    end
  end
end
