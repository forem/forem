describe KnapsackPro::TestFlatDistributor do
  let(:test_flat_distributor) { described_class.new(test_files, node_total) }
  let(:node_total) { 2 }
  let(:test_files) do
    [
      { 'path' => 'spec/dir1/a_spec.rb' },
      { 'path' => 'spec/dir2/a_spec.rb' },
      { 'path' => 'spec/dir3/a_spec.rb' },
      { 'path' => 'spec/feature/e_spec.rb' },
      { 'path' => 'spec/models/b_spec.rb' },
      { 'path' => 'spec/feature/c_spec.rb' },
      { 'path' => 'spec/models/d_spec.rb' },
      { 'path' => 'spec/feature/a_spec.rb' },
      { 'path' => 'spec/models/f_spec.rb' },
      { 'path' => 'spec/models/g_spec.rb' },
      { 'path' => 'spec/dir4/h_spec.rb' },
      { 'path' => 'spec/models/i_spec.rb' },
    ]
  end

  describe '#nodes' do
    subject { test_flat_distributor.nodes }

    it do
      should eq({
        0 => [
          { 'path' => 'spec/feature/a_spec.rb' },
          { 'path' => 'spec/feature/e_spec.rb' },
          { 'path' => 'spec/models/d_spec.rb' },
          { 'path' => 'spec/models/g_spec.rb' },
          { 'path' => 'spec/dir1/a_spec.rb' },
          { 'path' => 'spec/dir3/a_spec.rb' },
        ],
        1 => [
          { 'path' => 'spec/feature/c_spec.rb' },
          { 'path' => 'spec/models/b_spec.rb' },
          { 'path' => 'spec/models/f_spec.rb' },
          { 'path' => 'spec/models/i_spec.rb' },
          { 'path' => 'spec/dir2/a_spec.rb' },
          { 'path' => 'spec/dir4/h_spec.rb' },
        ],
      })
    end
  end

  describe '#test_files_for_node' do
    subject { test_flat_distributor.test_files_for_node(1) }

    it do
      should eq([
        { 'path' => 'spec/feature/c_spec.rb' },
        { 'path' => 'spec/models/b_spec.rb' },
        { 'path' => 'spec/models/f_spec.rb' },
        { 'path' => 'spec/models/i_spec.rb' },
        { 'path' => 'spec/dir2/a_spec.rb' },
        { 'path' => 'spec/dir4/h_spec.rb' },
      ])
    end
  end
end
