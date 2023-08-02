require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20230718102644_backfill_user_blank_name.rb",
)

describe DataUpdateScripts::BackfillUserBlankName do
  let(:invalid_user_with_blank_name) { make_user_for(" ", "user_name") }
  let(:valid_user_name_with_trailing_spaces) { create(:user, name: "  Name  ") }
  let(:valid_user) { create(:user) }

  def make_user_for(name, username)
    build(:user, name: name, username: username).tap do |user|
      user.save(validate: false)
    end
  end

  it "replaces the blank name with the username" do
    username = invalid_user_with_blank_name.username

    expect { described_class.new.run }
      .to change { invalid_user_with_blank_name.reload.name }
      .from(" ")
      .to(username)
  end

  it "does not modify the name if it has trailing whitespaces" do
    expect { described_class.new.run }.not_to change(:valid_user_name_with_trailing_spaces, :name)
  end

  it "does not modify the name if it is valid" do
    expect { described_class.new.run }.not_to change(:valid_user, :name)
  end
end
