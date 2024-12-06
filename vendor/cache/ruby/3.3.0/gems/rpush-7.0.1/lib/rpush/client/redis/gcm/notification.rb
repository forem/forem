module Rpush
  module Client
    module Redis
      module Gcm
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Gcm::Notification
        end
      end
    end
  end
end
