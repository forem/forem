require "rails_helper"

RSpec.describe ApiSecret, type: :model do
  describe "validations" do
    subject { create(:api_secret) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(300) }

    it "validates the number of keys a user already has" do
      user = create(:user)
      create_list(:api_secret, 9, user_id: user.id)
      invalid_secret = create(:api_secret, user_id: user.id)

      expect(invalid_secret).not_to be_valid
      expect(invalid_secret.errors.full_messages.join).to include("limit of 10 per user has been reached")
    end
  end
end
