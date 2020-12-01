require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'A class double with the doubled class not loaded' do
      include_context "with isolated configuration"

      before do
        RSpec::Mocks.configuration.verify_doubled_constant_names = false
      end

      it 'includes the double name in errors for unexpected messages' do
        o = class_double("NonLoadedClass")
        expect {
          o.foo
        }.to fail_including('ClassDouble(NonLoadedClass)')
      end

      it 'allows any method to be stubbed' do
        o = class_double('NonloadedClass')
        allow(o).to receive(:undefined_instance_method).with(:arg).and_return(1)
        expect(o.undefined_instance_method(:arg)).to eq(1)
      end

      specify "trying to raise a class_double raises a TypeError", :unless => RUBY_VERSION == '1.9.2' do
        subject = Object.new
        class_double("StubbedError").as_stubbed_const
        allow(subject).to receive(:some_method).and_raise(StubbedError)
        expect { subject.some_method }.to raise_error(TypeError, 'exception class/object expected')
      end

      context "when stubbing a private module method" do
        before(:all) do
          Module.class_exec do
            private
            def use; end
          end
        end

        after(:all) do
          Module.class_exec do
            undef use
          end
        end

        it 'can mock private module methods' do
          double = Module.new
          allow(double).to receive(:use)
          expect { double.use }.to raise_error(/private method `use' called/)

          double = class_double("NonloadedClass")
          expect(double).to receive(:use).and_return(:ok)
          expect(double.use).to be(:ok)
        end
      end

      context "when the class const has been previously stubbed" do
        before { stub_const("NonLoadedClass", Class.new) }

        it "treats the class as being unloaded for `class_double('NonLoadedClass')`" do
          o = class_double("NonLoadedClass")
          allow(o).to receive(:undefined_method)
        end

        it "treats the class as being unloaded for `instance_double(NonLoadedClass)`" do
          o = class_double(NonLoadedClass)
          allow(o).to receive(:undefined_method)
        end
      end
    end
  end
end
