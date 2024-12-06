module Rpush
  module Client
    module ActiveRecord
      module Apns
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Apns::App
        end
      end
    end
  end
end
