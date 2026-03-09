require "rails_helper"

RSpec.describe "CSRF token handling", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
    # Stub CSRF token verification to always raise, simulating an invalid CSRF token
    # so we can trigger the rescue_from handler directly via ActionController.
    # We use `allow_any_instance_of` to raise the exception inside the request.
    allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
      .and_raise(ActionController::InvalidAuthenticityToken)
  end

  describe "HTML request with invalid CSRF token" do
    it "returns 422 status" do
      post comments_path, params: {
        comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a non-empty body" do
      post comments_path, params: {
        comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
      }
      expect(response.body).not_to be_empty
    end

    it "does not return a 200 OK status" do
      post comments_path, params: {
        comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
      }
      expect(response).not_to have_http_status(:ok)
    end

    it "increments the ForemStatsClient counter" do
      allow(ForemStatsClient).to receive(:increment)
      post comments_path, params: {
        comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
      }
      expect(ForemStatsClient).to have_received(:increment).with(
        "users.invalid_authenticity_token",
        hash_including(tags: array_including(a_string_matching(/controller_name:/), a_string_matching(/path:/))),
      )
    end
  end

  describe "JSON request with invalid CSRF token" do
    it "returns 422 status" do
      post comments_path,
           params: {
             comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
           },
           headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a JSON error body" do
      post comments_path,
           params: {
             comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
           },
           headers: { "Accept" => "application/json" }
      json = response.parsed_body
      expect(json["error"]).to be_present
    end

    it "does not return a 200 OK status" do
      post comments_path,
           params: {
             comment: { body_markdown: "Test comment", commentable_id: article.id, commentable_type: "Article" }
           },
           headers: { "Accept" => "application/json" }
      expect(response).not_to have_http_status(:ok)
    end
  end
end
