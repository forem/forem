require "rails_helper"

RSpec.describe "UserBlock", type: :request do
  let(:blocker) { create(:user) }
  let(:blocked) { create(:user) }

  before { sign_in blocker }

  describe "GET /user_blocks/:blocked_id or #show" do
    it "rejects when not-logged-in" do
      sign_out(blocker)
      get "/user_blocks/#{blocked.id}"
      expect(response.media_type).to eq "application/json"
      expect(response).to have_http_status :unauthorized
      expect(response.parsed_body["result"]).to eq "not-logged-in"
    end

    it "returns 'not-blocking' when the user is not blocked" do
      get "/user_blocks/#{blocked.id}"
      expect(response.media_type).to eq "application/json"
      expect(response.parsed_body["result"]).to eq "not-blocking"
    end

    it "returns 'blocking' when blocking" do
      create(:user_block, blocker: blocker, blocked: blocked)
      get "/user_blocks/#{blocked.id}"
      expect(response.media_type).to eq "application/json"
      expect(response.parsed_body["result"]).to eq "blocking"
    end
  end

  describe "POST /user_blocks or #create" do
    it "renders 'not-logged-in' when not logged in" do
      sign_out blocker
      post "/user_blocks", params: { user_block: { blocked_id: blocked.id } }
      expect(response.media_type).to eq "application/json"
      expect(response).to have_http_status :unauthorized
      expect(response.parsed_body["result"]).to eq "not-logged-in"
    end

    it "creates the correct user_block" do
      post "/user_blocks", params: { user_block: { blocked_id: blocked.id } }
      expect(UserBlock.count).to eq 1
      expect(UserBlock.first.blocker_id).to eq blocker.id
      expect(UserBlock.first.blocked_id).to eq blocked.id
    end

    it "returns a JSON response with blocked" do
      post "/user_blocks", params: { user_block: { blocked_id: blocked.id } }
      expect(response.media_type).to eq "application/json"
      expect(response.parsed_body["result"]).to eq "blocked"
    end
  end

  describe "DELETE /user_blocks/:blocked_id or #delete" do
    before do
      create(:user_block, blocker: blocker, blocked: blocked)
      blocker.update(blocking_others_count: 1)
    end

    it "renders 'not-logged-in' when not logged in" do
      sign_out blocker
      delete "/user_blocks/#{blocked.id}", params: { user_block: { blocked_id: blocked.id } }
      expect(response.media_type).to eq "application/json"
      expect(response).to have_http_status :unauthorized
      expect(response.parsed_body["result"]).to eq "not-logged-in"
    end

    it "renders 'not-blocking-anyone' if there is no one to unblock" do
      UserBlock.delete_all
      blocker.update(blocking_others_count: 0)
      delete "/user_blocks/#{blocked.id}", params: { user_block: { blocked_id: blocked.id } }
      expect(response.media_type).to eq "application/json"
      expect(response.parsed_body["result"]).to eq "not-blocking-anyone"
    end

    it "raises ActiveRecord::RecordNotFound error if UserBlock not found" do
      missing_id = blocked.id
      blocked.destroy
      expect do
        delete "/user_blocks/#{missing_id}", params: { user_block: { blocked_id: missing_id } }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "removes the correct user_block" do
      delete "/user_blocks/#{blocked.id}", params: { user_block: { blocked_id: blocked.id } }
      expect(blocker.blocking?(blocked)).to be false
    end
  end
end
