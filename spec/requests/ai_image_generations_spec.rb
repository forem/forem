require "rails_helper"

RSpec.describe "AiImageGenerations" do
  describe "POST /ai_image_generations" do
    let(:user) { create(:user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }
    let(:valid_params) { { prompt: "A beautiful sunset over mountains" } }
    let(:image_url) { "https://example.com/generated-image.png" }

    context "when not logged-in" do
      it "responds with 401" do
        post "/ai_image_generations", headers: headers, params: valid_params.to_json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in" do
      before do
        sign_in user
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
        # Set settings in database and clear cache
        Settings::UserExperience.cover_image_height = 500
        Settings::UserExperience.cover_image_fit = "crop"
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        # Spy on Ai::ImageGenerator.new
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # Verify the aspect ratio was calculated correctly (1000/500 = 2.0, should map to 16:9)
        expect(Ai::ImageGenerator).to have_received(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        )
      end

      it "calculates aspect ratio from subforem settings (limit mode)" do
        Settings::UserExperience.cover_image_height = 420
        Settings::UserExperience.cover_image_fit = "limit"
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # Limit mode should default to 16:9
        expect(Ai::ImageGenerator).to have_received(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        )
      end

      it "uses 5:4 aspect ratio for taller cover images" do
        # 1000/800 = 1.25, which should map to 5:4 (range 1.2..1.4)
        # But this gets capped at 500, so 1000/500 = 2.0 -> 16:9
        # So let's test with a height that doesn't get capped
        Settings::UserExperience.cover_image_height = 400
        Settings::UserExperience.cover_image_fit = "crop"
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # 1000/400 = 2.5, which maps to 21:9 (else case, > 2.1)
        expect(Ai::ImageGenerator).to have_received(:new).with(
          anything,
          hash_including(aspect_ratio: "21:9")
        )
      end

      it "caps height at 500 for aspect ratio calculation" do
        # Height should be capped at 500, so 1000/500 = 2.0, which should map to 16:9
        Settings::UserExperience.cover_image_height = 1000
        Settings::UserExperience.cover_image_fit = "crop"
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        expect(Ai::ImageGenerator).to have_received(:new).with(
          anything,
          hash_including(aspect_ratio: "16:9")
        )
      end

      it "includes aesthetic instructions when set" do
        aesthetic = "vibrant and modern with bold colors"
        Settings::UserExperience.cover_image_height = 420
        Settings::UserExperience.cover_image_fit = "crop"
        Settings::UserExperience.cover_image_aesthetic_instructions = aesthetic
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # Check that the aesthetic instructions were included in the prompt
        expect(Ai::ImageGenerator).to have_received(:new).with(
          /Style to use if not otherwise contradicted previously: #{aesthetic}/,
          anything
        )
      end

      it "does not modify prompt when aesthetic instructions are blank" do
        Settings::UserExperience.cover_image_height = 420
        Settings::UserExperience.cover_image_fit = "crop"
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # Check that only the safety prompt was added, not any aesthetic instructions
        expect(Ai::ImageGenerator).to have_received(:new).with(
          /^#{Regexp.escape(valid_params[:prompt])}\.\n\nDo not under any circumstances/,
          anything
        )
      end

      it "falls back to default subforem aesthetic when current subforem value is blank" do
        # Create default subforem and set it up BEFORE any requests
        default_subforem = create(:subforem)
        default_aesthetic = "default subforem aesthetic style"
        
        # This will be called by the middleware
        allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)
        
        # Set aesthetic for default subforem
        Settings::UserExperience.set_cover_image_aesthetic_instructions(
          default_aesthetic, 
          subforem_id: default_subforem.id
        )
        
        # Ensure global/current has blank aesthetic
        Settings::UserExperience.cover_image_aesthetic_instructions = ""
        Settings::UserExperience.clear_cache
        
        allow(Ai::ImageGenerator).to receive(:new).and_call_original
        allow_any_instance_of(Ai::ImageGenerator).to receive(:generate).and_return(
          Ai::ImageGenerator::GenerationResult.new(url: image_url, text_response: nil)
        )

        post "/ai_image_generations", headers: headers, params: valid_params.to_json

        expect(response).to have_http_status(:ok)
        # Should fall back to default subforem's aesthetic
        expect(Ai::ImageGenerator).to have_received(:new).with(
          /Style to use if not otherwise contradicted previously: #{Regexp.escape(default_aesthetic)}/,
          anything
        )
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
      let(:cache_key) { "#{user.id}_ai_image_generation" }

      before do
        sign_in user
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

