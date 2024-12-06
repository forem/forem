describe KnapsackPro::Config::CI::Semaphore2 do
  let(:env) { {} }

  before do
    stub_const('ENV', env)
  end

  it { should be_kind_of KnapsackPro::Config::CI::Base }

  describe '#node_total' do
    subject { described_class.new.node_total }

    context 'when the environment exists' do
      let(:env) { { 'SEMAPHORE_JOB_COUNT' => 4 } }
      it { should eql 4 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_index' do
    subject { described_class.new.node_index }

    context 'when the environment exists' do
      let(:env) { { 'SEMAPHORE_JOB_INDEX' => 4 } }
      it { should eql 3 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#node_build_id' do
    subject { described_class.new.node_build_id }

    context 'when the environment exists' do
      let(:env) { { 'SEMAPHORE_WORKFLOW_ID' => 123 } }
      it { should eql 123 }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#commit_hash' do
    subject { described_class.new.commit_hash }

    context 'when the environment exists' do
      let(:env) { { 'SEMAPHORE_GIT_SHA' => '4323320992a21b1169e3ac5b7789d379597738e6' } }
      it { should eql '4323320992a21b1169e3ac5b7789d379597738e6' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#branch' do
    subject { described_class.new.branch }

    context 'when the environment exists' do
      let(:env) { { 'SEMAPHORE_GIT_BRANCH' => 'master' } }
      it { should eql 'master' }
    end

    context "when the environment doesn't exist" do
      it { should be nil }
    end
  end

  describe '#project_dir' do
    subject { described_class.new.project_dir }

    context 'when HOME and SEMAPHORE_GIT_DIR environments exist' do
      let(:env) do
        {
          'HOME' => '/home/semaphore',
          'SEMAPHORE_GIT_DIR' => 'project-name',
        }
      end
      it { should eql '/home/semaphore/project-name' }
    end

    context 'when only HOME environment exists' do
      let(:env) do
        {
          'HOME' => '/home/semaphore',
        }
      end
      it { should be nil }
    end

    context 'when only SEMAPHORE_GIT_DIR environment exists' do
      let(:env) do
        {
          'SEMAPHORE_GIT_DIR' => 'project-name'
        }
      end
      it { should be nil }
    end

    context "when the environments don't exist" do
      it { should be nil }
    end
  end
end
