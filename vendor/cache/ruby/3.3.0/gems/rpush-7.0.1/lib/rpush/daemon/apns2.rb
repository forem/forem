module Rpush
  module Daemon
    module Apns2
      extend ServiceConfigMethods

      batch_deliveries true
      dispatcher :apns_http2
    end
  end
end
