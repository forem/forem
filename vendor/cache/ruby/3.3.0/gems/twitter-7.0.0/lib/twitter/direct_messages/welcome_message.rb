require 'twitter/creatable'
require 'twitter/entities'
require 'twitter/identity'

module Twitter
  module DirectMessages
    class WelcomeMessage < Twitter::Identity
      include Twitter::Creatable
      include Twitter::Entities
      # @return [String]
      attr_reader :text
      # @return [String]
      attr_reader :name
      alias full_text text
    end
  end
end
