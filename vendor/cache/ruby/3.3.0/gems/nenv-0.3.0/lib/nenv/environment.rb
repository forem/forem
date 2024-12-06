require 'nenv/environment/dumper'
require 'nenv/environment/loader'

module Nenv
  class Environment
    class Error < ArgumentError
    end

    class MethodError < Error
      def initialize(meth)
        @meth = meth
      end
    end

    class AlreadyExistsError < MethodError
      def message
        format('Method %s already exists', @meth.inspect)
      end
    end

    def initialize(namespace = nil)
      @namespace = (namespace ? namespace.upcase : nil)
    end

    def create_method(meth, &block)
      self.class._create_env_accessor(singleton_class, meth, &block)
    end

    private

    def _sanitize(meth)
      meth.to_s[/^([^=?]*)[=?]?$/, 1].upcase
    end

    def _namespaced_sanitize(meth)
      [@namespace, _sanitize(meth)].compact.join('_')
    end

    class << self
      def create_method(meth, &block)
        _create_env_accessor(self, meth, &block)
      end

      def _create_env_accessor(klass, meth, &block)
        _fail_if_accessor_exists(klass, meth)

        if meth.to_s.end_with? '='
          _create_env_writer(klass, meth, &block)
        else
          _create_env_reader(klass, meth, &block)
        end
      end

      private

      def _create_env_writer(klass, meth, &block)
        env_name = nil
        dumper = nil
        klass.send(:define_method, meth) do |raw_value|
          env_name ||= _namespaced_sanitize(meth)
          dumper ||= Dumper.setup(&block)
          ENV[env_name] = dumper.(raw_value)
        end
      end

      def _create_env_reader(klass, meth, &block)
        env_name = nil
        loader = nil
        klass.send(:define_method, meth) do
          env_name ||= _namespaced_sanitize(meth)
          loader ||= Loader.setup(meth, &block)
          loader.(ENV[env_name])
        end
      end

      def _fail_if_accessor_exists(klass, meth)
        fail(AlreadyExistsError, meth) if klass.method_defined?(meth)
      end
    end
  end
end
