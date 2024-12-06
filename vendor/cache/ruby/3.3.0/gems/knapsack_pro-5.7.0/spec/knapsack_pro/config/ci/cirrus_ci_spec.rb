describe KnapsackPro::Config::CI::CirrusCI do
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

    context 'when the environment exists' do
      let(:env) { { 'CI_NODE_INDEX' => 3 } }
      it { should eql 3 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_build_id' do
    subject { described_class.new.node_build_id }

    context 'when the environment exists' do
      let(:env) { { 'CIRRUS_BUILD_ID' => 123 } }
      it { should eql 123 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when the environment exists' do
      let(:env) { { 'CIRRUS_CHANGE_IN_REPO' => '2e13512fc230d6f9ebf4923352718e4d' } }
      it { should eql '2e13512fc230d6f9ebf4923352718e4d' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when the environment exists' do
      let(:env) { { 'CIRRUS_BRANCH' => 'master' } }
      it { should eql 'master' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    context 'when the environment exists' do
      let(:env) { { 'CIRRUS_WORKING_DIR' => '/tmp/cirrus-ci-build' } }
      it { should eql '/tmp/cirrus-ci-build' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end
end
