module SmartProperties
  class Error < ::ArgumentError; end
  class ConfigurationError < Error; end

  class AssignmentError < Error
    attr_accessor :sender
    attr_accessor :property

    def initialize(sender, property, message)
      @sender = sender
      @property = property
      super(message)
    end
  end

  class ConstructorArgumentForwardingError < Error
    def initialize(positional_arguments, keyword_arguments)
      argument_description = [
        generate_description("positional", positional_arguments.count),
        generate_description("keyword", keyword_arguments.count)
      ].compact

      arguments = positional_arguments + keyword_arguments.map { |name, value| "#{name}: #{value}" }

      super "Forwarding the following %s failed: %s" % [
        argument_description.join(" and "),
        arguments.join(", ")
      ]
    end

    private

    def generate_description(argument_type, argument_number)
      case argument_number
      when 0
        nil
      when 1
        "#{argument_type} argument"
      else
        "#{argument_number} #{argument_type} arguments"
      end
    end
  end

  class MissingValueError < AssignmentError
    def initialize(sender, property)
      super(
        sender,
        property,
        "%s requires the property %s to be set" % [
          sender.class.name,
          property.name
        ]
      )
    end

    def to_hash
      Hash[property.name, "must be set"]
    end
  end

  class InvalidValueError < AssignmentError
    attr_accessor :value

    def initialize(sender, property, value)
      @value = value

      super(
        sender,
        property,
        "%s does not accept %s as value for the property %s. Only accepts: %s" % [
          sender.class.name,
          value.inspect,
          property.name,
          accepter_message(sender, property)
        ]
      )
    end

    def to_hash
      Hash[property.name, "does not accept %s as value" % value.inspect]
    end

    private

    def accepter_message(sender, property)
      accepter = property.accepter
      if accepter.is_a?(Proc)
        return "Values passing lambda defined in #{accepter.source_location.join(' at line ')}"
      end
      accepter
    end
  end

  class InitializationError < Error
    attr_accessor :sender
    attr_accessor :properties

    def initialize(sender, properties)
      @sender = sender
      @properties = properties
      super(
        "%s requires the following properties to be set: %s" % [
          sender.class.name,
          properties.map(&:name).sort.join(', ')
        ]
      )
    end

    def to_hash
      properties.each_with_object({}) { |property, errors| errors[property.name] = "must be set" }
    end
  end
end
