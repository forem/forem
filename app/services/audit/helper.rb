module Audit
  module Helper
    NOTIFICATION_SUFFIX = ".audit.log".freeze

    def instrument_name(name)
      "#{name}#{NOTIFICATION_SUFFIX}"
    end
  end
end
