require 'twitter/entity'

module Twitter
  class Entity
    class Symbol < Twitter::Entity
      # @return [String]
      attr_reader :text
    end
  end
end
