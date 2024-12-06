require 'nenv/version'

require 'nenv/autoenvironment'
require 'nenv/builder'

def Nenv(namespace = nil)
  Nenv::AutoEnvironment.new(namespace).tap do |env|
    yield env if block_given?
  end
end

module Nenv
  class << self
    def respond_to?(meth)
      instance.respond_to?(meth)
    end

    def method_missing(meth, *args)
      instance.send(meth, *args)
    end

    def reset
      @instance = nil
    end

    def instance
      @instance ||= Nenv::AutoEnvironment.new
    end
  end
end
