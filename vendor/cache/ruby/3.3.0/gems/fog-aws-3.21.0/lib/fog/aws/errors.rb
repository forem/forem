module Fog
  module AWS
    module Errors
      def self.match_error(error)
        if !Fog::AWS.json_response?(error.response)
          matchers = [
            lambda {|s| s.match(/(?:.*<Code>(.*)<\/Code>)(?:.*<Message>(.*)<\/Message>)/m)},
            lambda {|s| s.match(/.*<(.+Exception)>(?:.*<Message>(.*)<\/Message>)/m)}
          ]
          [error.message, error.response.body].each(&Proc.new {|s|
              matchers.each do |matcher|
                match = matcher.call(s)
                return {:code => match[1].split('.').last, :message => match[2]} if match
              end
            })
        else
          begin
            full_msg_error = Fog::JSON.decode(error.response.body)
            if (full_msg_error.has_key?('Message') || full_msg_error.has_key?('message')) &&
                (error.response.headers.has_key?('x-amzn-ErrorType') || full_msg_error.has_key?('__type'))
              matched_error = {
                :code    => full_msg_error['__type'] || error.response.headers['x-amzn-ErrorType'].split(':').first,
                :message => full_msg_error['Message'] || full_msg_error['message']
              }
              return matched_error
            end
          rescue Fog::JSON::DecodeError => e
            Fog::Logger.warning("Error parsing response json - #{e}")
          end
        end
        {} # we did not match the message or response body
      end
    end
  end
end
