require 'nenv/environment'

module Nenv
  module Builder
    def self.build(&block)
      Class.new(Nenv::Environment, &block)
    end
  end
end
