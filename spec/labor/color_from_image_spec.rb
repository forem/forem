require "rails_helper"

RSpec.describe ColorFromImage, type: :labor do
  it "returns a color" do
    expected_regexp = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
    expect(described_class.new(File.expand_path("spec/fixtures/files/image_gps_data.jpg")).main).to match expected_regexp
  end
end
