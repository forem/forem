module Rpush
  module Client
    module ActiveRecord
      module Apns2
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Apns2::App
        end
      end
    end
  end
end
