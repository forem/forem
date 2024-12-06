# frozen_string_literal: true

module Solargraph
  module Pin
    class Keyword < Base
      def initialize name
        super(name: name)
      end

      def name
        @name
      end
    end
  end
end
