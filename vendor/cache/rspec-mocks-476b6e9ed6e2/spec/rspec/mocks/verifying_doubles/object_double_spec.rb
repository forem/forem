require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'An object double' do
      let(:loaded_instance) { LoadedClass.new(1, 2) }

      it 'can replace an unloaded constant' do
        o = object_double("LoadedClass::NOINSTANCE").as_stubbed_const

        expect(LoadedClass::NOINSTANCE).to eq(o)

        expect(o).to receive(:undefined_instance_method)
        o.undefined_instance_method
      end

      it 'can replace a constant by name and verify instance methods' do
        o = object_double("LoadedClass::INSTANCE").as_stubbed_const

        expect(LoadedClass::INSTANCE).to eq(o)

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
        prevents { o.defined_instance_method }

        expect(o).to receive(:defined_instance_method)
        o.defined_instance_method
        expect(o).to receive(:defined_private_method)
        o.send :defined_private_method
      end

      it 'can create a double that matches the interface of any arbitrary object' do
        o = object_double(loaded_instance)

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
        prevents { o.defined_instance_method }

        expect(o).to receive(:defined_instance_method)
        o.defined_instance_method
        expect(o).to receive(:defined_private_method)
        o.send :defined_private_method
      end

      it 'does not allow transferring constants to an object' do
        expect {
          object_double("LoadedClass::INSTANCE").
            as_stubbed_const(:transfer_nested_constants => true)
        }.to raise_error(/Cannot transfer nested constants/)
      end

      it 'does not allow as_stubbed_constant for real objects' do
        expect {
          object_double(loaded_instance).as_stubbed_const
        }.to raise_error(/Can not perform constant replacement with an anonymous object/)
      end

      it 'is not a module' do
        expect(object_double("LoadedClass::INSTANCE")).to_not be_a(Module)
      end

      it 'validates `with` args against the method signature when stubbing a method' do
        dbl = object_double(loaded_instance)
        prevents(/Wrong number of arguments. Expected 2, got 3./) {
          allow(dbl).to receive(:instance_method_with_two_args).with(3, :foo, :args)
        }
      end

      context "when a loaded object constant has previously been stubbed with an object" do
        before { stub_const("LoadedClass::INSTANCE", Object.new) }

        it "uses the original object to verify against for `object_double('ConstName')`" do
          o = object_double("LoadedClass::INSTANCE")
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_meth) }
        end

        it "uses the stubbed const value to verify against for `object_double(ConstName)`, " \
           "which probably isn't what the user wants, but there's nothing else we can do since " \
           "we can't get the constant name from the given object and thus cannot interrogate " \
           "our stubbed const registry to see it has been stubbed" do
          o = object_double(LoadedClass::INSTANCE)
          prevents { allow(o).to receive(:defined_instance_method) }
        end
      end

      context "when a loaded object constant has previously been stubbed with a class" do
        before { stub_const("LoadedClass::INSTANCE", Class.new) }

        it "uses the original object to verify against for `object_double('ConstName')`" do
          o = object_double("LoadedClass::INSTANCE")
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_meth) }
        end

        it "uses the original object to verify against for `object_double(ConstName)`" do
          o = object_double(LoadedClass::INSTANCE)
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_meth) }
        end
      end

      context "when an unloaded object constant has previously been stubbed with an object" do
        before { stub_const("LoadedClass::NOINSTANCE", LoadedClass::INSTANCE) }

        it "treats it as being unloaded for `object_double('ConstName')`" do
          o = object_double("LoadedClass::NOINSTANCE")
          allow(o).to receive(:undefined_method)
        end

        it "uses the stubbed const value to verify against for `object_double(ConstName)`, " \
           "which probably isn't what the user wants, but there's nothing else we can do since " \
           "we can't get the constant name from the given object and thus cannot interrogate " \
           "our stubbed const registry to see it has been stubbed" do
          o = object_double(LoadedClass::NOINSTANCE)
          allow(o).to receive(:defined_instance_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end

      context "when an unloaded object constant has previously been stubbed with a class" do
        before { stub_const("LoadedClass::NOINSTANCE", Class.new) }

        it "treats it as being unloaded for `object_double('ConstName')`" do
          o = object_double("LoadedClass::NOINSTANCE")
          allow(o).to receive(:undefined_method)
        end

        it "treats it as being unloaded for `object_double(ConstName)`" do
          o = object_double(LoadedClass::NOINSTANCE)
          allow(o).to receive(:undefined_method)
        end
      end
    end
  end
end
