require 'set'

module Launchy
  #
  # Use by either
  #
  #   class Foo
  #     extend DescendantTracker
  #   end
  #
  # or
  #   
  #   class Foo
  #     class << self
  #       include DescendantTracker
  #     end
  #   end
  #
  # It will track all the classes that inherit from the extended class and keep
  # them in a Set that is available via the 'children' method.
  #
  module DescendantTracker
    def inherited( klass )
      return unless klass.instance_of?( Class )
      self.children << klass
    end

    #
    # The list of children that are registered
    #
    def children
      unless defined? @children
        @children = Array.new
      end
      return @children
    end

    #
    # Find one of the child classes by calling the given method
    # and passing all the rest of the parameters to that method in 
    # each child
    def find_child( method, *args )
      children.find do |child|
        Launchy.log "Checking if class #{child} is the one for #{method}(#{args.join(', ')})}"
        child.send( method, *args )
      end
    end
  end
end
