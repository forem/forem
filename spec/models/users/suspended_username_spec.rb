require "rails_helper"

RSpec.describe Users::SuspendedUsername, type: :model do
  describe "validations" do
    subject { create(:suspended_username) }

    it { is_expected.to validate_presence_of(:username_hash) }
    it { is_expected.to validate_uniqueness_of(:username_hash) }
  end

  describe ".previously_banned?" do
    it "returns true if the user has been previously banned" do
      user = create(:user, :banned)
      described_class.create_from_user(user)

      expect(described_class.previously_banned?(user.username)).to be true
    end

    it "returns false if the user has not been previously_banned" do
      user = create(:user)

      expect(described_class.previously_banned?(user.username)).to be false
    end
  end

  describe ".create_from_user" do
    it "records a hash of the username in the database" do
      expect do
        described_class.create_from_user(create(:user, :banned))
      end.to change(described_class, :count).by(1)
    end
  end
end
