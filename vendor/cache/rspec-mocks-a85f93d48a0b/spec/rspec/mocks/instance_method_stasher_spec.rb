module RSpec
  module Mocks
    RSpec.describe InstanceMethodStasher do
      class ExampleClass
        def hello
          :hello_defined_on_class
        end
      end

      def singleton_class_for(obj)
        class << obj; self; end
      end

      def stasher_for(obj, method_name)
        InstanceMethodStasher.new(obj, method_name)
      end

      it "stashes the current implementation of an instance method so it can be temporarily replaced" do
        obj = Object.new
        def obj.hello; :hello_defined_on_singleton_class; end;

        stashed_method = stasher_for(obj, :hello)
        stashed_method.stash

        with_isolated_stderr { def obj.hello; :overridden_hello; end }
        expect(obj.hello).to eql :overridden_hello

        stashed_method.restore
        expect(obj.hello).to eql :hello_defined_on_singleton_class
      end

      it "stashes private instance methods" do
        obj = Object.new
        def obj.hello; :hello_defined_on_singleton_class; end;
        singleton_class_for(obj).__send__(:private, :hello)

        stashed_method = stasher_for(obj, :hello)
        stashed_method.stash

        with_isolated_stderr { def obj.hello; :overridden_hello; end }
        stashed_method.restore
        expect(obj.send(:hello)).to eql :hello_defined_on_singleton_class
      end

      it "only stashes methods directly defined on the given class, not its ancestors" do
        obj = ExampleClass.new

        stashed_method = stasher_for(obj, :hello)
        stashed_method.stash

        def obj.hello; :overridden_hello; end;
        expect(obj.hello).to eql :overridden_hello

        stashed_method.restore
        expect(obj.hello).to eql :overridden_hello
      end

      it "does not unnecessarily create obfuscated aliased methods", :if => (RUBY_VERSION.to_f > 1.8) do
        obj = Object.new
        def obj.hello; :hello_defined_on_singleton_class; end;

        stashed_method = stasher_for(obj, :hello)
        stashed_method.stash
        expect(obj.methods.grep(/rspec/)).to eq([])
      end

      it "undefines the original method", :if => (RUBY_VERSION.to_f > 1.8) do
        obj = Object.new
        def obj.hello; :hello_defined_on_singleton_class; end;

        stashed_method = stasher_for(obj, :hello)
        stashed_method.stash

        expect(obj.methods).not_to include(:hello)
        expect(obj).not_to respond_to(:hello)
      end
    end
  end
end
