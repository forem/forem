require "rails_helper"

RSpec.describe "AiImageGenerations" do
  describe "POST /ai_image_generations" do
    let(:admin_user) { create(:user, :admin) }
    let(:regular_user) { create(:user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }
    let(:valid_params) { { prompt: "A beautiful sunset over mountains" } }
    let(:image_url) { "https://example.com/generated-image.png" }

    context "when not logged-in" do
      it "responds with 401" do
        post "/ai_image_generations", headers: headers, params: valid_params.to_json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in as non-admin" do
      before do
        sign_in regular_user
      end

      it "does not allow non-admin users to generate images" do
        expect do
          post "/ai_image_generations", headers: headers, params: valid_params.to_json
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when logged-in as admin" do
      before do
        sign_in admin_user
      end

      it "returns json" do
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )
        
        post "/ai_image_generations", headers: headers, params: valid_params.to_json
        expect(response.media_type).to eq("application/json")
      end

      it "generates an image successfully with valid prompt" do
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["url"]).to eq(image_url)
      end

      it "accepts optional aspect_ratio parameter" do
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        params_with_ratio = valid_params.merge(aspect_ratio: "1:1")
        post "/ai_image_generations", headers: headers, params: params_with_ratio.to_json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["url"]).to eq(image_url)
      end

      it "returns error when prompt is blank" do
        post "/ai_image_generations", headers: headers, params: { prompt: "" }.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.prompt_required"))
      end

      it "returns error when prompt is missing" do
        post "/ai_image_generations", headers: headers, params: {}.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.prompt_required"))
      end

      it "returns error when image generation fails" do
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(nil)

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.generation_failed"))
      end

      it "handles timeout errors gracefully" do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:request_timeout)
        expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.timeout"))
      end

      it "handles unexpected errors gracefully" do
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_raise(StandardError, "Unexpected error")

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:internal_server_error)
        expect(response.parsed_body["error"]).to eq(I18n.t("ai_image_generations_controller.unexpected_error"))
      end
    end

    context "when rate limiting works" do
      let(:cache_store) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
      let(:cache) { Rails.cache }
      let(:cache_key) { "#{admin_user.id}_ai_image_generation" }

      before do
        sign_in admin_user
        allow(Rails).to receive(:cache).and_return(cache_store)
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )
      end

      it "counts number of generations in cache" do
        post "/ai_image_generations", headers: headers, params: valid_params.to_json
        expect(cache.read(cache_key, raw: true).to_i).to eq(1)
      end

      it "responds with HTTP 429 with too many generations" do
        # Default rate limit for AI image generation is 5
        # Make 10 requests to ensure we hit the limit
        10.times { post "/ai_image_generations", headers: headers, params: valid_params.to_json }

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "when user is spam" do
      let(:spam_user) { create(:user, :spam) }

      before do
        sign_in spam_user
      end

      it "does not allow spam users to generate images" do
        expect do
          post "/ai_image_generations", headers: headers, params: valid_params.to_json
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

  end
end

