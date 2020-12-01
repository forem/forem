require "support/runner_support"

module RSpec::Core
  RSpec.describe "Configuration :suite hooks" do
    [:before, :after, :prepend_before, :append_before, :prepend_after, :append_after].each do |registration_method|
      type = registration_method.to_s.split('_').last

      describe "a `:suite` hook registered with `#{registration_method}`" do
        it 'is skipped when in dry run mode' do
          RSpec.configuration.dry_run = true

          expect { |b|
            RSpec.configuration.__send__(registration_method, :suite, &b)
            RSpec.configuration.with_suite_hooks { }
          }.not_to yield_control
        end

        it 'notifies about errors in the hook' do
          RSpec.configuration.__send__(registration_method, :suite) { 1 / 0 }

          expect(RSpec.configuration.reporter).to receive(:notify_non_example_exception).with(
            ZeroDivisionError, /suite\)` hook/
          )

          RSpec.configuration.with_suite_hooks { }
        end

        it 'sets `wants_to_quit` when an error occurs so that the suite does not get run' do
          RSpec.configuration.__send__(registration_method, :suite) { 1 / 0 }
          allow(RSpec.configuration.reporter).to receive(:notify_non_example_exception)

          expect {
            RSpec.configuration.with_suite_hooks { }
          }.to change(RSpec.world, :wants_to_quit).from(a_falsey_value).to(true)
        end

        it 'runs in the context of an example group' do
          run_context = nil
          RSpec.configuration.__send__(registration_method, :suite) { run_context = self }
          RSpec.configuration.with_suite_hooks { }
          expect(run_context).to be_a ExampleGroup
        end

        it 'allows access to rspec-mocks methods within the hook' do
          run = false
          RSpec.configuration.__send__(registration_method, :suite) do
            RSpec::Mocks.with_temporary_scope { double('something') }
            run = true
          end
          RSpec.configuration.with_suite_hooks { }
          expect(run).to be true
        end

        it 'allows access to rspec-expectation methods within the hook' do
          notified_failure = nil

          RSpec::Support.with_failure_notifier(lambda { |e, _opts| notified_failure = e }) do
            RSpec.configuration.__send__(registration_method, :suite) do
              expect(true).to be false
            end

            RSpec.configuration.with_suite_hooks { }
          end

          expect(notified_failure).to be_a(RSpec::Expectations::ExpectationNotMetError)
        end

        context "registered on an example group" do
          it "is ignored with a clear warning" do
            sequence = []

            expect {
              RSpec.describe "Group" do
                __send__(registration_method, :suite) { sequence << :suite_hook }
                example { sequence << :example }
              end.run
            }.to change { sequence }.to([:example]).
              and output(a_string_including("#{type}(:suite)")).to_stderr
          end
        end

        context "registered with metadata" do
          it "explicitly warns that the metadata is ignored" do
            expect {
              RSpec.configure do |c|
                c.__send__(registration_method, :suite, :some => :metadata)
              end
            }.to output(a_string_including(":suite", "metadata")).to_stderr
          end
        end
      end
    end

    it 'always runs `after(:suite)` hooks even in the face of errors' do
      expect { |b|
        RSpec.configuration.after(:suite, &b)
        RSpec.configuration.with_suite_hooks { raise "boom" }
      }.to raise_error("boom").and yield_control
    end

    describe "the runner" do
      include_context "Runner support"

      def define_and_run_example_group(&block)
        example_group = class_double(ExampleGroup, :descendants => [])

        allow(example_group).to receive(:run, &block)
        allow(world).to receive_messages(:ordered_example_groups => [example_group])
        allow(config).to receive :load_spec_files

        runner = build_runner
        runner.run err, out
      end

      it "still runs :suite hooks with metadata even though the metadata is ignored" do
        sequence = []
        allow(RSpec).to receive(:warn_with)

        config.before(:suite, :foo)  { sequence << :before_suite   }
        config.after(:suite, :foo)   { sequence << :after_suite    }
        define_and_run_example_group { sequence << :example_groups }

        expect(sequence).to eq([ :before_suite, :example_groups, :after_suite ])
      end

      it "runs :suite hooks before and after example groups in the correct order" do
        sequence = []

        config.before(:suite)         { sequence << :before_suite_2 }
        config.before(:suite)         { sequence << :before_suite_3 }
        config.append_before(:suite)  { sequence << :before_suite_4 }
        config.prepend_before(:suite) { sequence << :before_suite_1 }
        config.after(:suite)          { sequence << :after_suite_3  }
        config.after(:suite)          { sequence << :after_suite_2  }
        config.prepend_after(:suite)  { sequence << :after_suite_1  }
        config.append_after(:suite)   { sequence << :after_suite_4  }

        define_and_run_example_group { sequence << :example_groups }

        expect(sequence).to eq([
          :before_suite_1,
          :before_suite_2,
          :before_suite_3,
          :before_suite_4,
          :example_groups,
          :after_suite_1,
          :after_suite_2,
          :after_suite_3,
          :after_suite_4
        ])
      end
    end
  end
end
