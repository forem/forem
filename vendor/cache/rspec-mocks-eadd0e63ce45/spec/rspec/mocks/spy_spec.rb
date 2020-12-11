require "spec_helper"

RSpec.describe "the spy family of methods" do
  describe "spy" do
    it "responds to arbitrary methods" do
      expect(spy.respond_to?(:foo)).to be true
    end

    it "takes a name" do
      expect(spy(:bacon_bits).inspect).to include("bacon_bits")
    end

    it "records called methods" do
      expect(spy.tap { |s| s.foo }).to have_received(:foo)
    end

    it "takes a hash of method names and return values" do
      expect(spy(:foo => :bar).foo).to eq(:bar)
    end

    it "takes a name and a hash of method names and return values" do
      expect(spy(:bacon_bits, :foo => :bar).foo).to eq(:bar)
    end
  end

  shared_examples_for "a verifying spy with a foo method" do
    it "responds to methods on the verified object" do
      expect(subject.respond_to?(:foo)).to be true
    end

    it "does not respond to methods that are not on the verified object" do
      expect(subject.respond_to?(:other_method)).to be false
    end

    it "records called methods" do
      expect(subject.tap { |s| s.foo }).to have_received(:foo)
    end

    it 'fails fast when `have_received` is passed an undefined method name' do
      expect {
        expect(subject).to have_received(:bar)
      }.to fail_including("does not implement")
    end

    it 'fails fast when negative `have_received` is passed an undefined method name' do
      expect {
        expect(subject).to_not have_received(:bar)
      }.to fail_including("does not implement")
    end
  end

  describe "instance_spy" do
    context "when passing a class object" do
      let(:the_class) do
        Class.new do
          def foo
            3
          end
        end
      end

      subject { instance_spy(the_class) }

      it_behaves_like "a verifying spy with a foo method"

      it "takes a class and a hash of method names and return values" do
        expect(instance_spy(the_class, :foo => :bar).foo).to eq(:bar)
      end
    end

    context "passing a class by string reference" do
      DummyClass = Class.new do
        def foo
          3
        end
      end

      let(:the_class) { "DummyClass" }

      subject { instance_spy(the_class) }

      it_behaves_like "a verifying spy with a foo method"

      it "takes a class name string and a hash of method names and return values" do
        expect(instance_spy(the_class, :foo => :bar).foo).to eq(:bar)
      end
    end
  end

  describe "object_spy" do
    let(:the_class) do
      Class.new do
        def foo
          3
        end
      end
    end

    let(:the_instance) { the_class.new }

    subject { object_spy(the_instance) }

    it_behaves_like "a verifying spy with a foo method"

    it "takes an instance and a hash of method names and return values" do
      expect(object_spy(the_instance, :foo => :bar).foo).to eq(:bar)
    end
  end

  describe "class_spy" do
    let(:the_class) do
      Class.new do
        def self.foo
          3
        end
      end
    end

    subject { class_spy(the_class) }

    it_behaves_like "a verifying spy with a foo method"

    it "takes a class and a hash of method names and return values" do
      expect(class_spy(the_class, :foo => :bar).foo).to eq(:bar)
    end
  end
end
