# http://localhost:3000/api/comments?a_id=23
require "rails_helper"

RSpec.describe "VideoStatesUpdate", type: :request do
  before do
    @user = FactoryBot.create(:user)
    @user.update(secret:"TEST_SECRET")
    @user.add_role(:super_admin)
    @article = FactoryBot.create(:article, video_code: "DUMMY_VID_CODE")
  end
  describe "POST /video_states" do
    it "updates video state" do
      post "/video_states?key=#{@user.secret}", params: {input: {key: Article.last.video_code}}
      expect(Article.last.video_state).to eq("COMPLETED")
    end
    it "rejects non-authorized users" do
      @user.remove_role(:super_admin)
      post "/video_states?key=#{@user.secret}", params: {input: {key: Article.last.video_code}}
      expect(response).to have_http_status(422)
    end
  end
end
