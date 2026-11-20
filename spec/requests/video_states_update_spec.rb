require "rails_helper"

RSpec.describe "VideoStatesUpdate" do
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

    it "rejects requests when video_encoder_key is unconfigured (nil) and key param is omitted" do
      allow(Settings::General).to receive(:video_encoder_key).and_return(nil)
      input = JSON.unparse(input: { key: article.video_code })

      post "/video_states", params: { Message: input }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(article.reload.video_state).not_to eq("COMPLETED")
    end

    it "rejects requests when video_encoder_key is blank and key param is empty" do
      allow(Settings::General).to receive(:video_encoder_key).and_return("")
      input = JSON.unparse(input: { key: article.video_code })

      post "/video_states?key=", params: { Message: input }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(article.reload.video_state).not_to eq("COMPLETED")
    end

    it "does not match articles with nil video_code when SNS input key is blank" do
      non_video_article = create(:article, video_code: nil)
      input = JSON.unparse(input: { key: nil })

      post "/video_states?key=#{encoder_key}", params: { Message: input }.to_json

      expect(response).to have_http_status(:not_found)
      expect(non_video_article.reload.video_state).not_to eq("COMPLETED")
    end

    it "does not match articles or send email when SNS input key is a non-string value" do
      non_video_article = create(:article, video_code: nil)
      input = JSON.unparse(input: { key: [nil] })

      expect do
        post "/video_states?key=#{encoder_key}", params: { Message: input }.to_json
      end.not_to change { ActionMailer::Base.deliveries.count }

      expect(response).to have_http_status(:not_found)
      expect(non_video_article.reload.video_state).not_to eq("COMPLETED")
    end

    it "returns not_found when SNS message shape is malformed" do
      non_video_article = create(:article, video_code: nil)
      input = JSON.unparse(["unexpected"])

      expect do
        post "/video_states?key=#{encoder_key}", params: { Message: input }.to_json
      end.not_to change { ActionMailer::Base.deliveries.count }

      expect(response).to have_http_status(:not_found)
      expect(non_video_article.reload.video_state).not_to eq("COMPLETED")
    end
  end
end
