module Rpush
  module Client
    module Redis
      module Wns
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Wns::App

          attribute :access_token, :string
          attribute :access_token_expiration, :timestamp
        end
      end
    end
  end
end
