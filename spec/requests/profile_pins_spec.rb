require "rails_helper"

RSpec.describe "ProfilePins", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before { sign_in user }

  describe "POST /profile_pins" do
    it "creates a pin" do
      post "/profile_pins", params: {
        profile_pin: { pinnable_id: article.id }
      }
      expect(ProfilePin.last.pinnable_id).to eq(article.id)
    end
  end

  describe "PUT /profile_pins/:id" do
    it "votes on behalf of current user" do
      profile_pin = create(:profile_pin, pinnable_id: article.id, profile_id: user.id)
      put "/profile_pins/#{profile_pin.id}"
      expect(ProfilePin.all.size).to eq(0)
    end
  end
end
