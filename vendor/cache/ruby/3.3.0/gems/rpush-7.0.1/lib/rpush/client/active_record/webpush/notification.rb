module Rpush
  module Client
    module ActiveRecord
      module Webpush
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Webpush::Notification
        end
      end
    end
  end
end

