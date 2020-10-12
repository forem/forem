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
end
