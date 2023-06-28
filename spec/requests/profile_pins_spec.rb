require "rails_helper"

RSpec.describe "ProfilePins" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:article2) { create(:article, user_id: user.id) }
  let(:article3) { create(:article, user_id: user.id) }
  let(:article4) { create(:article, user_id: user.id) }
  let(:article5) { create(:article, user_id: user.id) }
  let(:article6) { create(:article, user_id: user.id) }
  let(:article7) { create(:article, user_id: user.id) }

  before { sign_in user }

  describe "POST /profile_pins" do
    it "creates a pin" do
      post "/profile_pins", params: {
        profile_pin: { pinnable_id: article.id }
      }
      expect(ProfilePin.last.pinnable_id).to eq(article.id)
    end

    it "allows only five pins" do
      articles = [article, article2, article3, article4, article5, article6, article7]
      articles.each do |a|
        post "/profile_pins", params: {
          profile_pin: { pinnable_id: a.id }
        }
      end
      expect(user.reload.profile_pins.size).to eq(5)
    end
  end

  describe "PUT /profile_pins/:id" do # delete
    it "adds pin on behalf of current user" do
      profile_pin = create(:profile_pin, pinnable: article, profile: user)
      put "/profile_pins/#{profile_pin.id}"
      expect(ProfilePin.all.size).to eq(0)
    end
  end
end
