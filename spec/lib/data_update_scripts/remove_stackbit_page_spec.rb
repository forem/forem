require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211206222716_remove_stackbit_page.rb",
)

describe DataUpdateScripts::RemoveStackbitPage do
  it "idempotently destroys the Stackbit page" do
    create(:page, slug: "connecting-with-stackbit")
    expect { described_class.new.run }
      .to change(Page, :count).by(-1)

    expect { described_class.new.run }
      .not_to change(Page, :count)
  end
end
