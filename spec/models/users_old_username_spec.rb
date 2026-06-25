require "rails_helper"

RSpec.describe UsersOldUsername do
  describe "validations" do
    subject { build(:users_old_username) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }
  end

  describe "uniqueness" do
    it "does not allow duplicate usernames" do
      user = create(:user)
      create(:users_old_username, user: user, username: "oldname")
      duplicate = build(:users_old_username, user: user, username: "oldname")
      expect(duplicate).not_to be_valid
    end

    it "allows different usernames for the same user" do
      user = create(:user)
      create(:users_old_username, user: user, username: "oldname1")
      record = build(:users_old_username, user: user, username: "oldname2")
      expect(record).to be_valid
    end
  end
end
