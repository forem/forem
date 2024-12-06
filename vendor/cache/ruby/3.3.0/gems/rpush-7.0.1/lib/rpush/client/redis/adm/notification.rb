module Rpush
  module Client
    module Redis
      module Adm
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Adm::Notification
        end
      end
    end
  end
end
