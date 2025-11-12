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

      it "calculates aspect ratio from subforem settings (crop mode)" do
        allow(Settings::UserExperience).to receive(:cover_image_height).and_return(420)
        allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("crop")
        
        expect(Ai::ImageGenerator).to receive(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
      end

      it "calculates aspect ratio from subforem settings (limit mode)" do
        allow(Settings::UserExperience).to receive(:cover_image_height).and_return(420)
        allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("limit")
        
        expect(Ai::ImageGenerator).to receive(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
      end

      it "uses 4:3 aspect ratio for square-ish cover images" do
        allow(Settings::UserExperience).to receive(:cover_image_height).and_return(750)
        allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("crop")
        
        # 1000/750 = 1.33, which should map to 4:3
        expect(Ai::ImageGenerator).to receive(:new).with(
          anything,
          hash_including(aspect_ratio: "4:3")
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
      end

      it "caps height at 500 for aspect ratio calculation" do
        allow(Settings::UserExperience).to receive(:cover_image_height).and_return(1000)
        allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("crop")
        
        # Height should be capped at 500, so 1000/500 = 2.0, which should map to 16:9
        expect(Ai::ImageGenerator).to receive(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
      end

      it "includes aesthetic instructions when set" do
        aesthetic = "vibrant and modern with bold colors"
        allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).and_return(aesthetic)
        
        expect(Ai::ImageGenerator).to receive(:new).with(
          "#{valid_params[:prompt]}. Style: #{aesthetic}",
          anything
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
      end

      it "does not modify prompt when aesthetic instructions are blank" do
        allow(Settings::UserExperience).to receive(:cover_image_aesthetic_instructions).and_return("")
        
        expect(Ai::ImageGenerator).to receive(:new).with(
          valid_params[:prompt],
          anything
        ).and_call_original
        
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
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

