require 'pathname'
require 'tempfile'

require 'gem_isolator'

RSpec.describe "Formatter test", type: :acceptance do
  context "when isolated" do
    before { allow(Kernel).to receive(:system).and_call_original }

    let!(:formatter) { File.expand_path('lib/guard/rspec_formatter.rb') }

    context "when a valid results file path is given" do
      around do |example|
        Tempfile.open('results') do |tempfile|
          @results_file = tempfile.path
          example.run
        end
      end

      context "when a succeeding command is given" do
        let!(:spec) do
          File.expand_path('spec/acceptance/fixtures/succeeding_spec.rb')
        end

        let(:rspec_args) do
          ['-r', formatter, '-f', 'Guard::RSpecFormatter', spec]
        end

        context "when guard is not in Gemfile" do
          let(:gems) { [%w(rspec ~>3.4)] }

          it "works" do
            GemIsolator.isolate(gems: gems) do |env, isolation|
              env = env.merge('GUARD_RSPEC_RESULTS_FILE' => @results_file)

              # TODO: I don't know why Travis needs a full path for binaries
              # for system() to work.
              rspec = env['PATH'].sub(/:.*/, '/rspec')
              expect(isolation.system(env, rspec, *rspec_args)).to eq(true)
            end
          end
        end
      end
    end
  end
end
