describe KnapsackPro::Config::CI::GithubActions do
  let(:env) { {} }

  before do
    stub_const('ENV', env)
  end

  it { should be_kind_of KnapsackPro::Config::CI::Base }

  describe '#node_total' do
    subject { described_class.new.node_total }

    it { should be nil }
  end

  describe '#node_index' do
    subject { described_class.new.node_index }

    it { should be nil }
  end

  describe '#node_build_id' do
    subject { described_class.new.node_build_id }

    context 'when the environment exists' do
      let(:env) { { 'GITHUB_RUN_ID' => 2706 } }
      it { should eql 2706 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_retry_count' do
    subject { described_class.new.node_retry_count }

    context 'when the environment exists' do
      let(:env) { { 'GITHUB_RUN_ATTEMPT' => 2 } }
      it { should eql 1 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when the environment exists' do
      let(:env) { { 'GITHUB_SHA' => '2e13512fc230d6f9ebf4923352718e4d' } }
      it { should eql '2e13512fc230d6f9ebf4923352718e4d' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when the environment exists' do
      context 'when GITHUB_REF has value' do
        let(:env) do
          {
            'GITHUB_REF' => 'main',
            'GITHUB_SHA' => '2e13512fc230d6f9ebf4923352718e4d',
          }
        end

        it { should eql 'main' }
      end

      context 'when GITHUB_REF is not set' do
        let(:env) do
          {
            'GITHUB_SHA' => '2e13512fc230d6f9ebf4923352718e4d',
          }
        end

        it { should eql '2e13512fc230d6f9ebf4923352718e4d' }
      end
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    context 'when the environment exists' do
      let(:env) { { 'GITHUB_WORKSPACE' => '/home/runner/work/my-repo-name/my-repo-name' } }
      it { should eql '/home/runner/work/my-repo-name/my-repo-name' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#user_seat' do
    subject { described_class.new.user_seat }

    context 'when the GITHUB_ACTOR environment variable exists' do
      let(:env) { { 'GITHUB_ACTOR' => 'jane_doe' } }

      it { should eql 'jane_doe' }
    end

    context "when the GITHUB_ACTOR environment variable doesn't exist" do
      it { should be nil }
    end
  end
end
