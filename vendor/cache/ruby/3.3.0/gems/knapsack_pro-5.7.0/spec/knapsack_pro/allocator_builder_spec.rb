describe KnapsackPro::AllocatorBuilder do
  let(:adapter_class) { KnapsackPro::Adapters::BaseAdapter }
  let(:allocator_builder) { described_class.new(adapter_class) }

  describe '#allocator' do
    let(:allocator) { double }

    subject { allocator_builder.allocator }

    before do
      fast_and_slow_test_files_to_run = double
      expect(allocator_builder).to receive(:fast_and_slow_test_files_to_run).and_return(fast_and_slow_test_files_to_run)

      fallback_mode_test_files = double
      expect(allocator_builder).to receive(:fallback_mode_test_files).and_return(fallback_mode_test_files)

      repository_adapter = double
      expect(KnapsackPro::RepositoryAdapterInitiator).to receive(:call).and_return(repository_adapter)

      ci_node_total = double
      expect(KnapsackPro::Config::Env).to receive(:ci_node_total).and_return(ci_node_total)
      ci_node_index = double
      expect(KnapsackPro::Config::Env).to receive(:ci_node_index).and_return(ci_node_index)

      expect(KnapsackPro::Allocator).to receive(:new).with(
        fast_and_slow_test_files_to_run: fast_and_slow_test_files_to_run,
        fallback_mode_test_files: fallback_mode_test_files,
        ci_node_total: ci_node_total,
        ci_node_index: ci_node_index,
        repository_adapter: repository_adapter,
      ).and_return(allocator)
    end

    it { should eq allocator }
  end
end
