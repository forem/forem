module Rpush
  module Client
    module Redis
      module Apns2
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
        end
      end
    end
  end
end
