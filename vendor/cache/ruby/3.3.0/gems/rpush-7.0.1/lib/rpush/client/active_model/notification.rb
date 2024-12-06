module Rpush
  module Client
    module ActiveModel
      module Notification
        def self.included(base)
          base.instance_eval do
            validates :expiry, numericality: true, allow_nil: true
            validates :app, presence: true
          end
        end

        def payload
          multi_json_dump(as_json)
        end

        def payload_data_size
          multi_json_dump(as_json['data']).bytesize
        end
      end
    end
  end
end
