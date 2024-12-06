describe KnapsackPro::Adapters::RSpecAdapter do
  it 'backwards compatibility with knapsack gem old rspec adapter name' do
    expect(KnapsackPro::Adapters::RspecAdapter.new).to be_kind_of(described_class)
  end

  it do
    expect(described_class::TEST_DIR_PATTERN).to eq 'spec/**{,/*/**}/*_spec.rb'
  end

  context do
    before { expect(::RSpec).to receive(:configure) }
    it_behaves_like 'adapter'
  end

  describe '.split_by_test_cases_enabled?' do
    subject { described_class.split_by_test_cases_enabled? }

    before do
      expect(KnapsackPro::Config::Env).to receive(:rspec_split_by_test_examples?).and_return(rspec_split_by_test_examples_enabled)
    end

    context 'when the RSpec split by test examples is enabled' do
      let(:rspec_split_by_test_examples_enabled) { true }

      it { expect(subject).to be true }

      context 'when the RSpec version is < 3.3.0' do
        before do
          stub_const('RSpec::Core::Version::STRING', '3.2.0')
        end

        it do
          expect { subject }.to raise_error RuntimeError, 'RSpec >= 3.3.0 is required to split test files by test examples. Learn more: https://knapsackpro.com/perma/ruby/split-by-test-examples'
        end
      end
    end

    context 'when the RSpec split by test examples is disabled' do
      let(:rspec_split_by_test_examples_enabled) { false }

      it { expect(subject).to be false }
    end
  end

  describe '.test_file_cases_for' do
    let(:slow_test_files) do
      [
        '1_spec.rb',
        '2_spec.rb',
        '3_spec.rb',
        '4_spec.rb',
        '5_spec.rb',
      ]
    end

    subject { described_class.test_file_cases_for(slow_test_files) }

    before do
      logger = instance_double(Logger)
      expect(KnapsackPro).to receive(:logger).and_return(logger)
      expect(logger).to receive(:info).with("Generating RSpec test examples JSON report for slow test files to prepare it to be split by test examples (by individual test cases). Thanks to that, a single slow test file can be split across parallel CI nodes. Analyzing 5 slow test files.")

      cmd = 'RACK_ENV=test RAILS_ENV=test bundle exec rake knapsack_pro:rspec_test_example_detector'
      expect(Kernel).to receive(:system).with(cmd).and_return(cmd_result)
    end

    context 'when the rake task to detect RSpec test examples succeeded' do
      let(:cmd_result) { true }

      it 'returns test example paths for slow test files' do
        rspec_test_example_detector = instance_double(KnapsackPro::TestCaseDetectors::RSpecTestExampleDetector)
        expect(KnapsackPro::TestCaseDetectors::RSpecTestExampleDetector).to receive(:new).and_return(rspec_test_example_detector)

        test_file_example_paths = double
        expect(rspec_test_example_detector).to receive(:test_file_example_paths).and_return(test_file_example_paths)

        expect(subject).to eq test_file_example_paths
      end
    end

    context 'when the rake task to detect RSpec test examples failed' do
      let(:cmd_result) { false }

      it do
        expect { subject }.to raise_error(RuntimeError, 'Could not generate JSON report for RSpec. Rake task failed when running RACK_ENV=test RAILS_ENV=test bundle exec rake knapsack_pro:rspec_test_example_detector')
      end
    end
  end

  describe '.ensure_no_tag_option_when_rspec_split_by_test_examples_enabled!' do
    let(:cli_args) { double }

    subject { described_class.ensure_no_tag_option_when_rspec_split_by_test_examples_enabled!(cli_args) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:rspec_split_by_test_examples?).and_return(rspec_split_by_test_examples_enabled)
    end

    context 'when RSpec split by test examples enabled' do
      let(:rspec_split_by_test_examples_enabled) { true }

      before do
        expect(described_class).to receive(:has_tag_option?).with(cli_args).and_return(has_tag_option)
      end

      context 'when RSpec tag option is provided' do
        let(:has_tag_option) { true }

        it do
          expect { subject }.to raise_error(/It is not allowed to use the RSpec tag option together with the RSpec split by test examples feature/)
        end
      end

      context 'when RSpec tag option is not provided' do
        let(:has_tag_option) { false }

        it 'does nothing' do
          expect(subject).to be_nil
        end
      end
    end

    context 'when RSpec split by test examples disabled' do
      let(:rspec_split_by_test_examples_enabled) { false }

      it 'does nothing' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.has_tag_option?' do
    subject { described_class.has_tag_option?(cli_args) }

    context 'when tag option is provided as -t' do
      let(:cli_args) { ['-t', 'mytag'] }

      it { expect(subject).to be true }
    end

    context 'when tag option is provided as --tag' do
      let(:cli_args) { ['--tag', 'mytag'] }

      it { expect(subject).to be true }
    end

    context 'when tag option is provided without delimiter' do
      let(:cli_args) { ['-tmytag'] }

      it { expect(subject).to be true }
    end

    context 'when tag option is not provided' do
      let(:cli_args) { ['--fake', 'value'] }

      it { expect(subject).to be false }
    end
  end

  describe '.has_format_option?' do
    subject { described_class.has_format_option?(cli_args) }

    context 'when format option is provided as -f' do
      let(:cli_args) { ['-f', 'documentation'] }

      it { expect(subject).to be true }
    end

    context 'when format option is provided as --format' do
      let(:cli_args) { ['--format', 'documentation'] }

      it { expect(subject).to be true }
    end

    context 'when format option is provided without delimiter' do
      let(:cli_args) { ['-fd'] }

      it { expect(subject).to be true }
    end

    context 'when format option is not provided' do
      let(:cli_args) { ['--fake', 'value'] }

      it { expect(subject).to be false }
    end
  end

  describe '.order_option' do
    subject { described_class.order_option(cli_args) }

    context "when order is 'defined'" do
      let(:cli_args) { ['--order', 'defined'] }

      it { expect(subject).to eq 'defined' }
    end

    context "when order is 'recently-modified'" do
      let(:cli_args) { ['--order', 'recently-modified'] }

      it { expect(subject).to eq 'recently-modified' }
    end

    context "when order is 'rand'" do
      let(:cli_args) { ['--order', 'rand'] }

      it { expect(subject).to eq 'rand' }

      context 'with the seed' do
        let(:cli_args) { ['--order', 'rand:123456'] }

        it { expect(subject).to eq 'rand:123456' }
      end
    end

    context "when order is 'random'" do
      let(:cli_args) { ['--order', 'random'] }

      it { expect(subject).to eq 'random' }

      context 'with the seed' do
        let(:cli_args) { ['--order', 'random:123456'] }

        it { expect(subject).to eq 'random:123456' }
      end
    end

    context 'when some custom order is specified' do
      let(:cli_args) { ['--order', 'some-custom-order'] }

      it { expect(subject).to eq 'some-custom-order' }
    end

    context "when the seed is given with the --seed command" do
      let(:cli_args) { ['--seed', '123456'] }

      it { expect(subject).to eq 'rand:123456' }
    end
  end

  describe '.test_path' do
    let(:example_group) do
      {
        file_path: '1_shared_example.rb',
        parent_example_group: {
          file_path: '2_shared_example.rb',
          parent_example_group: {
            file_path: 'a_spec.rb'
          }
        }
      }
    end
    let(:current_example) do
      OpenStruct.new(metadata: {
        example_group: example_group
      })
    end

    subject { described_class.test_path(current_example) }

    it { should eql 'a_spec.rb' }

    context 'with turnip features' do
      describe 'when the turnip version is less than 2' do
        let(:example_group) do
          {
            file_path: "./spec/features/logging_in.feature",
            turnip: true,
            parent_example_group: {
              file_path: "gems/turnip-1.2.4/lib/turnip/rspec.rb"
            }
          }
        end

        before { stub_const("Turnip::VERSION", '1.2.4') }

        it { should eql './spec/features/logging_in.feature' }
      end

      describe 'when turnip is version 2 or greater' do
        let(:example_group) do
          {
            file_path: "gems/turnip-2.0.0/lib/turnip/rspec.rb",
            turnip: true,
            parent_example_group: {
              file_path: "./spec/features/logging_in.feature",
            }
          }
        end

        before { stub_const("Turnip::VERSION",  '2.0.0') }

        it { should eql './spec/features/logging_in.feature' }
      end
    end
  end

  describe 'bind methods' do
    let(:config) { double }

    describe '#bind_time_tracker' do
      let(:tracker) { instance_double(KnapsackPro::Tracker) }
      let(:logger) { instance_double(Logger) }
      let(:global_time) { 'Global time: 01m 05s' }
      let(:test_path) { 'spec/a_spec.rb' }
      let(:current_example) { double(metadata: {}) }

      context "when the example's metadata has :focus tag AND RSpec inclusion rule includes :focus" do
        let(:current_example) { double(metadata: { focus: true }) }

        it do
          expect(KnapsackPro::Config::Env).to receive(:rspec_split_by_test_examples?).and_return(false)

          expect(config).to receive(:prepend_before).with(:context).and_yield

          allow(KnapsackPro).to receive(:tracker).and_return(tracker)
          expect(tracker).to receive(:start_timer).ordered

          expect(config).to receive(:around).with(:each).and_yield(current_example)
          expect(::RSpec).to receive(:configure).and_yield(config)

          expect(tracker).to receive(:current_test_path).ordered.and_return(test_path)
          expect(tracker).to receive(:stop_timer).ordered

          expect(described_class).to receive(:test_path).with(current_example).and_return(test_path)

          expect(tracker).to receive(:current_test_path=).with(test_path).ordered

          expect(described_class).to receive_message_chain(:rspec_configuration, :filter, :rules, :[]).with(:focus).and_return(true)

          expect {
            subject.bind_time_tracker
          }.to raise_error /We detected a test file path spec\/a_spec\.rb with a test using the metadata `:focus` tag/
        end
      end

      context 'when rspec split by test examples is disabled' do
        before do
          expect(KnapsackPro::Config::Env).to receive(:rspec_split_by_test_examples?).and_return(false)
        end

        it 'records time for current test path' do
          expect(config).to receive(:prepend_before).with(:context).and_yield

          allow(KnapsackPro).to receive(:tracker).and_return(tracker)
          expect(tracker).to receive(:start_timer).ordered

          expect(config).to receive(:around).with(:each).and_yield(current_example)
          expect(config).to receive(:append_after).with(:context).and_yield
          expect(config).to receive(:after).with(:suite).and_yield
          expect(::RSpec).to receive(:configure).and_yield(config)

          expect(tracker).to receive(:current_test_path).ordered.and_return(test_path)
          expect(tracker).to receive(:stop_timer).ordered

          expect(described_class).to receive(:test_path).with(current_example).and_return(test_path)

          expect(tracker).to receive(:current_test_path=).with(test_path).ordered

          expect(current_example).to receive(:run)

          expect(tracker).to receive(:stop_timer).ordered

          expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
          expect(KnapsackPro).to receive(:logger).and_return(logger)
          expect(logger).to receive(:debug).with(global_time)

          subject.bind_time_tracker
        end
      end

      context 'when rspec split by test examples is enabled' do
        let(:test_example_path) { 'spec/a_spec.rb[1:1]' }

        before do
          expect(KnapsackPro::Config::Env).to receive(:rspec_split_by_test_examples?).and_return(true)
        end

        context 'when current test_path is a slow test file' do
          before do
            expect(described_class).to receive(:slow_test_file?).with(described_class, test_path).and_return(true)
          end

          it 'records time for example.id' do
            expect(current_example).to receive(:id).and_return(test_example_path)

            expect(config).to receive(:prepend_before).with(:context).and_yield

            allow(KnapsackPro).to receive(:tracker).and_return(tracker)
            expect(tracker).to receive(:start_timer).ordered

            expect(config).to receive(:around).with(:each).and_yield(current_example)
            expect(config).to receive(:append_after).with(:context).and_yield
            expect(config).to receive(:after).with(:suite).and_yield
            expect(::RSpec).to receive(:configure).and_yield(config)

            expect(tracker).to receive(:current_test_path).ordered.and_return(test_path)
            expect(tracker).to receive(:stop_timer).ordered

            expect(described_class).to receive(:test_path).with(current_example).and_return(test_path)

            expect(tracker).to receive(:current_test_path=).with(test_example_path).ordered

            expect(current_example).to receive(:run)

            expect(tracker).to receive(:stop_timer).ordered

            expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
            expect(KnapsackPro).to receive(:logger).and_return(logger)
            expect(logger).to receive(:debug).with(global_time)

            subject.bind_time_tracker
          end
        end

        context 'when current test_path is not a slow test file' do
          before do
            expect(described_class).to receive(:slow_test_file?).with(described_class, test_path).and_return(false)
          end

          it 'records time for current test path' do
            expect(config).to receive(:prepend_before).with(:context).and_yield

            allow(KnapsackPro).to receive(:tracker).and_return(tracker)
            expect(tracker).to receive(:start_timer).ordered

            expect(config).to receive(:around).with(:each).and_yield(current_example)
            expect(config).to receive(:append_after).with(:context).and_yield
            expect(config).to receive(:after).with(:suite).and_yield
            expect(::RSpec).to receive(:configure).and_yield(config)

            expect(described_class).to receive(:test_path).with(current_example).and_return(test_path)

            expect(tracker).to receive(:current_test_path).ordered.and_return(test_path)
            expect(tracker).to receive(:stop_timer).ordered

            expect(tracker).to receive(:current_test_path=).with(test_path).ordered

            expect(current_example).to receive(:run)

            expect(tracker).to receive(:stop_timer).ordered

            expect(KnapsackPro::Presenter).to receive(:global_time).and_return(global_time)
            expect(KnapsackPro).to receive(:logger).and_return(logger)
            expect(logger).to receive(:debug).with(global_time)

            subject.bind_time_tracker
          end
        end
      end
    end

    describe '#bind_save_report' do
      it do
        expect(config).to receive(:after).with(:suite).and_yield
        expect(::RSpec).to receive(:configure).and_yield(config)

        expect(KnapsackPro::Report).to receive(:save)

        subject.bind_save_report
      end
    end

    describe '#bind_before_queue_hook' do
      it do
        expect(config).to receive(:before).with(:suite).and_yield
        expect(::RSpec).to receive(:configure).and_yield(config)

        expect(KnapsackPro::Hooks::Queue).to receive(:call_before_queue)

        subject.bind_before_queue_hook
      end
    end
  end
end
