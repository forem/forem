# frozen_string_literal: true

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
          case type
          in NilClass
            "untyped"
          in Symbol
            TYPE_TO_CLASS.fetch(type) { defaults[param] ? "Symbol" : "untyped" }
          in Array
            "Array[untyped]"
          in array:, type:, **nil
            "Array[#{TYPE_TO_CLASS.fetch(type, "untyped")}]"
          in Hash
            "Hash[string,untyped]"
          in TrueClass | FalseClass
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
