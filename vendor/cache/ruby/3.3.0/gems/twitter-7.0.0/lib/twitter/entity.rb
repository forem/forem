require 'twitter/base'

module Twitter
  class Entity < Twitter::Base
    # @return [Array<Integer>]
    attr_reader :indices
  end
end
