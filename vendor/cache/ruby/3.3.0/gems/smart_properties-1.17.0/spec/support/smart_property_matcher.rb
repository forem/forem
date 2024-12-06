module Matchers
  class SmartPropertyMatcher
    attr_reader :property_name
    attr_reader :subject

    def initialize(property_name)
      @property_name = property_name
    end

    def matches?(subject)
      @subject = subject.is_a?(Class) ? subject : subject.class
      smart_property_enabled? && is_smart_property? && getters_and_setters_are_defined?
    end

    def does_not_match?(subject)
      @subject = subject.is_a?(Class) ? subject : subject.class
      !smart_property_enabled? || !is_smart_property?
    end

    def description
      "have smart property #{property_name}"
    end

    def failure_message
      return "expected #{subject.class.name} to have a property named #{property_name}" if smart_property_enabled?
      return "expected #{subject.class.name} to be smart property enabled"
    end

    def failure_message_when_negated
      "expected #{subject.class.name} to not have a property named #{property_name}"
    end
    alias negative_failure_message failure_message_when_negated

    private

    def smart_property_enabled?
      subject.ancestors.include?(::SmartProperties)
    end

    def is_smart_property?
      subject.properties[property_name].kind_of?(::SmartProperties::Property)
    end

    def getters_and_setters_are_defined?
      methods = subject.instance_methods
      methods.include?(property_name) && methods.include?(:"#{property_name}=")
    end
  end

  def have_smart_property(*args)
    SmartPropertyMatcher.new(*args)
  end
  alias has_smart_property have_smart_property
end

RSpec.configure do |spec|
  spec.include(Matchers)
end
