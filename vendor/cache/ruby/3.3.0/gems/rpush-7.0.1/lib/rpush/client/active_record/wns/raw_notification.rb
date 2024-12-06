module Rpush
  module Client
    module ActiveRecord
      module Wns
        class RawNotification < Rpush::Client::ActiveRecord::Notification
          validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator,
                         limit: 5120
          include Rpush::Client::ActiveModel::Wns::Notification
        end
      end
    end
  end
end
