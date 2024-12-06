module SmartProperties
  class Property
    MODULE_REFERENCE = :"@_smart_properties_method_scope"
    ALLOWED_DEFAULT_CLASSES = [Proc, Numeric, String, Range, TrueClass, FalseClass, NilClass, Symbol, Module].freeze

    attr_reader :name
    attr_reader :converter
    attr_reader :accepter
    attr_reader :reader
    attr_reader :instance_variable_name
    attr_reader :writable

    def self.define(scope, name, **options)
      new(name, **options).tap { |p| p.define(scope) }
    end

    def initialize(name, **attrs)
      attrs = attrs.dup

      @name      = name.to_sym
      @default   = attrs.delete(:default)
      @converter = attrs.delete(:converts)
      @accepter  = attrs.delete(:accepts)
      @required  = attrs.delete(:required)
      @reader    = attrs.delete(:reader)
      @writable  = attrs.delete(:writable)
      @reader    ||= @name

      @instance_variable_name = :"@#{name}"

      unless ALLOWED_DEFAULT_CLASSES.any? { |cls| @default.is_a?(cls) }
        raise ConfigurationError, "Default attribute value #{@default.inspect} cannot be specified as literal, "\
          "use the syntax `default: -> { ... }` instead."
      end

      unless attrs.empty?
        raise ConfigurationError, "SmartProperties do not support the following configuration options: #{attrs.keys.map { |m| m.to_s }.sort.join(', ')}."
      end
    end

    def required?(scope)
      @required.kind_of?(Proc) ? scope.instance_exec(&@required) : !!@required
    end

    def optional?(scope)
      !required?(scope)
    end

    def missing?(scope)
      required?(scope) && !present?(scope)
    end

    def present?(scope)
      !null_object?(get(scope))
    end

    def writable?
      return true if @writable.nil?
      @writable
    end

    def convert(scope, value)
      return value unless converter
      return value if null_object?(value)

      case converter
      when Symbol
        converter.to_proc.call(value)
      else
        scope.instance_exec(value, &converter)
      end
    end

    def default(scope)
      @default.kind_of?(Proc) ? scope.instance_exec(&@default) : @default.dup
    end

    def accepts?(value, scope)
      return true unless accepter
      return true if null_object?(value)

      if accepter.respond_to?(:to_proc)
        !!scope.instance_exec(value, &accepter)
      else
        Array(accepter).any? { |accepter| accepter === value }
      end
    end

    def prepare(scope, value)
      required = required?(scope)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      value = convert(scope, value)
      raise MissingValueError.new(scope, self) if required && null_object?(value)
      raise InvalidValueError.new(scope, self, value) unless accepts?(value, scope)
      value
    end

    def define(klass)
      property = self

      scope =
        if klass.instance_variable_defined?(MODULE_REFERENCE)
          klass.instance_variable_get(MODULE_REFERENCE)
        else
          m = Module.new
          klass.send(:include, m)
          klass.instance_variable_set(MODULE_REFERENCE, m)
          m
        end

      scope.send(:define_method, reader) do
        property.get(self)
      end

      if writable?
        scope.send(:define_method, :"#{name}=") do |value|
          property.set(self, value)
        end
      end
    end

    def set(scope, value)
      scope.instance_variable_set(instance_variable_name, prepare(scope, value))
    end

    def set_default(scope)
      return false if present?(scope)

      default_value = default(scope)
      return false if null_object?(default_value)

      set(scope, default_value)
      true
    end

    def get(scope)
      return nil unless scope.instance_variable_defined?(instance_variable_name)
      scope.instance_variable_get(instance_variable_name)
    end

    def to_h
      {
        accepter: @accepter,
        converter: @converter,
        default: @default,
        instance_variable_name: @instance_variable_name,
        name: @name,
        reader: @reader,
        required: @required
      }
    end

    private

    def null_object?(object)
      object.nil?
    rescue NoMethodError => error
      # BasicObject does not respond to #nil? by default, so we need to double
      # check if somebody implemented it and it fails internally or if the
      # error occured because the method is actually not present.
      
      # This is a workaround for the fact that #singleton_class is defined on Object, but not BasicObject.
      the_singleton_class = (class << object; self; end)
      
      if the_singleton_class.public_instance_methods.include?(:nil?)
        # object defines #nil?, but it raised NoMethodError,
        # something is wrong with the implementation, so raise the exception.
        raise error 
      else
        # treat the object as truthy because we don't know better.
        false 
      end
    end
  end
end
