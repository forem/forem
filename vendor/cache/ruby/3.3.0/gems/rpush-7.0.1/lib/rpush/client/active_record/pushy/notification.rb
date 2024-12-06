module Rpush
  module Client
    module ActiveRecord
      module Pushy
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Pushy::Notification
        end
      end
    end
  end
end
