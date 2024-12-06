module Rpush
  module Daemon
    class RetryHeaderParser
      def self.parse(header)
        new(header).parse
      end

      def initialize(header)
        @header = header
      end

      def parse
        return unless @header

        if @header.to_s =~ /^[0-9]+$/
          Time.now + @header.to_i
        else
          Time.httpdate(@header)
        end
      end
    end
  end
end
