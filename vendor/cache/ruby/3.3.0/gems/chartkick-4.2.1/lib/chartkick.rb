# modules
require "chartkick/enumerable"
require "chartkick/helper"
require "chartkick/version"

# integrations
require "chartkick/engine" if defined?(Rails)
require "chartkick/sinatra" if defined?(Sinatra)

if defined?(ActiveSupport.on_load)
  ActiveSupport.on_load(:action_view) do
    include Chartkick::Helper
  end
end

module Chartkick
  class << self
    attr_accessor :content_for
    attr_accessor :options
  end
  self.options = {}
end
