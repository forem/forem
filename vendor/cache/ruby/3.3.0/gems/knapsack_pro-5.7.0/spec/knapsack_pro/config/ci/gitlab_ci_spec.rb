describe KnapsackPro::Config::CI::GitlabCI do
  let(:env) { {} }

  before do
    stub_const('ENV', env)
  end

  it { should be_kind_of KnapsackPro::Config::CI::Base }

  describe '#node_total' do
    subject { described_class.new.node_total }

    context 'when the environment exists' do
      let(:env) { { 'CI_NODE_TOTAL' => 4 } }
      it { should eql 4 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_index' do
    subject { described_class.new.node_index }

    context 'when the environment exists and is in GitLab CI' do
      let(:env) { { 'CI_NODE_INDEX' => 4, 'GITLAB_CI' => 'true' } }
      it { should eql 3 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_build_id' do
    subject { described_class.new.node_build_id }

    context 'when Gitlab Release 9.0+ and environment exists' do
      let(:env) { { 'CI_PIPELINE_ID' => 7046507 } }
      it { should eql 7046507 }
    end

    context 'when Gitlab Release 8.x and environment exists' do
      let(:env) { { 'CI_BUILD_ID' => 7046508 } }
      it { should eql 7046508 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when Gitlab Release 9.0+ and environment exists' do
      let(:env) { { 'CI_COMMIT_SHA' => '4e0c4feec2267261fbcc060e82d7776e' } }
      it { should eql '4e0c4feec2267261fbcc060e82d7776e' }
    end

    context 'when Gitlab Release 8.x and environment exists' do
      let(:env) { { 'CI_BUILD_REF' => 'f76c468e3e1d570f71f5822b1e48bb04' } }
      it { should eql 'f76c468e3e1d570f71f5822b1e48bb04' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when Gitlab Release 9.0+ and environment exists' do
      let(:env) { { 'CI_COMMIT_REF_NAME' => 'main' } }
      it { should eql 'main' }
    end

    context 'when Gitlab Release 8.x and environment exists' do
      let(:env) { { 'CI_BUILD_REF_NAME' => 'main' } }
      it { should eql 'main' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    context 'when the environment exists' do
      let(:env) { { 'CI_PROJECT_DIR' => '/home/user/knapsack_pro-ruby' } }
      it { should eql '/home/user/knapsack_pro-ruby' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#user_seat' do
    subject { described_class.new.user_seat }

    context 'when the GITLAB_USER_NAME env var exists' do
      let(:env) do
        { 'GITLAB_USER_NAME' => 'Jane Doe',
          'GITLAB_USER_EMAIL' => nil }
      end

      it { should eql 'Jane Doe' }
    end

    context 'when the GITLAB_USER_EMAIL env var exists' do
      let(:env) do
        { 'GITLAB_USER_NAME' => nil,
          'GITLAB_USER_EMAIL' => 'janed@example.com' }
      end

      it { should eql 'janed@example.com' }
    end

    context 'when both GITLAB_USER_NAME and GITLAB_USER_EMAIL env vars exist' do
      let(:env) do
        { 'GITLAB_USER_NAME' => 'Jane Doe',
          'GITLAB_USER_EMAIL' => 'janed@example.com' }
      end

      it { should eql 'Jane Doe' }
    end

    context "when neither env var exists" do
      it { should be nil }
    end
  end
end
