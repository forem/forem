require 'twitter/creatable'
require 'twitter/identity'

module Twitter
  module DirectMessages
    class WelcomeMessageWrapper < Twitter::Identity
      attr_reader :created_timestamp

      object_attr_reader 'DirectMessages::WelcomeMessage', :welcome_message

      def initialize(attrs)
        attrs = read_from_response(attrs)
        text = attrs.dig(:message_data, :text)
        urls = attrs.dig(:message_data, :entities, :urls)

        text.gsub!(urls[0][:url], urls[0][:expanded_url]) if urls.any?

        attrs[:welcome_message] = build_welcome_message(attrs, text)
        super
      end

    private

      # @return [Hash] Normalized hash of attrs
      def read_from_response(attrs)
        return attrs[:welcome_message] unless attrs[:welcome_message].nil?

        attrs
      end

      def build_welcome_message(attrs, text)
        {
          id: attrs[:id].to_i,
          created_at: Time.at(attrs[:created_timestamp].to_i / 1000.0),
          text: text,
          name: attrs[:name],
          entities: attrs.dig(:message_data, :entities),
        }
      end
    end
  end
end
