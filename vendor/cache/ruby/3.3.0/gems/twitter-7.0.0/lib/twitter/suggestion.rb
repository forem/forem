require 'equalizer'
require 'memoizable'
require 'twitter/base'

module Twitter
  class Suggestion < Twitter::Base
    include Equalizer.new(:slug)
    include Memoizable

    # @return [Integer]
    attr_reader :size
    # @return [String]
    attr_reader :name, :slug

    # @return [Array<Twitter::User>]
    def users
      @attrs.fetch(:users, []).collect do |user|
        User.new(user)
      end
    end
    memoize :users
  end
end
