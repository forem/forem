describe KnapsackPro::TestFileCleaner do
  describe '.clean' do
    let(:test_file_path) { './models/user_spec.rb' }

    subject { described_class.clean(test_file_path) }

    it 'removes ./ from the begining of the test file path' do
      expect(subject).to eq 'models/user_spec.rb'
    end
  end
end
