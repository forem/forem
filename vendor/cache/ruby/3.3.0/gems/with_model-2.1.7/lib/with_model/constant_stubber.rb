# frozen_string_literal: true

module WithModel
  class ConstantStubber
    def initialize(const_name)
      @const_name = const_name.to_sym
      @namespace = nil
      @original_value = nil
    end

    def stub_const(value)
      @namespace = namespace
      if @namespace.const_defined?(basename)
        @original_value = @namespace.const_get(basename)
        @namespace.__send__ :remove_const, basename
      end

      @namespace.const_set basename, value
    end

    def unstub_const
      if @namespace
        @namespace.__send__ :remove_const, basename
        @namespace.const_set basename, @original_value if @original_value
        @namespace = nil
      end
      @original_value = nil
    end

    private

    def namespace
      *namespace_parts, _ = lookup_list
      namespace_parts.reduce(Object) do |ns, ns_part|
        ns.const_get(ns_part.to_sym)
      end
    end

    def lookup_list
      @const_name.to_s.split('::')
    end

    def basename
      @basename ||= lookup_list.last
    end
  end
  private_constant :ConstantStubber
end
