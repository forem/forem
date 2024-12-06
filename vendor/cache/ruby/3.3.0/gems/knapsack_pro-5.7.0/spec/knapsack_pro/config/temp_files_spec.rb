describe KnapsackPro::Config::TempFiles do
  describe 'TEMP_DIRECTORY_PATH' do
    subject { described_class::TEMP_DIRECTORY_PATH }

    it 'returns temporary directory path' do
      expect(subject).to eq '.knapsack_pro'
    end
  end

  describe '.ensure_temp_directory_exists!', :clear_tmp do
    let(:gitignore_file_path) { '.knapsack_pro/.gitignore' }

    subject { described_class.ensure_temp_directory_exists! }

    it 'creates .gitignore file' do
      expect { subject }.to change { File.exist?(gitignore_file_path) }.from(false).to(true)
    end

    it '.gitignore file has correct content to ignore all files in temporary directory' do
      subject

      expect(File.read(gitignore_file_path)).to match /^\*$/
    end
  end
end
