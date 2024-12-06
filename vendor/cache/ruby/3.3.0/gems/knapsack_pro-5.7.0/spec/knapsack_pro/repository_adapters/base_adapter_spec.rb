describe KnapsackPro::RepositoryAdapters::BaseAdapter do
  describe '#commit_hash' do
    it do
      expect { subject.commit_hash }.to raise_error NotImplementedError
    end
  end

  describe '#branch' do
    it do
      expect { subject.branch }.to raise_error NotImplementedError
    end
  end
end
