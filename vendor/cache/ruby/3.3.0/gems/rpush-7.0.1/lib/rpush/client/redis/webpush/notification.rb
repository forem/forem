module Rpush
  module Client
    module Redis
      module Webpush
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Webpush::Notification

          def time_to_live=(value)
            self.expiry = value
          end
        end
      end
    end
  end
end
