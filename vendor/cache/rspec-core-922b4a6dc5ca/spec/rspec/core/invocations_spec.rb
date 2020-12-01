require 'rspec/core/drb'
require 'rspec/core/bisect/coordinator'
require 'rspec/core/project_initializer'

module RSpec::Core
  RSpec.describe Invocations do
    let(:configuration_options) { instance_double(ConfigurationOptions) }
    let(:err) { StringIO.new }
    let(:out) { StringIO.new }

    def run_invocation
      subject.call(configuration_options, err, out)
    end

    describe Invocations::InitializeProject do
      it "initializes a project and returns a 0 exit code" do
        project_init = instance_double(ProjectInitializer, :run => nil)
        allow(ProjectInitializer).to receive_messages(:new => project_init)

        exit_code = run_invocation

        expect(project_init).to have_received(:run)
        expect(exit_code).to eq(0)
      end
    end

    describe Invocations::DRbWithFallback do
      context 'when a DRb server is running' do
        it "builds a DRbRunner and runs the specs" do
          drb_proxy = instance_double(RSpec::Core::DRbRunner, :run => 0)
          allow(RSpec::Core::DRbRunner).to receive(:new).and_return(drb_proxy)

          exit_code = run_invocation

          expect(drb_proxy).to have_received(:run).with(err, out)
          expect(exit_code).to eq(0)
        end
      end

      context 'when a DRb server is not running' do
        let(:runner) { instance_double(RSpec::Core::Runner, :run => 0) }

        before(:each) do
          allow(RSpec::Core::Runner).to receive(:new).and_return(runner)
          allow(RSpec::Core::DRbRunner).to receive(:new).and_raise(DRb::DRbConnError)
        end

        it "outputs a message" do
          run_invocation

          expect(err.string).to include(
            "No DRb server is running. Running in local process instead ..."
          )
        end

        it "builds a runner instance and runs the specs" do
          run_invocation

          expect(RSpec::Core::Runner).to have_received(:new).with(configuration_options)
          expect(runner).to have_received(:run).with(err, out)
        end

        if RSpec::Support::RubyFeatures.supports_exception_cause?
          it "prevents the DRb error from being listed as the cause of expectation failures" do
            allow(RSpec::Core::Runner).to receive(:new) do |configuration_options|
              raise RSpec::Expectations::ExpectationNotMetError
            end

            expect {
              run_invocation
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
              expect(e.cause).to be_nil
            end
          end
        end
      end
    end

    describe Invocations::Bisect do
      let(:original_cli_args) { %w[--bisect --seed 1234] }
      let(:configuration_options) { ConfigurationOptions.new(original_cli_args) }
      let(:success) { true }

      before do
        allow(RSpec::Core::Bisect::Coordinator).to receive(:bisect_with).and_return(success)
      end

      it "starts the bisection coordinator" do
        run_invocation

        expect(RSpec::Core::Bisect::Coordinator).to have_received(:bisect_with).with(
          an_instance_of(Runner),
          configuration_options.args,
          an_instance_of(Formatters::BisectProgressFormatter)
        )
      end

      context "when the bisection is successful" do
        it "returns 0" do
          exit_code = run_invocation

          expect(exit_code).to eq(0)
        end
      end

      context "when the bisection is unsuccessful" do
        let(:success) { false }

        it "returns 1" do
          exit_code = run_invocation

          expect(exit_code).to eq(1)
        end

        context "with a custom failure code set" do
          it "returns the custom failure code" do
            in_sub_process do
              RSpec.configuration.failure_exit_code = 42
              exit_code = run_invocation
              expect(exit_code).to eq(42)
            end
          end
        end
      end

      context "and the verbose option is specified" do
        let(:original_cli_args) { %w[--bisect=verbose --seed 1234] }

        it "starts the bisection coordinator with the debug formatter" do
          run_invocation

          expect(RSpec::Core::Bisect::Coordinator).to have_received(:bisect_with).with(
            an_instance_of(Runner),
            configuration_options.args,
            an_instance_of(Formatters::BisectDebugFormatter)
          )
        end
      end
    end

    describe Invocations::PrintVersion do
      before do
        allow(subject).to receive(:require).and_call_original
        allow(subject).to receive(:require).with("rspec/rails/version").and_raise(LoadError)
      end

      it "prints the major.minor version of RSpec as a whole" do
        stub_const("RSpec::Core::Version::STRING", "9.18.23")
        run_invocation
        expect(out.string).to include("RSpec 9.18\n")
      end

      it "prints off the whole version if it's a pre-release" do
        stub_const("RSpec::Core::Version::STRING", "9.18.0-beta1")
        run_invocation
        expect(out.string).to include("RSpec 9.18.0-beta1\n")
      end

      it "prints off the version of each part of RSpec" do
        [:Core, :Expectations, :Mocks, :Support].each_with_index do |const_name, index|
          # validate that this is an existing const
          expect(RSpec.const_get(const_name)::Version::STRING).to be_a String

          stub_const("RSpec::#{const_name}::Version::STRING", "9.2.#{index}")
        end

        run_invocation

        expect(out.string).to include(
          "- rspec-core 9.2.0",
          "- rspec-expectations 9.2.1",
          "- rspec-mocks 9.2.2",
          "- rspec-support 9.2.3"
        )
      end

      it "indicates a part is not installed if it cannot be loaded" do
        run_invocation

        expect(out.string).not_to include("rspec-rails")
      end

      it "returns a zero exit code" do
        expect(run_invocation).to eq 0
      end
    end

    describe Invocations::PrintHelp do
      let(:parser) { instance_double(OptionParser) }
      let(:invalid_options) { %w[ -d ] }

      subject { described_class.new(parser, invalid_options) }

      before do
        allow(parser).to receive(:to_s).and_return(<<-EOS)
        -d
        --bisect[=verbose]           Repeatedly runs the suite in order...
        EOS
      end

      it "prints the CLI options and returns a zero exit code" do
        exit_code = run_invocation

        expect(exit_code).to eq(0)
        expect(out.string).to include("--bisect")
      end

      it "won't display invalid options in the help output" do
        useless_lines = /^\s*-d\s*$\n/

        run_invocation

        expect(out.string).to_not match(useless_lines)
      end
    end
  end
end
