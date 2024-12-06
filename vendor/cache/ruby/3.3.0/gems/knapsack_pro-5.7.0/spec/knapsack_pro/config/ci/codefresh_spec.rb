describe KnapsackPro::Config::CI::Codefresh do
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
      let(:env) { { 'CF_BUILD_ID' => '1005' } }
      it { should eql '1005' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when the environment exists' do
      let(:env) { { 'CF_REVISION' => 'b624067a61d2134df1db74ebdabb1d8d' } }
      it { should eql 'b624067a61d2134df1db74ebdabb1d8d' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when the environment exists' do
      let(:env) { { 'CF_BRANCH' => 'codefresh-branch' } }
      it { should eql 'codefresh-branch' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    it { should be nil }
  end


  describe '#user_seat' do
    subject { described_class.new.user_seat }

    context 'when the CF_BUILD_INITIATOR environment variable exists' do
      let(:env) { { 'CF_BUILD_INITIATOR' => 'jane_doe' } }

      it { should eql 'jane_doe' }
    end

    context "when the CF_BUILD_INITIATOR environment variable doesn't exist" do
      it { should be nil }
    end
  end
end
