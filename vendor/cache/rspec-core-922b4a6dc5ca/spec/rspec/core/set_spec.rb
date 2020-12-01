RSpec.describe 'RSpec::Core::Set' do

  let(:set) { RSpec::Core::Set.new([1, 2, 3]) }

  it 'takes an array of values' do
    expect(set).to include(1, 2, 3)
  end

  it 'can be appended to' do
    set << 4
    expect(set).to include 4
  end

  it 'can have more values merged in' do
    set.merge([4, 5]).merge([6])
    expect(set).to include(4, 5, 6)
  end

  it 'is enumerable' do
    expect(set).to be_an Enumerable
    expect { |p| set.each(&p) }.to yield_successive_args(1, 2, 3)
  end

  it 'supports deletions' do
    expect {
      set.delete(1)
    }.to change { set.include?(1) }.from(true).to(false)
  end

  it 'indicates if it is empty' do
    set = RSpec::Core::Set.new
    expect {
      set << 1
    }.to change { set.empty? }.from(true).to(false)
  end

  it 'can be cleared' do
    expect { set.clear }.to change { set.empty? }.from(false).to(true)
    expect(set.clear).to equal(set)
  end
end
