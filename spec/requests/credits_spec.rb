require "rails_helper"

RSpec.describe "Credits", type: :request do
  describe "POST credits" do
    let(:user) {create(:user)}
    let(:stripe_helper) { StripeMock.create_test_helper }
    before do
      StripeMock.start
      sign_in user
    end
    
    it "creates unspent credits" do
      post "/credits", params: {
        credit: {
          number_to_purchase: 20
        },
        stripe_token: stripe_helper.generate_card_token
      }
      expect(user.credits.size).to eq(20)
    end
  end
end