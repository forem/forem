module Rpush
  module Client
    module ActiveRecord
      module Apns2
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
          include Rpush::Client::ActiveModel::Apns2::Notification
          include Rpush::Client::ActiveRecord::Apns::ActiveRecordSerializableNotification
        end
      end
    end
  end
end
