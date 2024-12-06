require 'spec_helper'

RSpec.describe SmartProperties, 'default values' do
  context 'when used to build a class that has a property called :id whose default value is a lambda statement for retrieving the object_id' do
    subject(:klass) { DummyClass.new { property :id, default: lambda { object_id } } }

    context "an instance of this class" do
      it "should evaluate the lambda in its own scope and thus differ from every other instance" do
        first_instance, second_instance = klass.new, klass.new
        expect(first_instance.id).to_not eq(second_instance.id)
      end
    end
  end

  context 'when used to build a class that has a property called :boom whose default value is a lambda statement that raises an exception' do
    subject(:klass) { DummyClass.new { property :boom, default: lambda { raise 'Boom!' } } }

    context "an instance of this class" do
      it "should raise during initialization if no other value for :boom has been provided" do
        expect { klass.new }.to raise_error(RuntimeError, 'Boom!')
      end

      it "should not evaluate the lambda expression and thus not raise during initialization if a different value for :boom has been provided as a a parameter or in the initalization block" do
        expect { klass.new(boom: 'Everything is just fine!') }.not_to raise_error
        expect { klass.new { |inst| inst.boom = 'Everything is just fine!' } }.not_to raise_error
      end
    end
  end

  context "when building a class that has a property with a default value" do
    subject(:klass) { DummyClass.new { property :title, default: 'Lorem Ipsum' } }

    context 'an instance of that class' do
      it 'should return nil for the title when the title was explicitly set to this value during initialization' do
        instance = klass.new(title: nil)
        expect(instance.title).to be_nil
        expect(instance[:title]).to be_nil
      end

      it 'should return the default value if no other value has been provided during initialization' do
        instance = klass.new
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')

        instance = klass.new {}
        expect(instance.title).to eq('Lorem Ipsum')
        expect(instance[:title]).to eq('Lorem Ipsum')
      end
    end
  end

  context "when defining a new property with a literal default value" do
    context 'with a numeric default' do
      subject(:klass) { DummyClass.new { property :var, default: 123 } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(be(123))
      end
    end

    context 'with a string default' do
      DEFAULT_VALUE = 'a string'
      subject(:klass) { DummyClass.new { property :var, default: DEFAULT_VALUE } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(eq(DEFAULT_VALUE))
      end

      it 'returns a copy of the string' do
        instance = klass.new
        expect(instance.var).to_not(be(DEFAULT_VALUE))
      end

      it 'mutating the instance variable does not mutate the original' do
        instance = klass.new
        instance.var[0] = 'o'
        expect(DEFAULT_VALUE).to(eq('a string'))
      end
    end

    context 'with a range default' do
      subject(:klass) { DummyClass.new { property :var, default: 1..2 } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(eq(1..2))
      end
    end

    context 'with a true default' do
      subject(:klass) { DummyClass.new { property :var, default: true } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(be(true))
      end
    end

    context 'with a false default' do
      subject(:klass) { DummyClass.new { property :var, default: false } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(be(false))
      end
    end

    context 'with a symbol default' do
      subject(:klass) { DummyClass.new { property :var, default: :foo } }

      it 'accepts the default and returns it' do
        instance = klass.new
        expect(instance.var).to(be(:foo))
      end
    end
  end
end
