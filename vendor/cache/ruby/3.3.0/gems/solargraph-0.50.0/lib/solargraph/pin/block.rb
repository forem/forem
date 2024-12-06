# frozen_string_literal: true

module Solargraph
  module Pin
    class Block < Closure
      # The signature of the method that receives this block.
      #
      # @return [Parser::AST::Node]
      attr_reader :receiver

      # @param args [Array<Parameter>]
      def initialize receiver: nil, args: [], context: nil, **splat
        super(**splat)
        @receiver = receiver
        @context = context
        @parameters = args
      end

      # @param api_map [ApiMap]
      # @return [void]
      def rebind api_map
        @binder ||= binder_or_nil(api_map)
      end

      def binder
        @binder || closure.binder
      end

      # @return [Array<Parameter>]
      def parameters
        @parameters ||= []
      end

      # @return [Array<String>]
      def parameter_names
        @parameter_names ||= parameters.map(&:name)
      end

      private

      # @param api_map [ApiMap]
      # @return [ComplexType, nil]
      def binder_or_nil api_map
        return nil unless receiver
        word = receiver.children.find { |c| c.is_a?(::Symbol) }.to_s
        return nil unless api_map.rebindable_method_names.include?(word)
        chain = Parser.chain(receiver, location.filename)
        locals = api_map.source_map(location.filename).locals_at(location)
        links_last_word = chain.links.last.word
        if %w[instance_eval instance_exec class_eval class_exec module_eval module_exec].include?(links_last_word)
          return chain.base.infer(api_map, self, locals)
        end
        if 'define_method' == links_last_word and chain.define(api_map, self, locals).first&.path == 'Module#define_method' # change class type to instance type
          if chain.links.size > 1 # Class.define_method
            ty = chain.base.infer(api_map, self, locals)
            return Solargraph::ComplexType.parse(ty.namespace)
          else # define_method without self
            return Solargraph::ComplexType.parse(closure.binder.namespace)
          end
        end
        # other case without early return, read block yieldself tags
        receiver_pin = chain.define(api_map, self, locals).first
        if receiver_pin && receiver_pin.docstring
          ys = receiver_pin.docstring.tag(:yieldself)
          if ys && ys.types && !ys.types.empty?
            return ComplexType.try_parse(*ys.types).qualify(api_map, receiver_pin.context.namespace)
          end
        end
        nil
      end
    end
  end
end
