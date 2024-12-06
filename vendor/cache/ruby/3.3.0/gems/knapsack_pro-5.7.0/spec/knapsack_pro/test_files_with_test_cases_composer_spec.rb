describe KnapsackPro::TestFilesWithTestCasesComposer do
  let(:test_files) do
    [
      { 'path' => 'spec/a_spec.rb' },
      { 'path' => 'spec/b_spec.rb' },
      { 'path' => 'spec/c_spec.rb' },
      { 'path' => 'spec/slow_1_spec.rb' },
      { 'path' => 'spec/slow_2_spec.rb' },
    ]
  end
  let(:slow_test_files) do
    [
      { 'path' => 'spec/slow_1_spec.rb', 'time_execution' => 1.0 },
      { 'path' => 'spec/slow_2_spec.rb', 'time_execution' => 2.0 },
    ]
  end
  let(:test_file_cases) do
    [
      { 'path' => 'spec/slow_1_spec.rb[1:1]' },
      { 'path' => 'spec/slow_1_spec.rb[1:2]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:1]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:2]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:3]' },
    ]
  end

  subject { described_class.call(test_files, slow_test_files, test_file_cases) }

  it 'returns test files that are not slow and test file cases for slow test files' do
    expect(subject).to eq([
      { 'path' => 'spec/a_spec.rb' },
      { 'path' => 'spec/b_spec.rb' },
      { 'path' => 'spec/c_spec.rb' },
      { 'path' => 'spec/slow_1_spec.rb[1:1]' },
      { 'path' => 'spec/slow_1_spec.rb[1:2]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:1]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:2]' },
      { 'path' => 'spec/slow_2_spec.rb[1:1:3]' },
    ])
  end
end
