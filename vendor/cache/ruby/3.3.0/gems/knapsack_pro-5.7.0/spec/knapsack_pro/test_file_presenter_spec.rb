describe KnapsackPro::TestFilePresenter do
  describe '.stringify_paths' do
    let(:test_file_paths) { ['a_spec.rb', 'b_spec.rb'] }

    subject { described_class.stringify_paths(test_file_paths) }

    it { should eq '"a_spec.rb" "b_spec.rb"' }
  end

  describe '.paths' do
    let(:test_files) do
      [
        { 'path' => 'a_spec.rb' },
        { 'path' => 'b_spec.rb' },
      ]
    end

    subject { described_class.paths(test_files) }

    it { should eq ['a_spec.rb', 'b_spec.rb'] }
  end
end
