require "rails_helper"

RSpec.describe EmailAuthorization, type: :model do
  it { is_expected.to validate_inclusion_of(:type_of).in_array(EmailAuthorization::TYPES) }

  describe "#sent_at" do
    it "calls #created_at" do
      email_auth = create(:email_authorization)
      expect(email_auth.sent_at).to eq email_auth.created_at
    end
  end
end
