require 'rails_helper'

RSpec.describe ColorFromImage do
  it 'should return a color' do
    expect(described_class.new("https://example.com").main).to match /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
  end
end
