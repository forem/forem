require 'twitter/creatable'
require 'twitter/identity'

module Twitter
  module DirectMessages
    class WelcomeMessageRuleWrapper < Twitter::Identity
      attr_reader :created_timestamp

      object_attr_reader 'DirectMessages::WelcomeMessageRule', :welcome_message_rule

      def initialize(attrs)
        attrs = read_from_response(attrs)

        attrs[:welcome_message_rule] = build_welcome_message_rule(attrs)
        super
      end

    private

      # @return [Hash] Normalized hash of attrs
      def read_from_response(attrs)
        return attrs[:welcome_message_rule] unless attrs[:welcome_message_rule].nil?

        attrs
      end

      def build_welcome_message_rule(attrs)
        {
          id: attrs[:id].to_i,
          created_at: Time.at(attrs[:created_timestamp].to_i / 1000.0),
          welcome_message_id: attrs[:welcome_message_id].to_i,
        }
      end
    end
  end
end
