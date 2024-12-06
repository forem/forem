module Rpush
  module Client
    module Redis
      module Apns
        class Feedback
          include Modis::Model

          attribute :app_id, :integer
          attribute :device_token, :string
          attribute :failed_at, :timestamp

          validates :device_token, presence: true
          validates :failed_at, presence: true

          validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
        end
      end
    end
  end
end
