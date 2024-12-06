module Rpush
  module Daemon
    module Wns
      class RawRequest
        def self.create(notification, access_token)
          body = notification.data.to_json
          uri = URI.parse(notification.uri)
          headers = {
            "Content-Length" => body.length.to_s,
            "Content-Type" => "application/octet-stream",
            "X-WNS-Type" => "wns/raw",
            "X-WNS-RequestForStatus" => "true",
            "Authorization" => "Bearer #{access_token}"
          }

          headers['X-WNS-PRIORITY'] = notification.priority.to_s if notification.priority

          post = Net::HTTP::Post.new(
            uri.request_uri,
            headers
          )

          post.body = body
          post
        end
      end
    end
  end
end
