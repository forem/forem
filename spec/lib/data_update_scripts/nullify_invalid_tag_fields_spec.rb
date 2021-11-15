require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211115154021_nullify_invalid_tag_fields.rb",
)

describe DataUpdateScripts::NullifyInvalidTagFields do
  let(:tag) { create(:tag) }

  it "nullifies empty background color" do
    tag.update_column(:bg_color_hex, "")

    described_class.new.run

    expect(tag.reload.bg_color_hex).to be_nil
    expect(tag.valid?).to be true
  end

  it "nullifies empty text foreground color" do
    tag.update_column(:text_color_hex, "")

    described_class.new.run

    expect(tag.reload.text_color_hex).to be_nil
    expect(tag.valid?).to be true
  end

  it "nullifies when both colors empty" do
    tag.update_columns(bg_color_hex: "", text_color_hex: "")

    described_class.new.run

    expect(tag.reload.text_color_hex).to be_nil
    expect(tag.valid?).to be true
  end

  it "nullifies invalid alias_for values" do
    tag.update_columns(alias_for: "this-is-not-a-tag-name")

    described_class.new.run

    expect(tag.reload.alias_for).to be_nil
    expect(tag.valid?).to be true
  end

  it "nullifies empty string alias_for values" do
    tag.update(alias_for: "")

    described_class.new.run

    expect(tag.reload.alias_for).to be_nil
    expect(tag.valid?).to be true
  end
end
