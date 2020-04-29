module FastlyConfig
  module Errors
    class Error < StandardError
    end

    class InvalidOptionsFormat < Error
    end

    class InvalidOption < Error
      def initialize(invalid_option, valid_options)
        msg = "Invalid Fastly option - #{invalid_option}. Only #{valid_options.join(', ')} are valid."
        super(msg)
      end
    end
  end
end
