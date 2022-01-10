require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220104165348_nullify_empty_string_for_alias_for.rb",
)

describe DataUpdateScripts::NullifyEmptyStringForAliasFor do
  it "converts empty string `alias_for` to nil value" do
    Tag.upsert_all([
                     attributes_for(:tag).merge(id: 1, alias_for: "", created_at: Time.current,
                                                updated_at: Time.current),
                   ])
    tag = Tag.first

    expect { described_class.new.run }.to change { tag.reload.alias_for }.from("").to(nil)
  end
end
