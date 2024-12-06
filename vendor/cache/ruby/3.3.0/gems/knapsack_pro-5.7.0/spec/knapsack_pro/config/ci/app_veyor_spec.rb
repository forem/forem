describe KnapsackPro::Config::CI::AppVeyor do
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
      let(:env) { { 'APPVEYOR_BUILD_ID' => 123 } }
      it { should eql 123 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when the environment exists' do
      let(:env) { { 'APPVEYOR_REPO_COMMIT' => '2e13512fc230d6f9ebf4923352718e4d' } }
      it { should eql '2e13512fc230d6f9ebf4923352718e4d' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when the environment exists' do
      let(:env) { { 'APPVEYOR_REPO_BRANCH' => 'master' } }
      it { should eql 'master' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    context 'when the environment exists' do
      let(:env) { { 'APPVEYOR_BUILD_FOLDER' => '/path/to/clone/repo' } }
      it { should eql '/path/to/clone/repo' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#user_seat' do
    subject { described_class.new.user_seat }

    context 'when the APPVEYOR_REPO_COMMIT_AUTHOR environment variable exists' do
      let(:env) { { 'APPVEYOR_REPO_COMMIT_AUTHOR' => 'jane_doe' } }

      it { should eql 'jane_doe' }
    end

    context "when the APPVEYOR_REPO_COMMIT_AUTHOR environment variable doesn't exist" do
      it { should be nil }
    end
  end
end
