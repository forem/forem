require 'twitter/entity'

module Twitter
  class Entity
    class URI < Twitter::Entity
      display_uri_attr_reader
      uri_attr_reader :expanded_uri, :uri
    end
  end
end
