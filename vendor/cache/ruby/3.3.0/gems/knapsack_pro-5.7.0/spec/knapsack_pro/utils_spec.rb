describe KnapsackPro::Utils do
  describe '.unsymbolize' do
    let(:test_files) do
      [
        { path: 'a_spec.rb', time_execution: 0.1 },
        { path: 'b_spec.rb', time_execution: 0.2 },
      ]
    end

    subject { described_class.unsymbolize(test_files) }

    it do
      should eq([
        { 'path' => 'a_spec.rb', 'time_execution' => 0.1 },
        { 'path' => 'b_spec.rb', 'time_execution' => 0.2 },
      ])
    end
  end
end
