require 'twitter/entity'

module Twitter
  class Entity
    class UserMention < Twitter::Entity
      # @return [Integer]
      attr_reader :id
      # @return [String]
      attr_reader :name, :screen_name
    end
  end
end
