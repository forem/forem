module Rpush
  module Daemon
    module Apnsp8
      extend ServiceConfigMethods

      batch_deliveries true
      dispatcher :apnsp8_http2
    end
  end
end
