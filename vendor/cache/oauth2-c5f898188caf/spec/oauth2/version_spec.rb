RSpec.describe OAuth2::Version do
  it 'has a version number' do
    expect(described_class).not_to be nil
  end
  it 'is greater than 0.1.0' do
    expect(Gem::Version.new(described_class) > Gem::Version.new('0.1.0')).to be(true)
  end
end
