module Rpush
  module Client
    module Redis
      module Apns
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Apns::App
        end
      end
    end
  end
end
