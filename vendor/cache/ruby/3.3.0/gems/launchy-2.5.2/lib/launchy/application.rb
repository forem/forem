require 'set'
module Launchy
  #
  # Application is the base class of all the application types that launchy may
  # invoke. It essentially defines the public api of the launchy system.
  #
  # Every class that inherits from Application must define:
  #
  # 1. A constructor taking no parameters
  # 2. An instance method 'open' taking a string or URI as the first parameter and a
  #    hash as the second
  # 3. A class method 'handles?' that takes a String and returns true if that
  #    class can handle the input.
  class Application
    extend DescendantTracker

    class << self
      # Find the application that handles the given uri.
      #
      # returns the Class that can handle the uri
      def handling( uri )
        klass = find_child( :handles?, uri )
        return klass if klass
        raise ApplicationNotFoundError, "No application found to handle '#{uri}'"
      end

      #
      # Find the given executable in the available paths
      def find_executable( bin, *paths )
        paths = Launchy.path.split( File::PATH_SEPARATOR ) if paths.empty?
        paths.each do |path|
          file = File.join( path, bin )
          if File.executable?( file ) then
            Launchy.log "#{self.name} : found executable #{file}"
            return file
          end
        end
        Launchy.log "#{self.name} : Unable to find `#{bin}' in #{paths.join(", ")}"
        return nil
      end
    end

    attr_reader :host_os_family
    attr_reader :ruby_engine
    attr_reader :runner

    def initialize
      @host_os_family = Launchy::Detect::HostOsFamily.detect
      @ruby_engine    = Launchy::Detect::RubyEngine.detect
      @runner         = Launchy::Detect::Runner.detect
    end

    def find_executable( bin, *paths )
      Application.find_executable( bin, *paths )
    end

    def run( cmd, *args )
      runner.run( cmd, *args )
    end
  end
end
require 'launchy/applications/browser'
