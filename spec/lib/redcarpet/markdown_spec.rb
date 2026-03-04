require "spec_helper"
require "redcarpet"
require "timecop"

RSpec.describe Redcarpet::Markdown do
  it "renders markdown with redcarpet" do
    markdown = described_class.new(Redcarpet::Render::HTML)

    expect(markdown.render("**bold**")).to include("<strong>bold</strong>")
  end

  describe Timecop do
    describe ".freeze" do
      it "freezes and restores time" do
        frozen_time = Time.utc(2025, 1, 1, 12)

        described_class.freeze(frozen_time) do
          expect(Time.now.utc).to eq(frozen_time)
        end
      end
    end
  end
end
