require "rails_helper"

RSpec.describe Tag, type: :model do
  let(:tag) { build(:tag) }

  it "passes validations if bg_color_hex is valid" do
    tag.bg_color_hex = "#000000"
    expect(tag).to be_valid
  end

  it "fails validation if bg_color_hex is invalid" do
    tag.bg_color_hex = "0000000"
    expect(tag).not_to be_valid
  end

  it "passes validations if text_color_hex is valid" do
    tag.text_color_hex = "#000000"
    expect(tag).to be_valid
  end

  it "fails validation if text_color_hex is invalid" do
    tag.text_color_hex = "0000000"
    expect(tag).not_to be_valid
  end

  it "fails validation if the alias does not refer to an existing tag" do
    tag.alias_for = "hello"
    expect(tag).not_to be_valid
  end

  it "turns markdown into HTML before saving" do
    tag.rules_markdown = "Hello [Google](https://google.com)"
    tag.save
    expect(tag.rules_html.include?("href")).to be(true)
  end

  it "marks as updated after save" do
    tag.save
    expect(tag.reload.updated_at).to be > 1.minute.ago
  end

  it "knows class valid categories" do
    expect(described_class.valid_categories).to include("tool")
  end

  it "triggers cache busting on save" do
    expect { build(:tag).save }.to have_enqueued_job.on_queue("tags_bust_cache")
  end
end
