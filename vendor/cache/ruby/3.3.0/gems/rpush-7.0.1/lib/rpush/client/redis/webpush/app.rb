module Rpush
  module Client
    module Redis
      module Webpush
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Webpush::App

          def vapid_keypair=(value)
            self.certificate = value
          end
        end
      end
    end
  end
end
