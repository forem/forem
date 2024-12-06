# frozen_string_literal: true

module Slack
  class Notifier
    class Config
      def initialize
        @http_client = Util::HTTPClient
        @defaults    = {}
        @middleware  = %i[
          format_message
          format_attachments
          at
          channels
        ]
      end

      def http_client client=nil
        return @http_client if client.nil?
        raise ArgumentError, "the http client must respond to ::post" unless client.respond_to?(:post)

        @http_client = client
      end

      def defaults new_defaults=nil
        return @defaults if new_defaults.nil?
        raise ArgumentError, "the defaults must be a Hash" unless new_defaults.is_a?(Hash)

        @defaults = new_defaults
      end

      def middleware *args
        return @middleware if args.empty?

        @middleware =
          if args.length == 1 && args.first.is_a?(Array) || args.first.is_a?(Hash)
            args.first
          else
            args
          end
      end
    end
  end
end
