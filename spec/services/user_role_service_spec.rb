require "rails_helper"

RSpec.describe UserRoleService do
  let(:user)        { create(:user) }
  let(:banned_user) { create(:user, :banned) }

  describe "#check_for_roles" do
    it "unbans a user if they were previously banned" do
      described_class.new(banned_user).check_for_roles(banned: "0")
      expect(banned_user.has_role?(:banned)).to eq(false)
    end

    it "bans a user when there is a reason included" do
      described_class.new(user).check_for_roles(banned: "1", reason_for_ban: "some reason")
      expect(user.has_role?(:banned)).to eq(true)
    end

    it "gives an error if there was no reason for ban included" do
      described_class.new(user).check_for_roles(banned: "1")
      expect(user.errors.messages[:reason_for_ban].first).
        to eq("can't be blank if banned is checked")
    end

    it "gives an error if there was a reason for ban but banned was not checked" do
      described_class.new(user).check_for_roles(banned: "0", reason_for_ban: "some reason")
      expect(user.errors.messages[:banned].first).
        to eq("was not checked but had the reason filled out")
    end

    it "warns a user when there is a reason included" do
      described_class.new(user).check_for_roles(warned: "1", reason_for_warning: "some_reason")
      expect(user.has_role?(:warned)).to eq(true)
    end

    it "gives an error if there was no reason for warning included" do
      described_class.new(user).check_for_roles(warned: "1")
      expect(user.errors.messages[:reason_for_warning].first).
        to eq("can't be blank if warned is checked")
    end

    it "gives an error if there was a reason for warning but warned was not checked" do
      described_class.new(user).check_for_roles(warned: "0", reason_for_warning: "some reason")
      expect(user.errors.messages[:warned].first).
        to eq("was not checked but had the reason filled out")
    end
  end

  describe "#new_roles?" do
    it "adds the trusted role to a user with valid params" do
      described_class.new(user).send(:new_roles?, trusted: "1")
      expect(user.has_role?(:trusted)).to eq(true)
    end

    it "adds the analytics role to a user with valid params" do
      described_class.new(user).send(:new_roles?, analytics: "1")
      expect(user.has_role?(:analytics_beta_tester)).to eq(true)
    end

    it "adds the scholar role to a user with valid params" do
      described_class.new(user).send(:new_roles?, scholar: "1")
      expect(user.has_role?(:workshop_pass)).to eq(true)
    end

    it "adds workshop_expiration date with valid params" do
      expiration_date = Time.now + 1.year
      described_class.new(user).
        send(:new_roles?, scholar: "1", workshop_expiration: expiration_date)
      expect(user.workshop_expiration).to eq(expiration_date)
    end

    it "doesn't add a workshop_expiration date if scholar is not checked" do
      expiration_date = Time.now + 1.year
      described_class.new(user).
        send(:new_roles?, scholar: "0", workshop_expiration: expiration_date)
      expect(user.workshop_expiration).to eq(nil)
    end
  end

  describe "#create_or_update_note" do
    it "updates a user's previous note" do
      user.notes.create(reason: "banned", content: "some reason", noteable_id: user.id, noteable_type: "User", author_id: user.id)
      described_class.new(user).send(:create_or_update_note, "banned", "a more specific reason")
      expect(user.notes.count).to eq(1)
    end
  end
end
