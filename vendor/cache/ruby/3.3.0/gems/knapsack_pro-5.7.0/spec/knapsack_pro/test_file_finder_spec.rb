describe KnapsackPro::TestFileFinder do
  describe '.call' do
    let(:test_file_pattern) { double }
    let(:test_files) { double }

    subject { described_class.call(test_file_pattern) }

    before do
      test_file_finder = instance_double(described_class, call: test_files)
      expect(described_class).to receive(:new).with(test_file_pattern, true).and_return(test_file_finder)
    end

    it { should eq test_files }
  end

  describe '.slow_test_files_by_pattern' do
    let(:adapter_class) { double }

    subject { described_class.slow_test_files_by_pattern(adapter_class) }

    before do
      expect(KnapsackPro::Config::Env).to receive(:slow_test_file_pattern).at_least(1).and_return(slow_test_file_pattern)
    end

    context 'when slow_test_file_pattern is present' do
      let(:slow_test_file_pattern) { double }
      let(:test_file_entities) do
        [
          { 'path' => 'a_spec.rb' },
          { 'path' => 'b_spec.rb' },
          { 'path' => 'c_spec.rb' },
        ]
      end
      let(:slow_test_file_entities) do
        [
          { 'path' => 'b_spec.rb' },
          { 'path' => 'c_spec.rb' },
          { 'path' => 'd_spec.rb' },
        ]
      end

      it do
        test_file_pattern = double
        expect(KnapsackPro::TestFilePattern).to receive(:call).with(adapter_class).and_return(test_file_pattern)
        expect(described_class).to receive(:call).with(test_file_pattern).and_return(test_file_entities)

        expect(described_class).to receive(:call).with(slow_test_file_pattern, test_file_list_enabled: false).and_return(slow_test_file_entities)

        expect(subject).to eq([
          { 'path' => 'b_spec.rb' },
          { 'path' => 'c_spec.rb' },
        ])
      end
    end

    context 'when slow_test_file_pattern is not present' do
      let(:slow_test_file_pattern) { nil }

      it do
        expect { subject }.to raise_error RuntimeError, 'KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN is not defined'
      end
    end
  end

  describe '.select_test_files_that_can_be_run' do
    let(:adapter_class) { double }
    let(:test_file_entities_to_run) do
      [
        { 'path' => 'a_spec.rb' },
        { 'path' => 'b_spec.rb' },
        { 'path' => 'not_existing_on_disk_spec.rb' },
      ]
    end
    # test files existing on disk
    let(:test_file_entities) do
      [
        { 'path' => 'a_spec.rb' },
        { 'path' => 'b_spec.rb' },
        { 'path' => 'c_spec.rb' },
      ]
    end

    subject { described_class.select_test_files_that_can_be_run(adapter_class, test_file_entities_to_run) }

    it do
      test_file_pattern = double
      expect(KnapsackPro::TestFilePattern).to receive(:call).with(adapter_class).and_return(test_file_pattern)
      expect(described_class).to receive(:call).with(test_file_pattern).and_return(test_file_entities)

      expect(subject).to eq([
        { 'path' => 'a_spec.rb' },
        { 'path' => 'b_spec.rb' },
      ])
    end
  end

  describe '#call' do
    let(:test_file_list_enabled) { true }
    let(:test_file_pattern) { 'spec_fake/**{,/*/**}/*_spec.rb' }

    subject { described_class.new(test_file_pattern, test_file_list_enabled).call }

    context 'when KNAPSACK_PRO_TEST_FILE_EXCLUDE_PATTERN is not defined' do
      it do
        should eq([
          { 'path' => 'spec_fake/controllers/users_controller_spec.rb' },
          { 'path' => 'spec_fake/models/admin_spec.rb' },
          { 'path' => 'spec_fake/models/user_spec.rb' },
        ])
      end
    end

    context 'when KNAPSACK_PRO_TEST_FILE_EXCLUDE_PATTERN is defined' do
      let(:test_file_exclude_pattern) { 'spec_fake/controllers/*_spec.rb' }

      before do
        stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_EXCLUDE_PATTERN' => test_file_exclude_pattern })
      end

      it do
        should eq([
          { 'path' => 'spec_fake/models/admin_spec.rb' },
          { 'path' => 'spec_fake/models/user_spec.rb' },
        ])
      end
    end

    context 'when KNAPSACK_PRO_TEST_FILE_LIST is defined' do
      # added spaces next to comma to check space is removed later
      let(:test_file_list) { 'spec/bar_spec.rb,spec/foo_spec.rb, spec/time_helpers_spec.rb:10 , spec/time_helpers_spec.rb:38' }

      before do
        stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_LIST' => test_file_list })
      end

      it do
        expect(subject).to eq([
          { 'path' => 'spec/bar_spec.rb' },
          { 'path' => 'spec/foo_spec.rb' },
          { 'path' => 'spec/time_helpers_spec.rb:10' },
          { 'path' => 'spec/time_helpers_spec.rb:38' },
        ])
      end

      context 'when test_file_list_enabled=false' do
        let(:test_file_list_enabled) { false }

        it do
          should eq([
            { 'path' => 'spec_fake/controllers/users_controller_spec.rb' },
            { 'path' => 'spec_fake/models/admin_spec.rb' },
            { 'path' => 'spec_fake/models/user_spec.rb' },
          ])
        end
      end
    end

    context 'when KNAPSACK_PRO_TEST_FILE_LIST_SOURCE_FILE is defined' do
      let(:test_file_list_source_file) { 'spec/fixtures/test_file_list_source_file.txt' }

      before do
        stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_LIST_SOURCE_FILE' => test_file_list_source_file })
      end

      it do
        expect(subject).to eq([
          { 'path' => 'spec/test1_spec.rb' },
          { 'path' => 'spec/test2_spec.rb[1]' },
          { 'path' => 'spec/test3_spec.rb[1:2:3:4]' },
          { 'path' => 'spec/test4_spec.rb:4' },
          { 'path' => 'spec/test4_spec.rb:5' },
        ])
      end
    end
  end
end
