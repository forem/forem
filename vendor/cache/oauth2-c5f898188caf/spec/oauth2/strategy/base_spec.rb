RSpec.describe OAuth2::Strategy::Base do
  it 'initializes with a Client' do
    expect { described_class.new(OAuth2::Client.new('abc', 'def')) }.not_to raise_error
  end
end
