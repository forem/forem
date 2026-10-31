require "rails_helper"

RSpec.describe "Api::V1::Images" do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:auth_headers) { v1_headers.merge("api-key" => api_secret.secret) }
  let(:json_auth_headers) { auth_headers.merge("Content-Type" => "application/json") }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:image) do
    Rack::Test::UploadedFile.new(Rails.root.join("spec/support/fixtures/images/image1.jpeg"), "image/jpeg")
  end

  before { allow(Rails).to receive(:cache).and_return(cache) }

  describe "POST /api/images" do
    it "returns 401 without an api key" do
      post api_images_path, params: { image: image }, headers: v1_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for a suspended user" do
      user.add_role(:suspended)
      post api_images_path, params: { image: image }, headers: auth_headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "uploads the image and returns its url" do
      post api_images_path, params: { image: image }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["url"]).to match(%r{\Ahttps?://.+/uploads/articles/.+\.jpeg\z})
    end

    it "returns a url usable as an article's main_image" do
      post api_images_path, params: { image: image }, headers: auth_headers
      url = response.parsed_body["url"]

      article = create(:article, user: user, main_image: url)
      expect(article.reload.main_image).to eq(url)
    end

    it "returns 422 when no image file is given" do
      post api_images_path, params: { image: "not-a-file" }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq(I18n.t("api.v1.images_controller.image_required"))
    end

    it "returns 422 for a disallowed file type" do
      pdf = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/800x600.pdf"), "application/pdf")
      post api_images_path, params: { image: pdf }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not count invalid requests against the limit" do
      allow(Settings::RateLimit).to receive(:api_image_upload).and_return(1)

      post api_images_path, params: {}, headers: auth_headers
      post api_images_path, params: { image: image }, headers: auth_headers

      expect(response).to have_http_status(:created)
    end

    it "returns 429 with Retry-After once the configured limit is reached" do
      allow(Settings::RateLimit).to receive_messages(api_image_upload: 1, api_image_upload_window_seconds: 600)

      post api_images_path, params: { image: image }, headers: auth_headers
      expect(response).to have_http_status(:created)

      post api_images_path, params: { image: image }, headers: auth_headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers["Retry-After"].to_s).to eq("600")
    end

    it "does not share its limit with the editor's image uploads" do
      allow(Settings::RateLimit).to receive(:api_image_upload).and_return(1)
      user.rate_limiter.track_limit_by_action(:image_upload)
      user.rate_limiter.track_limit_by_action(:image_upload)

      post api_images_path, params: { image: image }, headers: auth_headers

      expect(response).to have_http_status(:created)
    end

    it "is disabled when the limit is set to 0" do
      allow(Settings::RateLimit).to receive(:api_image_upload).and_return(0)

      post api_images_path, params: { image: image }, headers: auth_headers

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "POST /api/images/generate" do
    let(:generated_url) { "https://example.com/generated.png" }
    let(:success) { Ai::ArticleImageGenerator::Result.new(url: generated_url) }
    let(:failure) { Ai::ArticleImageGenerator::Result.new(failure_reason: :transient) }

    before do
      stub_const("AI_AVAILABLE", true)
      allow(Ai::ArticleImageGenerator).to receive(:call).and_return(success)
    end

    def generate(params = { prompt: "A robot reading a book" })
      post generate_api_images_path, params: params.to_json, headers: json_auth_headers
    end

    it "returns 401 without an api key" do
      post generate_api_images_path, params: { prompt: "A cat" }.to_json,
                                     headers: v1_headers.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:unauthorized)
    end

    it "generates an image and returns its url" do
      generate

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["url"]).to eq(generated_url)
      expect(Ai::ArticleImageGenerator).to have_received(:call)
        .with(prompt: "A robot reading a book", user: user, aspect_ratio: nil)
    end

    it "passes through a valid aspect_ratio" do
      generate(prompt: "A cat", aspect_ratio: "1:1")

      expect(response).to have_http_status(:created)
      expect(Ai::ArticleImageGenerator).to have_received(:call).with(prompt: "A cat", user: user, aspect_ratio: "1:1")
    end

    it "returns 422 for an invalid aspect_ratio" do
      generate(prompt: "A cat", aspect_ratio: "7:3")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Ai::ArticleImageGenerator).not_to have_received(:call)
    end

    it "returns 422 when the prompt is missing" do
      generate(prompt: "  ")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq(I18n.t("api.v1.images_controller.prompt_required"))
    end

    it "returns 422 when the prompt is too long" do
      generate(prompt: "a" * (Api::V1::ImagesController::MAX_PROMPT_LENGTH + 1))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Ai::ArticleImageGenerator).not_to have_received(:call)
    end

    it "returns 503 when AI is not configured" do
      stub_const("AI_AVAILABLE", false)
      generate

      expect(response).to have_http_status(:service_unavailable)
    end

    it "returns 422 when generation fails" do
      allow(Ai::ArticleImageGenerator).to receive(:call).and_return(failure)
      generate

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.generation_failed"))
    end

    it "returns 422 asking to rephrase when the model refuses the prompt" do
      allow(Ai::ArticleImageGenerator).to receive(:call)
        .and_return(Ai::ArticleImageGenerator::Result.new(failure_reason: :refused))
      generate

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.generation_refused"))
    end

    it "returns 408 when generation times out" do
      allow(Ai::ArticleImageGenerator).to receive(:call).and_raise(Timeout::Error)
      generate

      expect(response).to have_http_status(:request_timeout)
    end

    it "counts failed attempts and returns 429 once the configured limit is reached" do
      allow(Settings::RateLimit).to receive_messages(api_ai_image_generation: 2,
                                                     api_ai_image_generation_window_seconds: 3600)
      allow(Ai::ArticleImageGenerator).to receive(:call).and_return(failure, success, success)

      generate
      expect(response).to have_http_status(:unprocessable_entity)
      generate
      expect(response).to have_http_status(:created)
      generate
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers["Retry-After"].to_s).to eq("3600")
      expect(Ai::ArticleImageGenerator).to have_received(:call).twice
    end

    it "is disabled when the limit is set to 0" do
      allow(Settings::RateLimit).to receive(:api_ai_image_generation).and_return(0)
      generate

      expect(response).to have_http_status(:too_many_requests)
      expect(Ai::ArticleImageGenerator).not_to have_received(:call)
    end
  end
end
