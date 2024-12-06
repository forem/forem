module Rpush
  module Client
    module Redis
      module Pushy
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Pushy::App

          def api_key=(value)
            self.auth_key = value
            super
          end
        end
      end
    end
  end
end
