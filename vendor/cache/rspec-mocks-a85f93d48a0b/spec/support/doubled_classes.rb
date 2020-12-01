class LoadedClass
  extend RSpec::Support::RubyFeatures

  M = :m
  N = :n
  INSTANCE = LoadedClass.new

  def initialize(_a, _b)
  end

  class << self
    def respond_to?(method_name, include_all=false)
      return true if method_name == :dynamic_class_method
      super
    end

    def defined_class_method
    end

    def send
      # fake out!
    end

    def defined_instance_and_class_method
    end

  protected

    def defined_protected_class_method
    end

  private

    def defined_private_class_method
    end
  end

  def defined_instance_method
  end

  def instance_method_with_two_args(_a, _b)
  end

  def instance_method_with_only_defaults(_a=1, _b=2)
  end

  def defined_instance_and_class_method
  end

  if required_kw_args_supported?
    # Need to eval this since it is invalid syntax on earlier rubies.
    eval <<-RUBY
      def kw_args_method(foo, optional_arg:'hello', required_arg:)
      end

      def mixed_args_method(foo, bar, optional_arg_1:1, optional_arg_2:2)
      end
    RUBY
  end

  def send(*)
  end

  def respond_to?(method_name, include_all=false)
    return true if method_name == :dynamic_instance_method
    super
  end

  class Nested; end

protected

  def defined_protected_method
  end

private

  def defined_private_method
    "wink wink ;)"
  end
end

class LoadedClassWithOverriddenName < LoadedClass
  def self.name
    "Overriding name is not a good idea but we can't count on users not doing this"
  end
end
