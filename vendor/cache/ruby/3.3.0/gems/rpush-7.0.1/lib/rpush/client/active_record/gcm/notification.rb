module Rpush
  module Client
    module ActiveRecord
      module Gcm
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Gcm::Notification
        end
      end
    end
  end
end
