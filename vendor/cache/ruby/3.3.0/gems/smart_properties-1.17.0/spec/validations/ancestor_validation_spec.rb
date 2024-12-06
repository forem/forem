# frozen_string_literal: true
require 'spec_helper'
require 'smart_properties/validations/ancestor'

RSpec.describe SmartProperties::Validations::Ancestor, 'validates ancestor' do
  context 'used to validate the ancestor of a smart_properties value' do
    let!(:test_base) do
      Class.new do
        def self.to_s
          'TestBase'
        end
      end
    end

    subject(:klass) do
      test_base_ref = test_base

      DummyClass.new do
        property :visible, accepts: SmartProperties::Validations::Ancestor.must_be(type: test_base_ref)
      end
    end

    it 'should return an error for any non Class based value' do
      expect { subject.new(visible: true) }
        .to raise_error(SmartProperties::InvalidValueError, /Only accepts: subclasses of TestBase/)
    end

    it 'should return an error for any Class instance instead of a class type' do
      non_ancestor_class = Class.new

      expect { subject.new(visible: non_ancestor_class.new) }
        .to raise_error(SmartProperties::InvalidValueError, /Only accepts: subclasses of TestBase/)
    end


    it 'should return an error for any Class instance instead of a class type even if it is a child' do
      test_base_child = Class.new(test_base)

      expect { subject.new(visible: test_base_child.new) }
        .to raise_error(SmartProperties::InvalidValueError, /Only accepts: subclasses of TestBase/)
    end

    it 'should return an error for a Class type that is not a child of the required ancestor' do
      non_ancestor_class = Class.new

      expect { subject.new(visible: non_ancestor_class) }
        .to raise_error(SmartProperties::InvalidValueError, /Only accepts: subclasses of TestBase/)
    end

    it 'should return an error if the class is the ancestor itself' do
      expect { subject.new(visible: test_base) }
        .to raise_error(SmartProperties::InvalidValueError, /Only accepts: subclasses of TestBase/)
    end

    it 'should succeed if the given class is a subtype ' do
      test_valid_class = Class.new(test_base)

      expect { subject.new(visible: test_valid_class) }
        .not_to raise_error
    end
  end
end
