require "rails_helper"

RSpec.describe Liquid::Raw do
  it "uses the correct regexp for invalid tokens" do
    expected_regexp = /\A(.*)#{Liquid::TagStart}\s*(\w+)\s*#{Liquid::TagEnd}\z/om
    expect(described_class::FullTokenPossiblyInvalid).to eq(expected_regexp)
  end
end
