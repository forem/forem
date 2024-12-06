module Guard
  module Internals
    module Tracing
      def self.trace(mod, meth)
        meta = (class << mod; self; end)
        original_meth = "original_#{meth}".to_sym

        if mod.respond_to?(original_meth)
          fail "ALREADY TRACED: #{mod}.#{meth}"
        end

        meta.send(:alias_method, original_meth, meth)
        meta.send(:define_method, meth) do |*args, &block|
          yield(*args) if block_given?
          mod.send original_meth, *args, &block
        end
      end

      def self.untrace(mod, meth)
        meta = (class << mod; self; end)
        original_meth = "original_#{meth}".to_sym

        unless mod.respond_to?(original_meth)
          fail "NOT TRACED: #{mod}.#{meth} (no method: #{original_meth})"
        end

        meta.send(:remove_method, meth)
        meta.send(:alias_method, meth, original_meth)
        meta.send(:undef_method, original_meth)
      end
    end
  end
end
