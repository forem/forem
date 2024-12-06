# encoding: utf-8

module Memoizable

  # Build the memoized method
  class MethodBuilder

    # Raised when the method arity is invalid
    class InvalidArityError < ArgumentError

      # Initialize an invalid arity exception
      #
      # @param [Module] descendant
      # @param [Symbol] method
      # @param [Integer] arity
      #
      # @api private
      def initialize(descendant, method, arity)
        super("Cannot memoize #{descendant}##{method}, its arity is #{arity}")
      end

    end # InvalidArityError

    # Raised when a block is passed to a memoized method
    class BlockNotAllowedError < ArgumentError

      # Initialize a block not allowed exception
      #
      # @param [Module] descendant
      # @param [Symbol] method
      #
      # @api private
      def initialize(descendant, method)
        super("Cannot pass a block to #{descendant}##{method}, it is memoized")
      end

    end # BlockNotAllowedError

    # The original method before memoization
    #
    # @return [UnboundMethod]
    #
    # @api public
    attr_reader :original_method

    # Initialize an object to build a memoized method
    #
    # @param [Module] descendant
    # @param [Symbol] method_name
    # @param [#call] freezer
    #
    # @return [undefined]
    #
    # @api private
    def initialize(descendant, method_name, freezer)
      @descendant          = descendant
      @method_name         = method_name
      @freezer             = freezer
      @original_visibility = visibility
      @original_method     = @descendant.instance_method(@method_name)
      assert_arity(@original_method.arity)
    end

    # Build a new memoized method
    #
    # @example
    #   method_builder.call  # => creates new method
    #
    # @return [MethodBuilder]
    #
    # @api public
    def call
      remove_original_method
      create_memoized_method
      set_method_visibility
      self
    end

  private

    # Assert the method arity is zero
    #
    # @param [Integer] arity
    #
    # @return [undefined]
    #
    # @raise [InvalidArityError]
    #
    # @api private
    def assert_arity(arity)
      if arity.nonzero?
        fail InvalidArityError.new(@descendant, @method_name, arity)
      end
    end

    # Remove the original method
    #
    # @return [undefined]
    #
    # @api private
    def remove_original_method
      name = @method_name
      @descendant.module_eval { undef_method(name) }
    end

    # Create a new memoized method
    #
    # @return [undefined]
    #
    # @api private
    def create_memoized_method
      name, method, freezer = @method_name, @original_method, @freezer
      @descendant.module_eval do
        define_method(name) do |&block|
          fail BlockNotAllowedError.new(self.class, name) if block
          memoized_method_cache.fetch(name) do
            freezer.call(method.bind(self).call)
          end
        end
      end
    end

    # Set the memoized method visibility to match the original method
    #
    # @return [undefined]
    #
    # @api private
    def set_method_visibility
      @descendant.send(@original_visibility, @method_name)
    end

    # Get the visibility of the original method
    #
    # @return [Symbol]
    #
    # @api private
    def visibility
      if    @descendant.private_method_defined?(@method_name)   then :private
      elsif @descendant.protected_method_defined?(@method_name) then :protected
      else                                                           :public
      end
    end

  end # MethodBuilder
end # Memoizable
