require "rails_helper"

RSpec.describe ColorFromImage do
  it "returns a color" do
    expected_regexp = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
    expect(described_class.new("https://example.com").main).to match expected_regexp
  end
end
