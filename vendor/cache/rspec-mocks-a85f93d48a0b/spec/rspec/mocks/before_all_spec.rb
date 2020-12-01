require 'support/before_all_shared_example_group'

RSpec.describe "Using rspec-mocks features in before(:all) blocks" do
  describe "#stub_const" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        stub_const("SomeNewConst", Class.new)
      end

      it 'does not stub the const' do
        expect(defined?(SomeNewConst)).to be_falsey
      end
    end
  end

  describe "#hide_const(for an undefined const)" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        hide_const("Foo")
      end
    end
  end

  describe "#hide_const(for a defined const)" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        hide_const("Float")
      end

      it 'does not hide the const' do
        expect(defined?(Float)).to be_truthy
      end
    end
  end

  describe "allow(...).to receive_message_chain" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        allow(Object).to receive_message_chain(:foo, :bar)
      end
    end
  end

  describe "#expect(...).to receive" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        expect(Object).to receive(:foo)
      end
    end
  end

  describe "#allow(...).to receive" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        allow(Object).to receive(:foo)
      end
    end
  end

  describe "#expect_any_instance_of(...).to receive" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        expect_any_instance_of(Object).to receive(:foo)
      end
    end
  end

  describe "#allow_any_instance_of(...).to receive" do
    include_examples "fails in a before(:all) block" do
      def use_rspec_mocks
        allow_any_instance_of(Object).to receive(:foo)
      end
    end
  end
end
