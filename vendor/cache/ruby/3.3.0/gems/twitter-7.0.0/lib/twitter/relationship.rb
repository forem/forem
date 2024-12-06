require 'twitter/base'

module Twitter
  class Relationship < Twitter::Base
    object_attr_reader :SourceUser, :source
    object_attr_reader :TargetUser, :target

    # Initializes a new object
    #
    # @param attrs [Hash]
    # @return [Twitter::Relationship]
    def initialize(attrs = {})
      @attrs = attrs[:relationship]
    end
  end
end
