require 'logger'

module Algolia
  class LoggerHelper
    # @param debug_file [nil|String] file used to output the logs
    #
    def self.create(debug_file = nil)
      file              = debug_file || (ENV['ALGOLIA_DEBUG'] ? File.new('debug.log') : $stderr)
      instance          = ::Logger.new file
      instance.progname = 'algolia'
      instance
    end
  end
end
