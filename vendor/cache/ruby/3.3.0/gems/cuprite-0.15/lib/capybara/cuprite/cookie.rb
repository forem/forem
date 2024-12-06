# frozen_string_literal: true

module Capybara
  module Cuprite
    class Cookie
      def initialize(attributes)
        @attributes = attributes
      end

      def name
        @attributes["name"]
      end

      def value
        @attributes["value"]
      end

      def domain
        @attributes["domain"]
      end

      def path
        @attributes["path"]
      end

      def size
        @attributes["size"]
      end

      def secure?
        @attributes["secure"]
      end

      def httponly?
        @attributes["httpOnly"]
      end

      def session?
        @attributes["session"]
      end

      def expires
        Time.at(@attributes["expires"]) if (@attributes["expires"]).positive?
      end
    end
  end
end
