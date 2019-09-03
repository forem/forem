module Quickin
  class Engine < ::Rails::Engine
    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        require_dependency(c)
      end
    end
    config.to_prepare(&method(:activate).to_proc)
  end
end
