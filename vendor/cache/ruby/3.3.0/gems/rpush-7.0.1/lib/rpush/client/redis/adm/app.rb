module Rpush
  module Client
    module Redis
      module Adm
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Adm::App

          attribute :access_token, :string
          attribute :access_token_expiration, :timestamp
        end
      end
    end
  end
end
