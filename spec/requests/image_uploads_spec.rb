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
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
    let(:cache) { Rails.cache }
    let(:bad_image) do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/support/fixtures/images/bad-image.jpg"),
        "image/jpeg",
      )
    end

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
        expect(response.content_type).to eq("application/json")
      end

      it "provides a link" do
        # this test is a little flimsy
        post "/image_uploads", headers: headers, params: { image: [image] }
        expect(JSON.parse(response.body)["links"].length).to eq(1)
        expect(response.body).to match("\/i\/.+\.")
      end

      it "supports for uploading a single image not in an array" do
        post "/image_uploads", headers: headers, params: { image: image }
        expect(JSON.parse(response.body)["links"].length).to eq(1)
        expect(response.body).to match("\/i\/.+\.")
      end

      it "supports upload of more than one image at a time" do
        image2 = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/support/fixtures/images/image2.jpeg"), "image/jpeg"
        )
        post "/image_uploads", headers: headers, params: { image: [image, image2] }

        expect(response.body).to match("\/i\/.+\.")
        expect(JSON.parse(response.body)["links"].length).to eq(2)
      end

      it "prevents image with resolutions larger than 4096x4096" do
        post "/image_uploads", headers: headers, params: { image: [bad_image] }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns a JSON error if something goes wrong" do
        post "/image_uploads", headers: headers, params: { image: [bad_image] }
        result = JSON.parse(response.body)
        expect(result["error"]).not_to be_nil
      end
    end

    context "when uploading rate limiting works" do
      before do
        sign_in user
        allow(Rails).to receive(:cache).and_return(memory_store)
        Rails.cache.clear
      end

      it "counts number of uploads in cache" do
        post "/image_uploads", headers: headers, params: { image: [image] }
        expect(cache.read("#{user.id}_image_upload")).to eq(1)
      end

      it "raises error with too many uploads" do
        upload = proc do
          Rack::Test::UploadedFile.new(
            Rails.root.join("spec/support/fixtures/images/images1.jpeg"), "image/jpeg"
          )
        end
        expect do
          11.times { post "/image_uploads", headers: headers, params: { image: [upload.call] } }
        end.to raise_error(RuntimeError)
      end
    end
  end
end
