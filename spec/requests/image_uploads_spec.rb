require "rails_helper"

RSpec.describe "ImageUploads", type: :request do
  describe "POST/image_uploads" do
    let(:user) { create(:user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }
    let(:image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/fixtures/images/image1.jpeg"),
        "image/jpeg",
      )
    end
    let(:bad_image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/fixtures/images/bad-image.jpg"),
        "image/jpeg",
      )
    end
    let(:image_directory_regex) { "\/uploads\/articles\/.+\." }

    context "when not logged-in" do
      it "responds with 401" do
        post "/image_uploads", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when logged-in" do
      before do
        sign_in user
      end

      it "returns json" do
        post "/image_uploads", headers: headers
        expect(response.media_type).to eq("application/json")
      end

      it "provides a link" do
        # this test is a little flimsy
        post "/image_uploads", headers: headers, params: { image: [image] }
        expect(response.parsed_body["links"].length).to eq(1)
        expect(response.body).to match(image_directory_regex)
      end

      it "supports for uploading a single image not in an array" do
        post "/image_uploads", headers: headers, params: { image: image }
        expect(response.parsed_body["links"].length).to eq(1)
        expect(response.body).to match(image_directory_regex)
      end

      it "supports upload of more than one image at a time" do
        image2 = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/fixtures/images/image2.jpeg"), "image/jpeg"
        )
        post "/image_uploads", headers: headers, params: { image: [image, image2] }

        expect(response.body).to match(image_directory_regex)
        expect(response.parsed_body["links"].length).to eq(2)
      end

      it "prevents image with resolutions larger than 4096x4096" do
        post "/image_uploads", headers: headers, params: { image: [bad_image] }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a JSON error if something goes wrong" do
        post "/image_uploads", headers: headers, params: { image: [bad_image] }
        expect(response.parsed_body["error"]).not_to be_nil
      end

      it "returns error if image file name is too long" do
        allow(image).to receive(:original_filename).and_return("#{'a_very_long_filename' * 15}.png")
        post "/image_uploads", headers: headers, params: { image: image }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error if image file is not a file" do
        allow(bad_image).to receive(:respond_to?).with(:original_filename).and_return(false)
        allow(bad_image).to receive(:respond_to?).with(:to_ary, true).and_call_original
        post "/image_uploads", headers: headers, params: { image: bad_image }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when uploading rate limiting works" do
      let(:cache_store) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
      let(:cache) { Rails.cache }
      let(:cache_key) { "#{user.id}_image_upload" }

      before do
        sign_in user
        allow(Rails).to receive(:cache).and_return(cache_store)
      end

      it "counts number of uploads in cache" do
        post "/image_uploads", headers: headers, params: { image: [image] }
        expect(cache.read(cache_key, raw: true).to_i).to eq(1)
      end

      it "responds with HTTP 429 with too many uploads" do
        upload = proc do
          Rack::Test::UploadedFile.new(
            Rails.root.join("spec/support/fixtures/images/image1.jpeg"),
            "image/jpeg",
          )
        end

        11.times { post "/image_uploads", headers: headers, params: { image: [upload.call] } }

        expect(response).to have_http_status(:too_many_requests)

        expected_retry_after = RateLimitChecker::ACTION_LIMITERS.dig(:image_upload, :retry_after)
        expect(response.headers["Retry-After"]).to eq(expected_retry_after)
      end
    end
  end
end
