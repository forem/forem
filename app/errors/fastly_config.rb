module FastlyConfig
  module Errors
    class Error < StandardError
    end

    class InvalidConfigsFormat < Error
      def initialize(msg = "configs: must be an Array of Strings")
        super(msg)
      end
    end

    class InvalidConfig < Error
      def initialize(invalid_config, valid_configs)
        msg = "Invalid Fastly config - #{invalid_config}. Only #{valid_configs.join(', ')} are valid."
        super(msg)
      end
    end
  end
end
