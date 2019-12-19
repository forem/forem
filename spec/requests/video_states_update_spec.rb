# http://localhost:3000/api/comments?a_id=23
require "rails_helper"

RSpec.describe "VideoStatesUpdate", type: :request do
  let(:authorized_user) { create(:user, :super_admin, secret: "TEST_SECRET") }
  let(:regular_user) { create(:user, secret: "TEST_SECRET") }
  let(:article) { create(:article, video_code: "DUMMY_VID_CODE") }

  describe "POST /video_states" do
    it "updates video state" do
      input = JSON.unparse(input: { key: article.video_code })
      post "/video_states?key=#{authorized_user.secret}",
           params: { Message: input }.to_json
      expect(Article.last.video_state).to eq("COMPLETED")
    end

    it "rejects non-authorized users" do
      post "/video_states?key=#{regular_user.secret}",
           params: { input: { key: article.video_code } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns not_found if video article is not found" do
      input = JSON.unparse(input: { key: "abc" })
      post "/video_states?key=#{authorized_user.secret}",
           params: { Message: input }.to_json
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["message"]).to eq("Related article not found")
    end
  end
end
