require "rails_helper"

RSpec.describe "TwilioTokens", type: :request do
  let(:user) { create(:user) }
  let(:chat_channel) { create(:chat_channel) }

  before do
    sign_in user
  end

  describe "GET /twilio_tokens/:id" do
    it "returns a token for member of a channel" do
      chat_channel.add_users [user]
      get "/twilio_tokens/private-video-channel-#{chat_channel.id}"
      expect(response.status).to eq(200)
    end

    it "returns not found if unknown ID" do
      chat_channel.add_users [user]
      get "/twilio_tokens/sddds3423443efrwdfsd"
      expect(response.status).to eq(404)
    end

    it "returns not found if wrong ID prefix" do
      chat_channel.add_users [user]
      get "/twilio_tokens/sddds3423443efrwdfsd-#{chat_channel.id}"
      expect(response.status).to eq(404)
    end

    # it "returns unauthorized if user not member of channel" do
    #   expect { get "/twilio_tokens/private-video-channel-#{chat_channel.id}" }.
    #     to raise_error(Pundit::NotAuthorizedError)
    # end
  end
end
