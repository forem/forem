require "rails_helper"

RSpec.describe EmailAuthorization, type: :model do
  let(:email_authorization) { create(:email_authorization) }

  describe "validations" do
    describe "builtin validations" do
      subject { email_authorization }

      it { is_expected.to validate_inclusion_of(:type_of).in_array(EmailAuthorization::TYPES) }

      it { is_expected.to validate_presence_of(:type_of) }
    end
  end

  describe "#confirmation_token" do
    it "is created automatically" do
      expect(email_authorization.confirmation_token).to be_present
    end

    it "is not changed if already present" do
      token = email_authorization.confirmation_token
      email_authorization.save!

      expect(email_authorization.reload.confirmation_token).to eq(token)
    end
  end

  describe "#sent_at" do
    it "is aliased to #created_at" do
      expect(email_authorization.sent_at).to eq(email_authorization.created_at)
    end
  end

  describe ".last_verification_date" do
    let(:user) { create(:user) }

    it "returns nil if there are no email authorizations" do
      expect(described_class.last_verification_date(user)).to be(nil)
    end

    it "does not return unverified email authorizations" do
      create(:email_authorization, user: user, verified_at: nil)

      expect(described_class.last_verification_date(user)).to be(nil)
    end

    it "returns the last email authorization's date" do
      ea1 = create(:email_authorization, user: user, created_at: 1.day.ago, verified_at: 1.day.ago)
      create(:email_authorization, user: user, created_at: 1.month.ago, verified_at: 1.month.ago)

      expect(described_class.last_verification_date(user).iso8601).to eq(ea1.verified_at.iso8601)
    end
  end
end
