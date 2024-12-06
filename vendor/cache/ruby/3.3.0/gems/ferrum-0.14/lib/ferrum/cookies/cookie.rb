# frozen_string_literal: true

module Ferrum
  class Cookies
    #
    # Represents a [cookie value](https://chromedevtools.github.io/devtools-protocol/1-3/Network/#type-Cookie).
    #
    class Cookie
      # The parsed JSON attributes.
      #
      # @return [Hash{String => [String, Boolean, nil]}]
      attr_reader :attributes

      #
      # Initializes the cookie.
      #
      # @param [Hash{String => String}] attributes
      #   The parsed JSON attributes.
      #
      def initialize(attributes)
        @attributes = attributes
      end

      #
      # The cookie's name.
      #
      # @return [String]
      #
      def name
        attributes["name"]
      end

      #
      # The cookie's value.
      #
      # @return [String]
      #
      def value
        attributes["value"]
      end

      #
      # The cookie's domain.
      #
      # @return [String]
      #
      def domain
        attributes["domain"]
      end

      #
      # The cookie's path.
      #
      # @return [String]
      #
      def path
        attributes["path"]
      end

      #
      # The `sameSite` configuration.
      #
      # @return ["Strict", "Lax", "None", nil]
      #
      def samesite
        attributes["sameSite"]
      end
      alias same_site samesite

      #
      # The cookie's size.
      #
      # @return [Integer]
      #
      def size
        attributes["size"]
      end

      #
      # Specifies whether the cookie is secure or not.
      #
      # @return [Boolean]
      #
      def secure?
        attributes["secure"]
      end

      #
      # Specifies whether the cookie is HTTP-only or not.
      #
      # @return [Boolean]
      #
      def httponly?
        attributes["httpOnly"]
      end
      alias http_only? httponly?

      #
      # Specifies whether the cookie is a session cookie or not.
      #
      # @return [Boolean]
      #
      def session?
        attributes["session"]
      end

      #
      # Specifies when the cookie will expire.
      #
      # @return [Time, nil]
      #
      def expires
        Time.at(attributes["expires"]) if attributes["expires"].positive?
      end

      #
      # The priority of the cookie.
      #
      # @return [String]
      #
      def priority
        @attributes["priority"]
      end

      #
      # @return [Boolean]
      #
      def sameparty?
        @attributes["sameParty"]
      end

      alias same_party? sameparty?

      #
      # @return [String]
      #
      def source_scheme
        @attributes["sourceScheme"]
      end

      #
      # @return [Integer]
      #
      def source_port
        @attributes["sourcePort"]
      end

      #
      # Compares different cookie objects.
      #
      # @return [Boolean]
      #
      def ==(other)
        other.class == self.class && other.attributes == attributes
      end

      #
      # Converts the cookie back into a raw cookie String.
      #
      # @return [String]
      #   The raw cookie string.
      #
      def to_s
        string = String.new("#{@attributes['name']}=#{@attributes['value']}")

        @attributes.each do |key, value|
          case key
          when "name", "value" # no-op
          when "domain"   then string << "; Domain=#{value}"
          when "path"     then string << "; Path=#{value}"
          when "expires"  then string << "; Expires=#{Time.at(value).httpdate}"
          when "httpOnly" then string << "; httpOnly" if value
          when "secure"   then string << "; Secure"   if value
          end
        end

        string
      end

      alias to_h attributes
    end
  end
end
