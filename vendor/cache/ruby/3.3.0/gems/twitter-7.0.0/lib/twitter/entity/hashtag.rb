require 'twitter/entity'

module Twitter
  class Entity
    class Hashtag < Twitter::Entity
      # @return [String]
      attr_reader :text
    end
  end
end
