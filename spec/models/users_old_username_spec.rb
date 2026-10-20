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

  describe "recording on rename" do
    it "records the previous username for any rename path" do
      user = create(:user)
      previous_username = user.username

      expect { user.update!(username: "#{previous_username}_new") }
        .to change { described_class.exists?(username: previous_username) }.from(false).to(true)
    end

    it "records nothing when the user is created" do
      expect { create(:user) }.not_to change(described_class, :count)
    end

    it "does not raise or abort the transaction when the username is already recorded" do
      user = create(:user)
      previous_username = user.username
      create(:users_old_username, user: user, username: previous_username)

      expect { user.update!(username: "#{previous_username}_new") }.not_to raise_error
      expect(user.reload.username).to eq("#{previous_username}_new")
    end
  end
end
