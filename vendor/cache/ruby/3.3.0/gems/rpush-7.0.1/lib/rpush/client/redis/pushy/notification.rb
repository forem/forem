module Rpush
  module Client
    module Redis
      module Pushy
        class Notification < Rpush::Client::Redis::Notification
          include Rpush::Client::ActiveModel::Pushy::Notification

          attribute :external_device_id, :string

          def time_to_live=(value)
            self.expiry = value
          end
        end
      end
    end
  end
end
