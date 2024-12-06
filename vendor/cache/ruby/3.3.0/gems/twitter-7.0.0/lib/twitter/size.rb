require 'equalizer'
require 'twitter/base'

module Twitter
  class Size < Twitter::Base
    include Equalizer.new(:h, :w)
    # @return [Integer]
    attr_reader :h, :w
    # @return [String]
    attr_reader :resize
    alias height h
    alias width w
  end
end
