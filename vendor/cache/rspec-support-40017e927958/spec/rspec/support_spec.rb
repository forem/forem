require 'rspec/support'
require 'rspec/support/spec/library_wide_checks'

module RSpec
  describe Support do
    extend Support::RubyFeatures

    it_behaves_like "library wide checks", "rspec-support",
      :consider_a_test_env_file => %r{rspec/support/spec},
      :allowed_loaded_feature_regexps => [
        /rbconfig/, # Used by RubyFeatures
        /prettyprint.rb/, /pp.rb/, /diff\/lcs/ # These are all loaded by the differ.
      ]

    describe '.method_handle_for(object, method_name)' do
      untampered_class = Class.new do
        def foo
          :bar
        end
      end

      http_request_class = Struct.new(:method, :uri)

      proxy_class = Struct.new(:original) do
        undef :=~, :method
        def method_missing(name, *args, &block)
          original.__send__(name, *args, &block)
        end
      end

      it 'fetches method definitions for vanilla objects' do
        object = untampered_class.new
        expect(Support.method_handle_for(object, :foo).call).to eq :bar
      end

      it 'fetches method definitions for objects with method redefined' do
        request = http_request_class.new(:get, "http://foo.com/")
        expect(Support.method_handle_for(request, :uri).call).to eq "http://foo.com/"
      end

      it 'fetches method definitions for proxy objects' do
        object = proxy_class.new([])
        expect(Support.method_handle_for(object, :=~)).to be_a Method
      end

      it 'fetches method definitions for proxy objects' do
        object = proxy_class.new([])
        expect(Support.method_handle_for(object, :=~)).to be_a Method
      end

      it 'fails with `NameError` when an undefined method is fetched ' +
         'from an object that has overriden `method` to raise an Exception' do
        object = double
        allow(object).to receive(:method).and_raise(Exception)
        expect {
          Support.method_handle_for(object, :some_undefined_method)
        }.to raise_error(NameError)
      end

      it 'fails with `NameError` when a method is fetched from an object ' +
         'that has overriden `method` to not return a method' do
        object = proxy_class.new(double(:method => :baz))
        expect {
          Support.method_handle_for(object, :=~)
        }.to raise_error(NameError)
      end

      context "for a BasicObject subclass", :if => RUBY_VERSION.to_f > 1.8 do
        let(:basic_class) do
          Class.new(BasicObject) do
            def foo
              :bar
            end
          end
        end

        let(:basic_class_with_method_override) do
          Class.new(basic_class) do
            def method
              :method
            end
          end
        end

        let(:basic_class_with_kernel) do
          Class.new(basic_class) do
            include ::Kernel
          end
        end

        let(:basic_class_with_proxying) do
          Class.new(BasicObject) do
            def method_missing(name, *args, &block)
              "foo".__send__(name, *args, &block)
            end
          end
        end

        it 'still works', :if => supports_rebinding_module_methods? do
          object = basic_class.new
          expect(Support.method_handle_for(object, :foo).call).to eq :bar
        end

        it 'works when `method` has been overriden', :if => supports_rebinding_module_methods? do
          object = basic_class_with_method_override.new
          expect(Support.method_handle_for(object, :foo).call).to eq :bar
        end

        it 'allows `method` to be proxied', :unless => supports_rebinding_module_methods? do
          object = basic_class_with_proxying.new
          expect(Support.method_handle_for(object, :reverse).call).to eq "oof"
        end

        it 'still works when Kernel has been mixed in' do
          object = basic_class_with_kernel.new
          expect(Support.method_handle_for(object, :foo).call).to eq :bar
        end
      end
    end

    describe '.class_of' do
      subject(:klass) do
        Support.class_of(object)
      end

      context 'with a String instance' do
        let(:object) do
          'foo'
        end

        it { is_expected.to equal(String) }
      end

      context 'with a BasicObject instance' do
        let(:object) do
          basic_object_class.new
        end

        let(:basic_object_class) do
          defined?(BasicObject) ? BasicObject : fake_basic_object_class
        end

        let(:fake_basic_object_class) do
          Class.new do
            def self.to_s
              'BasicObject'
            end

            undef class, inspect, respond_to?
          end
        end

        it { is_expected.to equal(basic_object_class) }
      end

      context 'with nil' do
        let(:object) do
          nil
        end

        it { is_expected.to equal(NilClass) }
      end

      context 'with an object having a singleton class' do
        let(:object) do
          object = 'foo'

          def object.some_method
          end

          object
        end

        it 'returns its non-singleton ancestor class' do
          expect(klass).to equal(String)
        end
      end

      context 'with a Class instance' do
        let(:object) do
          String
        end

        it { is_expected.to equal(Class) }
      end
    end

    describe "failure notification" do
      before { @failure_notifier = RSpec::Support.failure_notifier }
      after  { RSpec::Support.failure_notifier = @failure_notifier }
      let(:error) { NotImplementedError.new("some message") }
      let(:failures) { [] }
      let(:append_to_failures_array_notifier) { lambda { |failure, _opts| failures << failure } }

      def notify(failure)
        RSpec::Support.notify_failure(failure)
      end

      def append_to_failures_array_instead_of_raising
        avoid_raising_errors.and change { failures }.from([]).to([error])
      end

      def raise_instead_of_appending_to_failures_array
        raise_error(error).and avoid_changing { failures }
      end

      it "defaults to raising the provided exception" do
        expect { notify(error) }.to raise_error(error)
      end

      it "can be set to another callable" do
        RSpec::Support.failure_notifier = append_to_failures_array_notifier

        expect {
          notify(error)
        }.to append_to_failures_array_instead_of_raising
      end

      it "isolates notifier changes to the current thread" do
        RSpec::Support.failure_notifier = append_to_failures_array_notifier

        Thread.new do
          expect { notify(error) }.to raise_instead_of_appending_to_failures_array
        end.join
      end

      it "can be changed for the duration of a block" do
        yielded = false

        RSpec::Support.with_failure_notifier(append_to_failures_array_notifier) do
          yielded = true
          expect {
            notify(error)
          }.to append_to_failures_array_instead_of_raising
        end

        expect(yielded).to be true
      end

      it "resets the notifier back to what it originally was when the block completes, even if an error was raised" do
        expect {
          RSpec::Support.with_failure_notifier(append_to_failures_array_notifier) do
            raise "boom"
          end
        }.to raise_error("boom")

        expect { notify(error) }.to raise_instead_of_appending_to_failures_array
      end
    end

    describe "warning notification" do
      include RSpec::Support::Warnings

      before { @warning_notifier = RSpec::Support.warning_notifier }
      after  { RSpec::Support.warning_notifier = @warning_notifier }
      let(:warnings) { [] }
      let(:append_to_warnings_array_notifier) { lambda { |warning| warnings << warning } }

      def append_to_array_instead_of_warning
        change { warnings }.from([]).to([a_string_including('some warning')])
      end

      it "defaults to warning with the provided text" do
        expect {
          warning('some warning')
        }.to output(a_string_including 'some warning').to_stderr
      end

      it "can be set to another callable" do
        RSpec::Support.warning_notifier = append_to_warnings_array_notifier

        expect {
          warning('some warning')
        }.to append_to_array_instead_of_warning
      end
    end

    describe Support::AllExceptionsExceptOnesWeMustNotRescue do
      it "rescues a StandardError" do
        expect {
          begin
            raise StandardError
          rescue subject
          end
        }.not_to raise_error
      end

      it 'rescues an Exception' do
        expect {
          begin
            raise Exception
          rescue subject
          end
        }.not_to raise_error
      end

      Support::AllExceptionsExceptOnesWeMustNotRescue::AVOID_RESCUING.each do |klass|
        exception = if klass == SignalException
                      SignalException.new("INT")
                    else
                      klass
                    end

        it "does not rescue a #{klass}" do
          expect {
            begin
              raise exception
            rescue subject
            end
          }.to raise_error(klass)
        end
      end
    end
  end
end
