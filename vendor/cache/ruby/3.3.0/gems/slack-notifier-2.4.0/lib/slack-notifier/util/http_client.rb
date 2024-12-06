# frozen_string_literal: true

require "net/http"

module Slack
  class Notifier
    class APIError < StandardError; end

    module Util
      class HTTPClient
        class << self
          def post uri, params
            HTTPClient.new(uri, params).call
          end
        end

        attr_reader :uri, :params, :http_options

        def initialize uri, params
          @uri          = uri
          @http_options = params.delete(:http_options) || {}
          @params       = params
        end

        # rubocop:disable Layout/IndentHeredoc
        def call
          http_obj.request(request_obj).tap do |response|
            unless response.is_a?(Net::HTTPSuccess)
              raise Slack::Notifier::APIError, <<-MSG
The slack API returned an error: #{response.body} (HTTP Code #{response.code})
Check the "Handling Errors" section on https://api.slack.com/incoming-webhooks for more information
MSG
            end
          end
        end
        # rubocop:enable Layout/IndentHeredoc

        private

          def request_obj
            req = Net::HTTP::Post.new uri.request_uri
            req.set_form_data params

            req
          end

          def http_obj
            http = Net::HTTP.new uri.host, uri.port
            http.use_ssl = (uri.scheme == "https")

            http_options.each do |opt, val|
              if http.respond_to? "#{opt}="
                http.send "#{opt}=", val
              else
                warn "Net::HTTP doesn't respond to `#{opt}=`, ignoring that option"
              end
            end

            http
          end
      end
    end
  end
end
