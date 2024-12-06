require 'memoizable'
require 'twitter/base'

module Twitter
  class ProfileBanner < Twitter::Base
    include Memoizable

    # Returns an array of photo sizes
    #
    # @return [Array<Twitter::Size>]
    def sizes
      @attrs.fetch(:sizes, []).each_with_object({}) do |(key, value), object|
        object[key] = Size.new(value)
      end
    end
    memoize :sizes
  end
end
