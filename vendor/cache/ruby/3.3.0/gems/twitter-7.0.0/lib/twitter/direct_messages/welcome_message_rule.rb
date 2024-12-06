require 'twitter/creatable'
require 'twitter/identity'

module Twitter
  module DirectMessages
    class WelcomeMessageRule < Twitter::Identity
      include Twitter::Creatable
      # @return [Integer]
      attr_reader :welcome_message_id
    end
  end
end
