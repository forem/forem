module Rpush
  class DeliveryError < StandardError
    attr_reader :code, :notification_id

    def initialize(code, notification_id, description)
      @code = code
      @notification_id = notification_id
      @description = description
    end

    def to_s
      message
    end

    def message
      error_str = [@code, "(#{@description})"].compact.join(' ')
      "Unable to deliver notification #{@notification_id}, received error #{error_str}"
    end

    def ==(other)
      other.is_a?(DeliveryError) && \
        other.code == code && \
        other.notification_id == notification_id && \
        other.to_s == to_s
    end
  end
end
