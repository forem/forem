module Rpush
  module Client
    module Redis
      module Gcm
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Gcm::App
        end
      end
    end
  end
end
