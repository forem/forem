module Rpush
  module Client
    module Redis
      module Apnsp8
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
          include Rpush::Client::ActiveModel::Apnsp8::Notification
        end
      end
    end
  end
end
