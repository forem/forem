module VCR
  # @private
  module VariableArgsBlockCaller
    def call_block(block, *args)
      if block.arity >= 0
        args = args.first([args.size, block.arity].min)
      end

      block.call(*args)
    end
  end
end

