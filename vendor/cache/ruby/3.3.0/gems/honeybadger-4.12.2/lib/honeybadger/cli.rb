$:.unshift(File.expand_path('../../../vendor/cli', __FILE__))

require 'thor'

require 'honeybadger/cli/main'

module Honeybadger
  # @api private
  module CLI
    def self.start(*args)
      Main.start(*args)
    end
  end
end
