module Honeybadger
  # @api private
  module Conversions
    module_function

    # Convert context into a Hash.
    #
    # @param [Object] object The context object.
    #
    # @return [Hash] The hash context.
    def Context(object)
      object = object.to_honeybadger_context if object.respond_to?(:to_honeybadger_context)
      Hash(object)
    end
  end
end
