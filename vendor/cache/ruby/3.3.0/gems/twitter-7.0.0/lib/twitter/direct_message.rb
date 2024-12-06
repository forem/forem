require 'twitter/creatable'
require 'twitter/entities'
require 'twitter/identity'

module Twitter
  class DirectMessage < Twitter::Identity
    include Twitter::Creatable
    include Twitter::Entities
    # @return [String]
    attr_reader :text
    attr_reader :sender_id
    attr_reader :recipient_id
    alias full_text text
    object_attr_reader :User, :recipient
    object_attr_reader :User, :sender
  end
end
