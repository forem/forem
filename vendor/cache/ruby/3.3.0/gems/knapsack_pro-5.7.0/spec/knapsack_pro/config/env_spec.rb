describe KnapsackPro::Config::Env do
  before { stub_const("ENV", {}) }

  describe '.ci_node_total' do
    subject { described_class.ci_node_total }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_CI_NODE_TOTAL has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_CI_NODE_TOTAL' => '5' }) }
        it { should eq 5 }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:node_total).and_return(4)
        end

        it { should eq 4 }
      end
    end

    context "when ENV doesn't exist" do
      it { should eq 1 }
    end
  end

  describe '.ci_node_index' do
    subject { described_class.ci_node_index }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_CI_NODE_INDEX has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_CI_NODE_INDEX' => '3' }) }
        it { should eq 3 }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:node_index).and_return(2)
        end

        it { should eq 2 }
      end

      context 'when order of loading envs does matter' do
        context 'when GitLab CI' do
          before { stub_const("ENV", { 'CI_NODE_INDEX' => '2', 'GITLAB_CI' => 'true' }) }
          it { should eq 1 }
        end
      end
    end

    context "when ENV doesn't exist" do
      it { should eq 0 }
    end
  end

  describe '.ci_node_build_id' do
    subject { described_class.ci_node_build_id }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_CI_NODE_BUILD_ID has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_CI_NODE_BUILD_ID' => '7' }) }
        it { should eq '7' }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:node_build_id).and_return('8')
        end

        it { should eq '8' }
      end
    end

    context "when ENV does not exist" do
      it 'raises' do
        expect { subject }.to raise_error(/Missing environment variable KNAPSACK_PRO_CI_NODE_BUILD_ID/)
      end
    end
  end

  describe '.ci_node_retry_count' do
    subject { described_class.ci_node_retry_count }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_CI_NODE_RETRY_COUNT has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_CI_NODE_RETRY_COUNT' => '1' }) }
        it { should eq 1 }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:node_retry_count).and_return('2')
        end

        it { should eq 2 }
      end
    end

    context "when ENV doesn't exist" do
      it { should eq 0 }
    end
  end

  describe '.max_request_retries' do
    subject { described_class.max_request_retries }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_MAX_REQUEST_RETRIES' => '2' }) }
      it { should eq 2 }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.commit_hash' do
    subject { described_class.commit_hash }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_COMMIT_HASH has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_COMMIT_HASH' => '3fa64859337f6e56409d49f865d13fd7' }) }
        it { should eq '3fa64859337f6e56409d49f865d13fd7' }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:commit_hash).and_return('fe61a08118d0d52e97c38666eba1eaf3')
        end

        it { should eq 'fe61a08118d0d52e97c38666eba1eaf3' }
      end
    end

    context "when ENV doesn't exist" do
      it { should be nil }
    end
  end

  describe '.branch' do
    subject { described_class.branch }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_BRANCH has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_BRANCH' => 'master' }) }
        it { should eq 'master' }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:branch).and_return('feature-branch')
        end

        it { should eq 'feature-branch' }
      end
    end

    context "when ENV doesn't exist" do
      it { should be nil }
    end
  end

  describe '.project_dir' do
    subject { described_class.project_dir }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_PROJECT_DIR has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_PROJECT_DIR' => '/home/user/myapp' }) }
        it { should eq '/home/user/myapp' }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:project_dir).and_return('/home/runner/myapp')
        end

        it { should eq '/home/runner/myapp' }
      end
    end

    context "when ENV doesn't exist" do
      it { should be nil }
    end
  end

  describe '.user_seat' do
    subject { described_class.user_seat }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_USER_SEAT has value' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_USER_SEAT' => 'John Doe' }) }
        it { should eq 'John Doe' }
      end

      context 'when CI environment has value' do
        before do
          expect(described_class).to receive(:ci_env_for).with(:user_seat).and_return('Jane Doe')
        end

        it { should eq 'Jane Doe' }
      end
    end

    context "when ENV doesn't exist" do
      it { should be nil }
    end
  end

  describe '.masked_seat_hash' do
    subject { described_class.masked_user_seat }

    before do
      expect(described_class).to receive(:user_seat).at_least(1).and_return(user_seat)
    end

    context 'when the user seat is a name' do
      let(:user_seat) { 'John Doe' }

      it { expect(subject).to eq 'Jo** Do*' }
    end

    context 'when the user seat is an e-mail' do
      let(:user_seat) { 'john.doe@example.com' }

      it { expect(subject).to eq 'jo**.do*@ex*****.co*' }
    end

    context 'when the user seat is nil' do
      let(:user_seat) { nil }

      it { expect(subject).to be_nil }
    end
  end

  describe '.test_file_pattern' do
    subject { described_class.test_file_pattern }

    context 'when ENV exists' do
      let(:test_file_pattern) { 'custom_spec/**{,/*/**}/*_spec.rb' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_PATTERN' => test_file_pattern }) }
      it { should eq test_file_pattern }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.slow_test_file_pattern' do
    subject { described_class.slow_test_file_pattern }

    context 'when ENV exists' do
      let(:slow_test_file_pattern) { 'spec/features/*_spec.rb' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN' => slow_test_file_pattern }) }
      it { should eq slow_test_file_pattern }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_file_exclude_pattern' do
    subject { described_class.test_file_exclude_pattern }

    context 'when ENV exists' do
      let(:test_file_exclude_pattern) { 'spec/features/*_spec.rb' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_EXCLUDE_PATTERN' => test_file_exclude_pattern }) }
      it { should eq test_file_exclude_pattern }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_file_list' do
    subject { described_class.test_file_list }

    context 'when ENV exists' do
      let(:test_file_list) { 'spec/features/dashboard_spec.rb,spec/models/user.rb:10,spec/models/user.rb:29' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_LIST' => test_file_list }) }
      it { should eq test_file_list }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_file_list_source_file' do
    subject { described_class.test_file_list_source_file }

    context 'when ENV exists' do
      let(:test_file_list_source_file) { 'spec/fixtures/test_file_list_source_file.txt' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILE_LIST_SOURCE_FILE' => test_file_list_source_file }) }
      it { should eq test_file_list_source_file }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_dir' do
    subject { described_class.test_dir }

    context 'when ENV exists' do
      let(:test_dir) { 'spec' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_DIR' => test_dir }) }
      it { should eql test_dir }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.repository_adapter' do
    subject { described_class.repository_adapter }

    context 'when ENV exists' do
      let(:repository_adapter) { 'git' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_REPOSITORY_ADAPTER' => repository_adapter }) }
      it { should eq repository_adapter }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.recording_enabled' do
    subject { described_class.recording_enabled }

    context 'when ENV exists' do
      let(:recording_enabled) { 'true' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_RECORDING_ENABLED' => recording_enabled }) }
      it { should eq recording_enabled }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end


  describe '.regular_mode?' do
    subject { described_class.regular_mode? }

    before do
      expect(described_class).to receive(:recording_enabled?).and_return(recording_enabled)
    end

    context 'when recording is enabled' do
      let(:recording_enabled) { true }
      it { should be true }
    end

    context 'when recording is not enabled' do
      let(:recording_enabled) { false }
      it { should be false }
    end
  end

  describe '.recording_enabled?' do
    subject { described_class.recording_enabled? }

    before do
      expect(described_class).to receive(:recording_enabled).and_return(recording_enabled)
    end

    context 'when enabled' do
      let(:recording_enabled) { 'true' }

      it { should be true }
    end

    context 'when disabled' do
      let(:recording_enabled) { nil }

      it { should be false }
    end
  end

  describe '.queue_recording_enabled' do
    subject { described_class.queue_recording_enabled }

    context 'when ENV exists' do
      let(:queue_recording_enabled) { 'true' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_QUEUE_RECORDING_ENABLED' => queue_recording_enabled }) }
      it { should eq queue_recording_enabled }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.queue_recording_enabled?' do
    subject { described_class.queue_recording_enabled? }

    before do
      expect(described_class).to receive(:queue_recording_enabled).and_return(queue_recording_enabled)
    end

    context 'when enabled' do
      let(:queue_recording_enabled) { 'true' }

      it { should be true }
    end

    context 'when disabled' do
      let(:queue_recording_enabled) { nil }

      it { should be false }
    end
  end

  describe '.queue_id' do
    subject { described_class.queue_id }

    context 'when ENV exists' do
      let(:queue_id) { 'fake-queue-id' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_QUEUE_ID' => queue_id }) }
      it { should eq queue_id }
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it do
        expect { subject }.to raise_error('Missing Queue ID')
      end
    end
  end

  describe '.subset_queue_id' do
    subject { described_class.subset_queue_id }

    context 'when ENV exists' do
      let(:subset_queue_id) { 'fake-subset-queue-id' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_SUBSET_QUEUE_ID' => subset_queue_id }) }
      it { should eq subset_queue_id }
    end

    context "when ENV doesn't exist" do
      it do
        expect { subject }.to raise_error('Missing Subset Queue ID')
      end
    end
  end

  describe '.fallback_mode_enabled' do
    subject { described_class.fallback_mode_enabled }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_FALLBACK_MODE_ENABLED' => 'false' }) }
      it { should eq 'false' }
    end

    context "when ENV doesn't exist" do
      it { should be true }
    end
  end

  describe '.fallback_mode_enabled?' do
    subject { described_class.fallback_mode_enabled? }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_FALLBACK_MODE_ENABLED' => 'false' }) }
      it { should be false }
    end

    context "when ENV doesn't exist" do
      it { should be true }
    end
  end

  describe '.test_files_encrypted' do
    subject { described_class.test_files_encrypted }

    context 'when ENV exists' do
      let(:test_files_encrypted) { 'true' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_FILES_ENCRYPTED' => test_files_encrypted }) }
      it { should eq test_files_encrypted }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_files_encrypted?' do
    subject { described_class.test_files_encrypted? }

    before do
      expect(described_class).to receive(:test_files_encrypted).and_return(test_files_encrypted)
    end

    context 'when enabled' do
      let(:test_files_encrypted) { 'true' }

      it { should be true }
    end

    context 'when disabled' do
      let(:test_files_encrypted) { nil }

      it { should be false }
    end
  end

  describe '.modify_default_rspec_formatters' do
    subject { described_class.modify_default_rspec_formatters }

    context 'when ENV exists' do
      let(:modify_default_rspec_formatters) { 'false' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_MODIFY_DEFAULT_RSPEC_FORMATTERS' => modify_default_rspec_formatters }) }
      it { should eq modify_default_rspec_formatters }
    end

    context "when ENV doesn't exist" do
      it { should be true }
    end
  end

  describe '.modify_default_rspec_formatters?' do
    subject { described_class.modify_default_rspec_formatters? }

    before do
      expect(described_class).to receive(:modify_default_rspec_formatters).and_return(modify_default_rspec_formatters)
    end

    context 'when enabled' do
      let(:modify_default_rspec_formatters) { true }

      it { should be true }
    end

    context 'when disabled' do
      let(:modify_default_rspec_formatters) { false }

      it { should be false }
    end
  end

  describe '.branch_encrypted' do
    subject { described_class.branch_encrypted }

    context 'when ENV exists' do
      let(:branch_encrypted) { 'true' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_BRANCH_ENCRYPTED' => branch_encrypted }) }
      it { should eq branch_encrypted }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.branch_encrypted?' do
    subject { described_class.branch_encrypted? }

    before do
      expect(described_class).to receive(:branch_encrypted).and_return(branch_encrypted)
    end

    context 'when enabled' do
      let(:branch_encrypted) { 'true' }

      it { should be true }
    end

    context 'when disabled' do
      let(:branch_encrypted) { nil }

      it { should be false }
    end
  end

  describe '.salt' do
    subject { described_class.salt }

    context 'when ENV exists' do
      let(:salt) { '123' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_SALT' => salt }) }
      it { should eq salt }
    end

    context "when ENV doesn't exist" do
      it do
        expect { subject }.to raise_error('Missing environment variable KNAPSACK_PRO_SALT')
      end
    end
  end

  describe '.endpoint' do
    subject { described_class.endpoint }

    context 'when ENV exists' do
      let(:endpoint) { 'http://api-custom-url.knapsackpro.com' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_ENDPOINT' => endpoint }) }
      it { should eq endpoint }
    end

    context "when ENV doesn't exist" do
      context 'when default mode' do
        it { should eq 'https://api.knapsackpro.com' }
      end

      context 'when development mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'development' }) }
        it { should eq 'http://api.knapsackpro.test:3000' }
      end

      context 'when test mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'test' }) }
        it { should eq 'https://api-staging.knapsackpro.com' }
      end

      context 'when production mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'production' }) }
        it { should eq 'https://api.knapsackpro.com' }
      end

      context 'when unknown mode' do
        before do
          expect(described_class).to receive(:mode).and_return(:fake)
        end

        it do
          expect { subject }.to raise_error('Missing environment variable KNAPSACK_PRO_ENDPOINT')
        end
      end
    end
  end

  describe '.fixed_test_suite_split?' do
    subject { described_class.fixed_test_suite_split? }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT=true' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT' => 'true' }) }
        it { should be true }
      end

      context 'when KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT=false' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT' => 'false' }) }
        it { should be false }
      end
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it { should be true }
    end
  end

  describe '.fixed_queue_split?' do
    subject { described_class.fixed_queue_split? }
    after(:each) { described_class.remove_instance_variable(:@fixed_queue_split) }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_FIXED_QUEUE_SPLIT=false' do
        [
          ['AppVeyor', { 'APPVEYOR' => '123' }],
          ['Buildkite', { 'BUILDKITE' => 'true' }],
          ['CircleCI', { 'CIRCLECI' => 'true' }],
          ['Cirrus CI', { 'CIRRUS_CI' => 'true' }],
          ['Codefresh', { 'CF_BUILD_ID' => '123' }],
          ['Codeship', { 'CI_NAME' => 'codeship' }],
          ['GitHub Actions', { 'GITHUB_ACTIONS' => 'true' }],
          ['GitLab CI', { 'GITLAB_CI' => 'true' }],
          ['Heroku CI', { 'HEROKU_TEST_RUN_ID' => '123' }],
          ['Semaphore CI 1.0', { 'SEMAPHORE_BUILD_NUMBER' => '123' }],
          ['Semaphore CI 2.0', { 'SEMAPHORE' => 'true', 'SEMAPHORE_WORKFLOW_ID' => '123' }],
          ['Travis CI', { 'TRAVIS' => 'true' }],
          ['Unsupported CI', {}],
        ].each do |ci, env|
          it "on #{ci} it is false" do
            logger = instance_double(Logger)
            allow(KnapsackPro).to receive(:logger).and_return(logger)
            expect(logger).not_to receive(:info)

            stub_const("ENV", env.merge({ 'KNAPSACK_PRO_FIXED_QUEUE_SPLIT' => 'false' }))

            expect(subject).to eq(false)
          end
        end
      end

      context 'when KNAPSACK_PRO_FIXED_QUEUE_SPLIT=true' do
        [
          ['AppVeyor', { 'APPVEYOR' => '123' }],
          ['Buildkite', { 'BUILDKITE' => 'true' }],
          ['CircleCI', { 'CIRCLECI' => 'true' }],
          ['Cirrus CI', { 'CIRRUS_CI' => 'true' }],
          ['Codefresh', { 'CF_BUILD_ID' => '123' }],
          ['Codeship', { 'CI_NAME' => 'codeship' }],
          ['GitHub Actions', { 'GITHUB_ACTIONS' => 'true' }],
          ['GitLab CI', { 'GITLAB_CI' => 'true' }],
          ['Heroku CI', { 'HEROKU_TEST_RUN_ID' => '123' }],
          ['Semaphore CI 1.0', { 'SEMAPHORE_BUILD_NUMBER' => '123' }],
          ['Semaphore CI 2.0', { 'SEMAPHORE' => 'true', 'SEMAPHORE_WORKFLOW_ID' => '123' }],
          ['Travis CI', { 'TRAVIS' => 'true' }],
          ['Unsupported CI', {}],
        ].each do |ci, env|
          it "on #{ci} it is true" do
            logger = instance_double(Logger)
            allow(KnapsackPro).to receive(:logger).and_return(logger)
            expect(logger).not_to receive(:info)

            stub_const("ENV", env.merge({ 'KNAPSACK_PRO_FIXED_QUEUE_SPLIT' => 'true' }))

            expect(subject).to eq(true)
          end
        end
      end
    end

    context "when ENV doesn't exist" do
      [
        ['AppVeyor', { 'APPVEYOR' => '123' }, false],
        ['Buildkite', { 'BUILDKITE' => 'true' }, true],
        ['CircleCI', { 'CIRCLECI' => 'true' }, false],
        ['Cirrus CI', { 'CIRRUS_CI' => 'true' }, false],
        ['Codefresh', { 'CF_BUILD_ID' => '123' }, false],
        ['Codeship', { 'CI_NAME' => 'codeship' }, true],
        ['GitHub Actions', { 'GITHUB_ACTIONS' => 'true' }, true],
        ['GitLab CI', { 'GITLAB_CI' => 'true' }, true],
        ['Heroku CI', { 'HEROKU_TEST_RUN_ID' => '123' }, false],
        ['Semaphore CI 1.0', { 'SEMAPHORE_BUILD_NUMBER' => '123' }, false],
        ['Semaphore CI 2.0', { 'SEMAPHORE' => 'true', 'SEMAPHORE_WORKFLOW_ID' => '123' }, false],
        ['Travis CI', { 'TRAVIS' => 'true' }, true],
        ['Unsupported CI', {}, true],
      ].each do |ci, env, expected|
        it "on #{ci} it is #{expected}" do
          logger = instance_double(Logger)
          expect(KnapsackPro).to receive(:logger).and_return(logger)
          expect(logger).to receive(:info).with("KNAPSACK_PRO_FIXED_QUEUE_SPLIT is not set. Using default value: #{expected}. Learn more at #{KnapsackPro::Urls::FIXED_QUEUE_SPLIT}")

          stub_const("ENV", env)

          expect(subject).to eq(expected)
        end
      end
    end
  end

  describe '.cucumber_queue_prefix' do
    subject { described_class.cucumber_queue_prefix }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_CUCUMBER_QUEUE_PREFIX' => 'bundle exec spring' }) }
      it { should eq 'bundle exec spring' }
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it { should eq 'bundle exec' }
    end
  end

  describe '.rspec_split_by_test_examples' do
    subject { described_class.rspec_split_by_test_examples }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES' => true }) }
      it { should eq true }
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it { should be false }
    end
  end

  describe '.rspec_split_by_test_examples?' do
    subject { described_class.rspec_split_by_test_examples? }

    context 'when ENV exists' do
      context 'when KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES=true' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES' => 'true' }) }
        it { should be true }
      end

      context 'when KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES=false' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_RSPEC_SPLIT_BY_TEST_EXAMPLES' => 'false' }) }
        it { should be false }
      end
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it { should be false }
    end
  end

  describe '.rspec_test_example_detector_prefix' do
    subject { described_class.rspec_test_example_detector_prefix }

    context 'when ENV exists' do
      before { stub_const("ENV", { 'KNAPSACK_PRO_RSPEC_TEST_EXAMPLE_DETECTOR_PREFIX' => '' }) }
      it { should eq '' }
    end

    context "when ENV doesn't exist" do
      before { stub_const("ENV", {}) }
      it { should eq 'bundle exec' }
    end
  end

  describe '.test_suite_token' do
    subject { described_class.test_suite_token }

    context 'when ENV exists' do
      let(:token) { 'xyz' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN' => 'xyz' }) }
      it { should eq token }
    end

    context "when ENV doesn't exist" do
      it do
        expect { subject }.to raise_error('Missing environment variable KNAPSACK_PRO_TEST_SUITE_TOKEN. You should set environment variable like KNAPSACK_PRO_TEST_SUITE_TOKEN_RSPEC (note there is suffix _RSPEC at the end). knapsack_pro gem will set KNAPSACK_PRO_TEST_SUITE_TOKEN based on KNAPSACK_PRO_TEST_SUITE_TOKEN_RSPEC value. If you use other test runner than RSpec then use proper suffix.')
      end
    end
  end

  describe '.test_suite_token_rspec' do
    subject { described_class.test_suite_token_rspec }

    context 'when ENV exists' do
      let(:test_suite_token_rspec) { 'rspec-token' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_RSPEC' => test_suite_token_rspec }) }
      it { should eq test_suite_token_rspec }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_suite_token_minitest' do
    subject { described_class.test_suite_token_minitest }

    context 'when ENV exists' do
      let(:test_suite_token_minitest) { 'minitest-token' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_MINITEST' => test_suite_token_minitest }) }
      it { should eq test_suite_token_minitest }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_suite_token_test_unit' do
    subject { described_class.test_suite_token_test_unit }

    context 'when ENV exists' do
      let(:test_suite_token_test_unit) { 'test-unit-token' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_TEST_UNIT' => test_suite_token_test_unit }) }
      it { should eq test_suite_token_test_unit }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_suite_token_cucumber' do
    subject { described_class.test_suite_token_cucumber }

    context 'when ENV exists' do
      let(:test_suite_token_cucumber) { 'cucumber-token' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_CUCUMBER' => test_suite_token_cucumber }) }
      it { should eq test_suite_token_cucumber }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_suite_token_spinach' do
    subject { described_class.test_suite_token_spinach }

    context 'when ENV exists' do
      let(:test_suite_token_spinach) { 'spinach-token' }
      before { stub_const("ENV", { 'KNAPSACK_PRO_TEST_SUITE_TOKEN_SPINACH' => test_suite_token_spinach }) }
      it { should eq test_suite_token_spinach }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.mode' do
    subject { described_class.mode }

    context 'when ENV exists' do
      context 'when development mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'development' }) }

        it { should eq :development }
      end

      context 'when test mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'test' }) }

        it { should eq :test }
      end

      context 'when production mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'production' }) }

        it { should eq :production }
      end

      context 'when fake mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => 'fake' }) }

        it do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when blank mode' do
        before { stub_const("ENV", { 'KNAPSACK_PRO_MODE' => '' }) }

        it do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end

    context "when ENV doesn't exist" do
      it { should eq :production }
    end
  end

  describe '.log_level' do
    subject { described_class.log_level }

    context 'when ENV set to fatal' do
      let(:log_level) { 'fatal' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_LEVEL' => log_level }) }
      it { should eql ::Logger::FATAL }
    end

    context 'when ENV set to error' do
      let(:log_level) { 'error' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_LEVEL' => log_level }) }
      it { should eql ::Logger::ERROR }
    end

    context 'when ENV set to warn' do
      let(:log_level) { 'warn' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_LEVEL' => log_level }) }
      it { should eql ::Logger::WARN }
    end

    context 'when ENV set to info' do
      let(:log_level) { 'info' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_LEVEL' => log_level }) }
      it { should eql ::Logger::INFO }
    end

    context 'when ENV set with capital letters' do
      let(:log_level) { 'WARN' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_LEVEL' => log_level }) }
      it { should eql ::Logger::WARN }
    end

    context "when ENV doesn't exist" do
      it { should eql ::Logger::DEBUG }
    end
  end

  describe '.log_dir' do
    subject { described_class.log_dir }

    context 'when ENV set to directory path' do
      let(:log_dir) { 'log' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_LOG_DIR' => log_dir }) }
      it { should eql 'log' }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.test_runner_adapter' do
    subject { described_class.test_runner_adapter }

    context 'when ENV exists' do
      let(:test_runner_adapter) { 'RSpecAdapter' }
      before { stub_const('ENV', { 'KNAPSACK_PRO_TEST_RUNNER_ADAPTER' => test_runner_adapter }) }
      it { should eql 'RSpecAdapter' }
    end

    context "when ENV doesn't exist" do
      it { should be_nil }
    end
  end

  describe '.set_test_runner_adapter' do
    let(:adapter_class) { KnapsackPro::Adapters::RSpecAdapter }

    subject { described_class.set_test_runner_adapter(adapter_class) }

    it 'sets test runner adapter' do
      subject
      expect(described_class.test_runner_adapter).to eql 'RSpecAdapter'
    end
  end

  describe '.detected_ci' do
    [
      ['AppVeyor', { 'APPVEYOR' => '123' }, KnapsackPro::Config::CI::AppVeyor],
      ['Buildkite', { 'BUILDKITE' => 'true' }, KnapsackPro::Config::CI::Buildkite],
      ['CircleCI', { 'CIRCLECI' => 'true' }, KnapsackPro::Config::CI::Circle],
      ['Cirrus CI', { 'CIRRUS_CI' => 'true' }, KnapsackPro::Config::CI::CirrusCI],
      ['Codefresh', { 'CF_BUILD_ID' => '123' }, KnapsackPro::Config::CI::Codefresh],
      ['Codeship', { 'CI_NAME' => 'codeship' }, KnapsackPro::Config::CI::Codeship],
      ['GitHub Actions', { 'GITHUB_ACTIONS' => 'true' }, KnapsackPro::Config::CI::GithubActions],
      ['GitLab CI', { 'GITLAB_CI' => 'true' }, KnapsackPro::Config::CI::GitlabCI],
      ['Heroku CI', { 'HEROKU_TEST_RUN_ID' => '123' }, KnapsackPro::Config::CI::Heroku],
      ['Semaphore CI 1.0', { 'SEMAPHORE_BUILD_NUMBER' => '123' }, KnapsackPro::Config::CI::Semaphore],
      ['Semaphore CI 2.0', { 'SEMAPHORE' => 'true', 'SEMAPHORE_WORKFLOW_ID' => '123' }, KnapsackPro::Config::CI::Semaphore2],
      ['Travis CI', { 'TRAVIS' => 'true' }, KnapsackPro::Config::CI::Travis],
      ['Unsupported CI', {}, KnapsackPro::Config::CI::Base],
    ].each do |ci, env, expected|
      it "detects #{ci}" do
        stub_const("ENV", env)

        expect(described_class.detected_ci).to eq(expected)
      end
    end
  end

  describe '.ci?' do
    [
      ['CI from env', { 'CI' => 'True' }, true],
      ['Travis CI', { 'TRAVIS' => 'true' }, true],
      ['missing CI from ENV or development', {}, false],
    ].each do |ci, env, expected|
      it "detects #{ci}" do
        stub_const("ENV", env)

        expect(described_class.ci?).to eq(expected)
      end
    end
  end

  describe '.ci_provider' do
    [
      ['AppVeyor', { 'APPVEYOR' => '123' }],
      ['Azure Pipelines', { 'SYSTEM_TEAMFOUNDATIONCOLLECTIONURI' => '123' }],
      ['AWS CodeBuild', { 'CODEBUILD_BUILD_ARN' => '123' }],
      ['Bamboo', { 'bamboo_planKey' => '123' }],
      ['Bitbucket Pipelines', { 'BITBUCKET_COMMIT' => '123' }],
      ['Buddy.works', { 'BUDDY' => 'true' }],
      ['Buildkite', { 'BUILDKITE' => 'true' }],
      ['CircleCI', { 'CIRCLECI' => 'true' }],
      ['Cirrus CI', { 'CIRRUS_CI' => 'true' }],
      ['Codefresh', { 'CF_BUILD_ID' => '123' }],
      ['Codeship', { 'CI_NAME' => 'codeship' }],
      ['Drone.io', { 'DRONE' => 'true' }],
      ['GitHub Actions', { 'GITHUB_ACTIONS' => 'true' }],
      ['Gitlab CI', { 'GITLAB_CI' => 'true' }],
      ['Google Cloud Build', { 'BUILDER_OUTPUT' => '123' }],
      ['Heroku CI', { 'HEROKU_TEST_RUN_ID' => '123' }],
      ['Jenkins', { 'JENKINS_URL' => '123' }],
      ['Semaphore CI 1.0', { 'SEMAPHORE_BUILD_NUMBER' => '123' }],
      ['Semaphore CI 2.0', { 'SEMAPHORE' => 'true', 'SEMAPHORE_WORKFLOW_ID' => '123' }],
      ['TeamCity', { 'TEAMCITY_VERSION' => '123' }],
      ['Travis CI', { 'TRAVIS' => 'true' }],
      ['Other', { 'CI' => 'true'}],
      [nil, {}],
    ].each do |ci, env|
      it "detects #{ci || 'missing CI from env or development'}" do
        stub_const("ENV", env)

        expect(described_class.ci_provider).to eq(ci)
      end
    end
  end
end
