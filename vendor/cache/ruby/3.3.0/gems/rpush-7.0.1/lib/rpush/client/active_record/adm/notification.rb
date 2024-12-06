module Rpush
  module Client
    module ActiveRecord
      module Adm
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Rpush::Client::ActiveModel::Adm::Notification
        end
      end
    end
  end
end
