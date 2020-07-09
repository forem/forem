require "rails_helper"

RSpec.describe ColorFromImage, type: :labor do
  it "returns a color" do
    color = described_class.new(File.expand_path("spec/fixtures/files/image_gps_data.jpg")).main

    expected_regexp = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/
    expect(color).to match(expected_regexp)
  end
end
