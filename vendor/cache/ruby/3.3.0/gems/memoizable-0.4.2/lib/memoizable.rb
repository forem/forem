# encoding: utf-8

require 'monitor'
require 'thread_safe'

require 'memoizable/instance_methods'
require 'memoizable/method_builder'
require 'memoizable/module_methods'
require 'memoizable/memory'
require 'memoizable/version'

# Allow methods to be memoized
module Memoizable
  include InstanceMethods

  # Default freezer
  Freezer = lambda { |object| object.freeze }.freeze

  # Hook called when module is included
  #
  # @param [Module] descendant
  #   the module or class including Memoizable
  #
  # @return [self]
  #
  # @api private
  def self.included(descendant)
    super
    descendant.extend(ModuleMethods)
  end
  private_class_method :included

end # Memoizable
