module Rpush
  module Client
    module ActiveRecord
      module Apnsp8
        class Notification < Rpush::Client::ActiveRecord::Apns::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
        end
      end
    end
  end
end
