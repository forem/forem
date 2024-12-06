module Rpush
  module Client
    module Redis
      module Apns2
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Apns2::App
        end
      end
    end
  end
end
