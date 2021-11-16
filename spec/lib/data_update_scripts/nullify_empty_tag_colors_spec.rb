require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211112173720_nullify_empty_tag_colors.rb",
)

describe DataUpdateScripts::NullifyEmptyTagColors do
  let(:empty_bg_tag) { create(:tag) }
  let(:empty_fg_tag) { create(:tag) }

  before do
    empty_bg_tag.update_columns(bg_color_hex: "")
    empty_fg_tag.update_columns(text_color_hex: "")
  end

  it "sets empty string in background color to nil" do
    expect { described_class.new.run }
      .to change { empty_bg_tag.reload.bg_color_hex }
      .from("").to(nil)
  end

  it "sets empty string in foreground text color to nil" do
    expect { described_class.new.run }
      .to change { empty_fg_tag.reload.text_color_hex }
      .from("").to(nil)
  end
end
