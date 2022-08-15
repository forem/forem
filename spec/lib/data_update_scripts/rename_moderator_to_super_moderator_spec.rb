require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220802100730_rename_moderator_to_super_moderator.rb",
)

describe DataUpdateScripts::RenameModeratorToSuperModerator do
  before do
    create :user
    create :user, :tag_moderator
    create :user, :super_admin
  end

  context "when there are no moderators" do
    it "does nothing" do
      expect(described_class.new.run).to eq(0)
    end
  end

  context "when there are users with the moderator role" do
    let!(:moderator) do
      # moderator is no longer a valid name, so to stage a user with the old role
      # we can't use the convenience methods as we need to bypass validation
      role = Role.new name: "moderator"
      role.save validate: false

      create(:user) do |user|
        user.roles << role
      end
    end

    it "updates those records" do
      expect(moderator.roles.pluck(:name)).to contain_exactly("moderator")
      expect(described_class.new.run).to eq(1)
      expect(moderator.reload).to be_super_moderator
    end
  end

  context "when rename has already run" do
    let!(:super_moderator) { create :user, :super_moderator }

    it "does nothing" do
      expect(described_class.new.run).to eq(0)
      expect(super_moderator.reload).to be_super_moderator
    end
  end
end
