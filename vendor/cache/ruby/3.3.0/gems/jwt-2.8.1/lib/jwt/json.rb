# frozen_string_literal: true

require 'json'

module JWT
  # JSON wrapper
  class JSON
    class << self
      def generate(data)
        ::JSON.generate(data)
      end

      def parse(data)
        ::JSON.parse(data)
      end
    end
  end
end
