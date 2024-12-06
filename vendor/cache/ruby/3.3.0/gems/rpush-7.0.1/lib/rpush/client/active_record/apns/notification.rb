module Rpush
  module Client
    module ActiveRecord
      module Apns
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Apns::Notification
          include ActiveRecordSerializableNotification
        end
      end
    end
  end
end
