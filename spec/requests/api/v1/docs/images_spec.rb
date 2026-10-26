require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "api/v1/images" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  let(:upload_limit) { 10 }
  let(:generation_limit) { 3 }
  let(:ai_available) { true }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Settings::RateLimit).to receive_messages(api_image_upload: upload_limit, api_ai_image_generation: generation_limit)
    stub_const("AI_AVAILABLE", ai_available)
    allow(Ai::ArticleImageGenerator).to receive(:call)
      .and_return("https://dev-to-uploads.s3.amazonaws.com/uploads/articles/generated.png")
  end

  path "/api/images" do
    describe "upload an image" do
      post("upload an image") do
        tags "images"
        description(<<~DESCRIBE.strip)
          Upload an image and get back a URL hosted by this Forem.

          ### Using the URL:
          - Embed it in an article's `body_markdown`, e.g. `![A description](URL)`.
          - Set it as an article's cover image by passing it as `main_image` when creating or updating an article.

          ### Limits:
          - One image per request, sent as `multipart/form-data` in the `image` field.
          - Allowed types: jpg, jpeg, jpe, gif, png, ico, bmp, dng, webp. Max 25MB.
          - Rate limited per user to a configurable number of uploads per configurable window (by default 10 per hour). Exceeding it returns `429` with a `Retry-After` header. Forem admins can change both values, or set the limit to 0 to disable this endpoint.
        DESCRIBE
        operationId "uploadImage"
        produces "application/json"
        consumes "multipart/form-data"

        parameter name: :image, in: :formData, required: true,
                  schema: {
                    type: :object,
                    properties: {
                      image: { type: :string, format: :binary, description: "The image file to upload." }
                    },
                    required: %w[image]
                  }

        let(:image) do
          Rack::Test::UploadedFile.new(Rails.root.join("spec/support/fixtures/images/image1.jpeg"), "image/jpeg")
        end

        response(201, "created") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/ImageUrl"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:image) { "not-a-file" }
          add_examples

          run_test!
        end

        response "429", "too many requests" do
          let(:"api-key") { api_secret.secret }
          let(:upload_limit) { 0 }

          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/images/generate" do
    describe "generate an image with AI" do
      post("generate an image with AI") do
        tags "images"
        description(<<~DESCRIBE.strip)
          Generate an image from a text prompt and get back a URL hosted by this Forem.

          The image follows this Forem's cover image style and, unless `aspect_ratio` is given, is sized for its cover images. Use the URL in `body_markdown` or as an article's `main_image`, just like an uploaded image.

          ### Limits:
          - `prompt` is required and may be up to 1000 characters.
          - Rate limited per user to a configurable number of generations per configurable window (by default 3 per day). Every attempt counts, including failed ones. Exceeding it returns `429` with a `Retry-After` header. Forem admins can change both values, or set the limit to 0 to disable this endpoint.
          - Returns `503` if AI image generation is not configured on this Forem.
        DESCRIBE
        operationId "generateImage"
        produces "application/json"
        consumes "application/json"

        parameter name: :image_generation, in: :body,
                  schema: {
                    type: :object,
                    properties: {
                      prompt: { type: :string, maxLength: Api::V1::ImagesController::MAX_PROMPT_LENGTH,
                                description: "A description of the image to generate." },
                      aspect_ratio: { type: :string, enum: Ai::ImageGenerator::VALID_ASPECT_RATIOS.keys,
                                      description: "Aspect ratio of the image. Defaults to this Forem's cover image shape." }
                    },
                    required: %w[prompt]
                  }

        let(:image_generation) { { prompt: "A robot reading a book in a cozy library", aspect_ratio: "16:9" } }

        response(201, "created") do
          let(:"api-key") { api_secret.secret }
          schema "$ref": "#/components/schemas/ImageUrl"
          add_examples

          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples

          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:image_generation) { { prompt: "" } }
          add_examples

          run_test!
        end

        response "429", "too many requests" do
          let(:"api-key") { api_secret.secret }
          let(:generation_limit) { 0 }

          add_examples

          run_test!
        end

        response "503", "AI image generation unavailable" do
          let(:"api-key") { api_secret.secret }
          let(:ai_available) { false }

          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
# rubocop:enable Layout/LineLength
