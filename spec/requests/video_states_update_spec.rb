require "rails_helper"

RSpec.describe "VideoStatesUpdate", type: :request do
  let(:encoder_key) { "TEST_SECRET" }
  let(:article) { create(:article, video_code: "DUMMY_VID_CODE") }

  before do
    allow(Settings::General).to receive(:video_encoder_key).and_return(encoder_key)
  end

  describe "POST /video_states" do
    it "updates video state" do
      input = JSON.unparse(input: { key: article.video_code })
      post "/video_states?key=#{encoder_key}",
           params: { Message: input }.to_json
      expect(Article.last.video_state).to eq("COMPLETED")
    end

    it "rejects invalid key" do
      post "/video_states?key=not_a_valid_key",
           params: { input: { key: article.video_code } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns not_found if video article is not found" do
      input = JSON.unparse(input: { key: "abc" })
      post "/video_states?key=#{encoder_key}",
           params: { Message: input }.to_json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["message"]).to eq("Related article not found")
    end
  end
end
