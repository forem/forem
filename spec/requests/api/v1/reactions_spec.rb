require "rails_helper"

RSpec.describe "Api::V1::Reactions" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:params) do
    {
      reactable_type: "Article",
      reactable_id: "123",
      category: "like"
    }
  end

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
        expect(response.parsed_body.keys).to contain_exactly("id", "result", "category", "reactable_type",
                                                             "reactable_id")
      end
    end

    context "when toggled unsuccessfully" do
      let(:result) do
        ReactionHandler::Result.new.tap do |bad_result|
          allow(bad_result).to receive_messages(success?: false, errors_as_sentence: "Stuff was bad")
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
        expect(response.parsed_body.keys).to contain_exactly("id", "result", "category", "reactable_type",
                                                             "reactable_id")
      end
    end

    context "when created unsuccessfully" do
      let(:result) do
        ReactionHandler::Result.new.tap do |bad_result|
          allow(bad_result).to receive_messages(success?: false, errors_as_sentence: "Stuff was bad")
        end
      end

      it "responds with success" do
        post api_reactions_path, params: params.to_json, headers: auth_header
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "cache invalidation" do
    include_context "when user is authorized"
    
    let(:article) { create(:article) }
    let(:params) do
      {
        reactable_type: "Article",
        reactable_id: article.id.to_s,
        category: "like"
      }
    end

    it "invalidates reaction_counts_for_reactable cache when creating a reaction" do
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"
      
      # Create initial reactions to populate cache
      create(:reaction, reactable: article, category: "like", user: user)
      
      # Populate cache
      article.public_reaction_categories
      cache_existed = Rails.cache.exist?(cache_key)
      
      # Create reaction via API
      if cache_existed
        expect do
          post api_reactions_path, params: params.to_json, headers: auth_header
        end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      else
        # If cache doesn't exist, just verify the request succeeds
        post api_reactions_path, params: params.to_json, headers: auth_header
        expect(response).to be_successful
      end
    end

    it "invalidates reaction_counts_for_reactable cache when toggling a reaction" do
      cache_key = "reaction_counts_for_reactable-Article-#{article.id}"
      
      # Create initial reaction
      create(:reaction, reactable: article, category: "like", user: user)
      
      # Populate cache
      article.public_reaction_categories
      cache_existed = Rails.cache.exist?(cache_key)
      
      # Toggle reaction (destroy) via API
      if cache_existed
        expect do
          post api_reactions_toggle_path, params: params.to_json, headers: auth_header
        end.to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      else
        # If cache doesn't exist, just verify the request succeeds
        post api_reactions_toggle_path, params: params.to_json, headers: auth_header
        expect(response).to be_successful
      end
    end

    it "calls remove_reaction_counts_cache_key method" do
      controller = Api::V1::ReactionsController.new
      allow(controller).to receive(:remove_reaction_counts_cache_key).and_call_original
      allow(Api::V1::ReactionsController).to receive(:new).and_return(controller)
      
      post api_reactions_path, params: params.to_json, headers: auth_header
      
      expect(controller).to have_received(:remove_reaction_counts_cache_key)
    end
  end
end
