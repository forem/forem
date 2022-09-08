require "rails_helper"

RSpec.describe "Api::V1::Reactions", type: :request do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:params) do
    {
      reactable_type: "Article",
      reactable_id: "123",
      category: "like"
    }
  end

  before { allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true) }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when unauthenticated and post to toggle" do
    it "returns unauthorized" do
      post api_reactions_toggle_path, params: params.to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and post to toggle" do
    it "returns unauthorized" do
      post api_reactions_toggle_path, params: params.to_json,
                                      headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorized and post to toggle" do
    include_context "when user is authorized"

    before do
      allow(Rails.cache).to receive(:delete)
      allow(ReactionHandler).to receive(:toggle).and_return(result)
    end

    context "when toggled successfully" do
      let(:result) { ReactionHandler::Result.new reaction: Reaction.new }

      it "responds with success" do
        post api_reactions_toggle_path, params: params.to_json, headers: auth_header
        expect(response).to have_http_status(:success)
      end

      it "responds with expected JSON" do
        post api_reactions_toggle_path, params: params.to_json, headers: auth_header
        expect(JSON.parse(response.body).keys).to contain_exactly("id", "result", "category", "reactable_type",
                                                                  "reactable_id")
      end
    end

    context "when toggled unsuccessfully" do
      let(:result) do
        ReactionHandler::Result.new.tap do |bad_result|
          allow(bad_result).to receive(:success?).and_return(false)
          allow(bad_result).to receive(:errors_as_sentence).and_return("Stuff was bad")
        end
      end

      it "responds with success" do
        post api_reactions_toggle_path, params: params.to_json, headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when unauthenticated and post to create" do
    it "returns unauthorized" do
      post api_reactions_path, params: params.to_json, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and post to create" do
    it "returns unauthorized" do
      post api_reactions_path, params: params.to_json,
                               headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorized and post to create" do
    include_context "when user is authorized"

    before do
      allow(Rails.cache).to receive(:delete)
      allow(ReactionHandler).to receive(:create).and_return(result)
    end

    context "when created successfully" do
      let(:result) { ReactionHandler::Result.new reaction: Reaction.new }

      it "responds with success" do
        post api_reactions_path, params: params.to_json, headers: auth_header
        expect(response).to have_http_status(:success)
      end

      it "responds with expected JSON" do
        post api_reactions_path, params: params.to_json, headers: auth_header
        expect(JSON.parse(response.body).keys).to contain_exactly("id", "result", "category", "reactable_type",
                                                                  "reactable_id")
      end
    end

    context "when created unsuccessfully" do
      let(:result) do
        ReactionHandler::Result.new.tap do |bad_result|
          allow(bad_result).to receive(:success?).and_return(false)
          allow(bad_result).to receive(:errors_as_sentence).and_return("Stuff was bad")
        end
      end

      it "responds with success" do
        post api_reactions_path, params: params.to_json, headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
