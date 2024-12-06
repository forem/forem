# frozen_string_literal: true

module Ferrum
  class Page
    module Animation
      #
      # Returns playback rate for CSS animations, defaults to `1`.
      #
      # @return [Integer]
      #
      def playback_rate
        command("Animation.getPlaybackRate")["playbackRate"]
      end

      #
      # Sets playback rate of CSS animations.
      #
      # @param [Integer] value
      #
      # @example
      #   browser = Ferrum::Browser.new
      #   browser.playback_rate = 2000
      #   browser.go_to("https://google.com")
      #   browser.playback_rate # => 2000
      #
      def playback_rate=(value)
        command("Animation.setPlaybackRate", playbackRate: value)
      end
    end
  end
end
