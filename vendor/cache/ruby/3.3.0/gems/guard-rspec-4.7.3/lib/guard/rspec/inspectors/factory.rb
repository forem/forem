require "guard/rspec/inspectors/simple_inspector.rb"
require "guard/rspec/inspectors/keeping_inspector.rb"
require "guard/rspec/inspectors/focused_inspector.rb"

module Guard
  class RSpec < Plugin
    module Inspectors
      class Factory
        class << self
          def create(options = {})
            case options[:failed_mode]
            when :focus  then FocusedInspector.new(options)
            when :keep   then KeepingInspector.new(options)
            else; SimpleInspector.new(options)
            end
          end

          private :new
        end
      end
    end
  end
end
