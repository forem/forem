module RSpec
  module Mocks
    RSpec.describe "stub implementation" do
      describe "with no args" do
        it "execs the block when called" do
          obj = double
          allow(obj).to receive(:foo) { :bar }
          expect(obj.foo).to eq :bar
        end
      end

      describe "with one arg" do
        it "execs the block with that arg when called" do
          obj = double
          allow(obj).to receive(:foo) { |given| given }
          expect(obj.foo(:bar)).to eq :bar
        end
      end

      describe "with variable args" do
        it "execs the block when called" do
          obj = double
          allow(obj).to receive(:foo) { |*given| given.first }
          expect(obj.foo(:bar)).to eq :bar
        end
      end
    end

    RSpec.describe "unstubbing with `and_call_original`" do
      it "replaces the stubbed method with the original method" do
        obj = Object.new
        def obj.foo; :original; end
        allow(obj).to receive(:foo)
        allow(obj).to receive(:foo).and_call_original
        expect(obj.foo).to eq :original
      end

      it "removes all stubs with the supplied method name" do
        obj = Object.new
        def obj.foo; :original; end
        allow(obj).to receive(:foo).with(1)
        allow(obj).to receive(:foo).with(2)
        allow(obj).to receive(:foo).and_call_original
        expect(obj.foo).to eq :original
      end

      it "does not remove any expectations with the same method name" do
        obj = Object.new
        def obj.foo; :original; end
        expect(obj).to receive(:foo).with(3).and_return(:three)
        allow(obj).to receive(:foo).with(1)
        allow(obj).to receive(:foo).with(2)
        allow(obj).to receive(:foo).and_call_original
        expect(obj.foo(3)).to eq :three
      end

      shared_examples_for "stubbing `new` on class objects" do
        it "restores the correct implementations when stubbed and unstubbed on a parent and child class" do
          parent = stub_const("Parent", Class.new)
          child  = stub_const("Child", Class.new(parent))

          allow(parent).to receive(:new)
          allow(child).to receive(:new)
          allow(parent).to receive(:new).and_call_original
          allow(child).to receive(:new).and_call_original

          expect(parent.new).to be_an_instance_of parent
          expect(child.new).to be_an_instance_of child
        end

        it "restores the correct implementations when stubbed and unstubbed on a grandparent and grandchild class" do
          grandparent = stub_const("GrandParent", Class.new)
          parent      = stub_const("Parent", Class.new(grandparent))
          child       = stub_const("Child", Class.new(parent))

          allow(grandparent).to receive(:new)
          allow(child).to receive(:new)
          allow(grandparent).to receive(:new).and_call_original
          allow(child).to receive(:new).and_call_original

          expect(grandparent.new).to be_an_instance_of grandparent
          expect(child.new).to be_an_instance_of child
        end
      end

      context "when partial doubles are not verified" do
        before { expect(RSpec::Mocks.configuration.verify_partial_doubles?).to be false }
        include_examples "stubbing `new` on class objects"
      end

      context "when partial doubles are verified" do
        include_context "with isolated configuration"
        before { RSpec::Mocks.configuration.verify_partial_doubles = true }
        include_examples "stubbing `new` on class objects"
      end
    end
  end
end
