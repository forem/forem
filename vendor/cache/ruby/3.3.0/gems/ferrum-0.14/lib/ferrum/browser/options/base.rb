# frozen_string_literal: true

require "singleton"

module Ferrum
  class Browser
    class Options
      class Base
        include Singleton

        def self.options
          instance
        end

        def to_h
          self.class::DEFAULT_OPTIONS
        end

        def except(*keys)
          to_h.reject { |n, _| keys.include?(n) }
        end

        def detect_path
          Binary.find(self.class::PLATFORM_PATH[Utils::Platform.name])
        end

        def merge_required(flags, options, user_data_dir)
          raise NotImplementedError
        end

        def merge_default(flags, options)
          raise NotImplementedError
        end
      end
    end
  end
end
