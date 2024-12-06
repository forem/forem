# frozen_string_literal: true

require "anyway/optparse_config"
require "anyway/dynamic_config"

module Anyway # :nodoc:
  using RubyNext
  using Anyway::Ext::DeepDup
  using Anyway::Ext::DeepFreeze
  using Anyway::Ext::Hash

  using(Module.new do
    refine Object do
      def vm_object_id() = (object_id << 1).to_s(16)
    end
  end)

  # Base config class
  # Provides `attr_config` method to describe
  # configuration parameters and set defaults
  class Config
    PARAM_NAME = /^[a-z_](\w+)?$/

    # List of names that couldn't be used as config names
    # (the class instance methods we use)
    RESERVED_NAMES = %i[
      config_name
      env_prefix
      values
      class
      clear
      deconstruct_keys
      dig
      dup
      initialize
      load
      load_from_sources
      option_parser
      pretty_print
      raise_validation_error
      reload
      resolve_config_path
      tap
      to_h
      to_source_trace
      write_config_attr
      __type_caster__
    ].freeze

    ENV_OPTION_EXCLUDE_KEY = :except

    class Error < StandardError; end

    class ValidationError < Error; end

    include OptparseConfig
    include DynamicConfig

    class BlockCallback
      attr_reader :block

      def initialize(block)
        @block = block
      end

      def apply_to(config)
        config.instance_exec(&block)
      end
    end

    class NamedCallback
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def apply_to(config) = config.send(name)
    end

    class << self
      def attr_config(*args, **hargs)
        new_defaults = hargs.deep_dup
        new_defaults.stringify_keys!

        defaults.merge! new_defaults

        new_keys = ((args + new_defaults.keys) - config_attributes)

        validate_param_names! new_keys.map(&:to_s)

        new_keys.map!(&:to_sym)

        unless (reserved_names = (new_keys & RESERVED_NAMES)).empty?
          raise ArgumentError, "Can not use the following reserved names as config attrubutes: " \
            "#{reserved_names.sort.map(&:to_s).join(", ")}"
        end

        config_attributes.push(*new_keys)

        define_config_accessor(*new_keys)

        # Define predicate methods ("param?") for attributes
        # having `true` or `false` as default values
        new_defaults.each do |key, val|
          next unless val.is_a?(TrueClass) || val.is_a?(FalseClass)
          alias_method :"#{key}?", :"#{key}"
        end
      end

      def defaults
        return @defaults if instance_variable_defined?(:@defaults)

        @defaults = if superclass < Anyway::Config
          superclass.defaults.deep_dup
        else
          new_empty_config
        end
      end

      def config_attributes
        return @config_attributes if instance_variable_defined?(:@config_attributes)

        @config_attributes = if superclass < Anyway::Config
          superclass.config_attributes.dup
        else
          []
        end
      end

      def required(*names, env: nil)
        unknown_names = names - config_attributes
        raise ArgumentError, "Unknown config param: #{unknown_names.join(",")}" if unknown_names.any?

        names = filter_by_env(names, env)
        required_attributes.push(*names)
      end

      def filter_by_env(names, env)
        return names if env.nil? || env.to_s == current_env

        filtered_names = if env.is_a?(Hash)
          names_with_exclude_env_option(names, env)
        elsif env.is_a?(Array)
          names if env.flat_map(&:to_s).include?(current_env)
        end

        filtered_names || []
      end

      def current_env
        Settings.current_environment.to_s
      end

      def names_with_exclude_env_option(names, env)
        envs = env[ENV_OPTION_EXCLUDE_KEY]
        excluded_envs = [envs].flat_map(&:to_s)
        names if excluded_envs.none?(current_env)
      end

      def required_attributes
        return @required_attributes if instance_variable_defined?(:@required_attributes)

        @required_attributes = if superclass < Anyway::Config
          superclass.required_attributes.dup
        else
          []
        end
      end

      def on_load(*names, &block)
        raise ArgumentError, "Either methods or block should be specified, not both" if block && !names.empty?

        if block
          load_callbacks << BlockCallback.new(block)
        else
          load_callbacks.push(*names.map { NamedCallback.new(_1) })
        end
      end

      def load_callbacks
        return @load_callbacks if instance_variable_defined?(:@load_callbacks)

        @load_callbacks = if superclass <= Anyway::Config
          superclass.load_callbacks.dup
        else
          []
        end
      end

      def config_name(val = nil)
        return (@explicit_config_name = val.to_s) unless val.nil?

        return @config_name if instance_variable_defined?(:@config_name)

        @config_name = explicit_config_name || build_config_name
      end

      def explicit_config_name
        return @explicit_config_name if instance_variable_defined?(:@explicit_config_name)

        @explicit_config_name =
          if superclass.respond_to?(:explicit_config_name)
            superclass.explicit_config_name
          end
      end

      def explicit_config_name?() = !explicit_config_name.nil?

      def env_prefix(val = nil)
        return (@env_prefix = val.to_s.upcase) unless val.nil?

        return @env_prefix if instance_variable_defined?(:@env_prefix)

        @env_prefix = if superclass < Anyway::Config && superclass.explicit_config_name?
          superclass.env_prefix
        else
          config_name.upcase
        end
      end

      def new_empty_config() = {}

      def coerce_types(mapping)
        Utils.deep_merge!(coercion_mapping, mapping)
      end

      def coercion_mapping
        return @coercion_mapping if instance_variable_defined?(:@coercion_mapping)

        @coercion_mapping = if superclass < Anyway::Config
          superclass.coercion_mapping.deep_dup
        else
          {}
        end
      end

      def type_caster(val = nil)
        return @type_caster unless val.nil?

        @type_caster ||=
          if coercion_mapping.empty?
            fallback_type_caster
          else
            ::Anyway::TypeCaster.new(coercion_mapping, fallback: fallback_type_caster)
          end
      end

      def fallback_type_caster(val = nil)
        return (@fallback_type_caster = val) unless val.nil?

        return @fallback_type_caster if instance_variable_defined?(:@fallback_type_caster)

        @fallback_type_caster = if superclass < Anyway::Config
          superclass.fallback_type_caster.deep_dup
        else
          ::Anyway::AutoCast
        end
      end

      def disable_auto_cast!
        @fallback_type_caster = ::Anyway::NoCast
      end

      private

      def define_config_accessor(*names)
        names.each do |name|
          accessors_module.module_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{name}=(val)
              __trace__&.record_value(val, \"#{name}\", **Tracing.current_trace_source)
              values[:#{name}] = val
            end

            def #{name}
              values[:#{name}]
            end
          RUBY
        end
      end

      def accessors_module
        return @accessors_module if instance_variable_defined?(:@accessors_module)

        @accessors_module = Module.new.tap do |mod|
          include mod
        end
      end

      def build_config_name
        unless name
          raise "Please, specify config name explicitly for anonymous class " \
            "via `config_name :my_config`"
        end

        # handle two cases:
        # - SomeModule::Config => "some_module"
        # - SomeConfig => "some"
        unless name =~ /^(\w+)(::)?Config$/
          raise "Couldn't infer config name, please, specify it explicitly" \
            "via `config_name :my_config`"
        end

        Regexp.last_match[1].tap(&:downcase!)
      end

      def validate_param_names!(names)
        invalid_names = names.reject { |name| name =~ PARAM_NAME }
        return if invalid_names.empty?

        raise ArgumentError, "Invalid attr_config name: #{invalid_names.join(", ")}.\n" \
          "Valid names must satisfy /#{PARAM_NAME.source}/."
      end
    end

    on_load :validate_required_attributes!

    attr_reader :config_name, :env_prefix

    # Instantiate config instance.
    #
    # Example:
    #
    #   my_config = Anyway::Config.new()
    #
    #   # provide some values explicitly
    #   my_config = Anyway::Config.new({some: :value})
    #
    def initialize(overrides = nil)
      @config_name = self.class.config_name

      raise ArgumentError, "Config name is missing" unless @config_name

      @env_prefix = self.class.env_prefix
      @values = {}

      load(overrides)
    end

    def reload(overrides = nil)
      clear
      load(overrides)
      self
    end

    def clear
      values.clear
      @__trace__ = nil
      self
    end

    def load(overrides = nil)
      base_config = self.class.defaults.deep_dup

      trace = Tracing.capture do
        Tracing.trace!(:defaults) { base_config }

        config_path = resolve_config_path(config_name, env_prefix)

        load_from_sources(base_config, name: config_name, env_prefix:, config_path:)

        if overrides
          Tracing.trace!(:load) { overrides }

          Utils.deep_merge!(base_config, overrides)
        end
      end

      base_config.each do |key, val|
        write_config_attr(key.to_sym, val)
      end

      # Trace may contain unknown attributes
      trace&.keep_if { |key| self.class.config_attributes.include?(key.to_sym) }

      # Run on_load callbacks
      self.class.load_callbacks.each { _1.apply_to(self) }

      # Set trace after we write all the values to
      # avoid changing the source to accessor
      @__trace__ = trace

      self
    end

    def load_from_sources(base_config, **options)
      Anyway.loaders.each do |(_id, loader)|
        Utils.deep_merge!(base_config, loader.call(**options))
      end
      base_config
    end

    def dig(*keys) = values.dig(*keys)

    def to_h() = values.deep_dup.deep_freeze

    def dup
      self.class.allocate.tap do |new_config|
        %i[config_name env_prefix __trace__].each do |ivar|
          new_config.instance_variable_set(:"@#{ivar}", send(ivar).dup)
        end
        new_config.instance_variable_set(:@values, values.deep_dup)
      end
    end

    def resolve_config_path(name, env_prefix)
      Anyway.env.fetch(env_prefix).delete("conf") || Settings.default_config_path.call(name)
    end

    def deconstruct_keys(keys) = values.deconstruct_keys(keys)

    def to_source_trace() = __trace__&.to_h

    def inspect
      "#<#{self.class}:0x#{vm_object_id.rjust(16, "0")} config_name=\"#{config_name}\" env_prefix=\"#{env_prefix}\" " \
      "values=#{values.inspect}>"
    end

    def pretty_print(q)
      q.object_group self do
        q.nest(1) do
          q.breakable
          q.text "config_name=#{config_name.inspect}"
          q.breakable
          q.text "env_prefix=#{env_prefix.inspect}"
          q.breakable
          q.text "values:"
          q.pp __trace__
        end
      end
    end

    private

    attr_reader :values, :__trace__

    def validate_required_attributes!
      self.class.required_attributes.select do |name|
        values[name].nil? || (values[name].is_a?(String) && values[name].empty?)
      end.then do |missing|
        next if missing.empty?
        raise_validation_error "The following config parameters for `#{self.class.name}(config_name: #{self.class.config_name})` are missing or empty: #{missing.join(", ")}"
      end
    end

    def write_config_attr(key, val)
      key = key.to_sym
      return unless self.class.config_attributes.include?(key)

      val = __type_caster__.coerce(key, val)
      public_send(:"#{key}=", val)
    end

    def raise_validation_error(msg)
      raise ValidationError, msg
    end

    def __type_caster__
      self.class.type_caster
    end
  end
end
