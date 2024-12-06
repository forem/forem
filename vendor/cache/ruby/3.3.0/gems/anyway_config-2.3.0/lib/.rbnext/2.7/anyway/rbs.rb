# frozen_string_literal: true
using RubyNext;
module Anyway
  module RBSGenerator
    TYPE_TO_CLASS = {
      string: "String",
      integer: "Integer",
      float: "Float",
      date: "Date",
      datetime: "DateTime",
      uri: "URI",
      boolean: "bool"
    }.freeze

    # Generate RBS signature from a config class
    def to_rbs
      *namespace, class_name = name.split("::")

      buf = []
      indent = 0
      interface_name = "_Config"

      if namespace.empty?
        interface_name = "_#{class_name}"
      else
        buf << "module #{namespace.join("::")}"
        indent += 1
      end

      # Using interface emulates a module we include to provide getters and setters
      # (thus making `super` possible)
      buf << "#{"  " * indent}interface #{interface_name}"
      indent += 1

      # Generating setters and getters for config attributes
      config_attributes.each do |param|
        type = coercion_mapping[param] || defaults[param.to_s]

        type =
          case; when ((__m__ = type)) && false 
          when (NilClass === __m__)
            "untyped"
          when (Symbol === __m__)
            TYPE_TO_CLASS.fetch(type) { defaults[param] ? "Symbol" : "untyped" }
          when (Array === __m__)
            "Array[untyped]"
          when ((__m__.respond_to?(:deconstruct_keys) && (((__m_hash__src__ = __m__.deconstruct_keys(nil)) || true) && (Hash === __m_hash__src__ || Kernel.raise(TypeError, "#deconstruct_keys must return Hash"))) && (__m_hash__ = __m_hash__src__.dup)) && ((__m_hash__.key?(:array) && __m_hash__.key?(:type)) && (((array = __m_hash__.delete(:array)) || true) && (((type = __m_hash__.delete(:type)) || true) && __m_hash__.empty?))))
            "Array[#{TYPE_TO_CLASS.fetch(type, "untyped")}]"
          when (Hash === __m__)
            "Hash[string,untyped]"
          when ((TrueClass === __m__) || (FalseClass === __m__))
            "bool"
          else
            type.class.to_s
          end

        getter_type = type
        getter_type = "#{type}?" unless required_attributes.include?(param)

        buf << "#{"  " * indent}def #{param}: () -> #{getter_type}"
        buf << "#{"  " * indent}def #{param}=: (#{type}) -> void"

        if type == "bool" || type == "bool?"
          buf << "#{"  " * indent}def #{param}?: () -> #{getter_type}"
        end
      end

      indent -= 1
      buf << "#{"  " * indent}end"

      buf << ""

      buf << "#{"  " * indent}class #{class_name} < #{superclass.name}"
      indent += 1

      buf << "#{"  " * indent}include #{interface_name}"

      indent -= 1
      buf << "#{"  " * indent}end"

      unless namespace.empty?
        buf << "end"
      end

      buf << ""

      buf.join("\n")
    end
  end

  Config.extend RBSGenerator
end
