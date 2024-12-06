# frozen_string_literal: true

module Ferrum
  class Browser
    class Xvfb
      NOT_FOUND = "Could not find an executable for the Xvfb. Try to install " \
                  "it with your package manager"

      def self.start(*args)
        new(*args).tap(&:start)
      end

      attr_reader :screen_size, :display_id, :pid

      def initialize(options)
        @path = Binary.find("Xvfb")
        raise BinaryNotFoundError, NOT_FOUND unless @path

        @screen_size = "#{options.window_size.join('x')}x24"
        @display_id = (Time.now.to_f * 1000).to_i % 100_000_000
      end

      def start
        @pid = ::Process.spawn("#{@path} :#{display_id} -screen 0 #{screen_size}")
        ::Process.detach(@pid)
      end

      def to_env
        { "DISPLAY" => ":#{display_id}" }
      end
    end
  end
end
