require "rails_helper"

RSpec.describe "ImageUploads", type: :request do
  describe "POST/image_uploads" do
    let(:user) { create(:user) }
    let(:headers) { { "Content-Type": "application/json", Accept: "application/json" } }

    context "when not logged-in" do
      it "redirects to /enter" do
        post "/image_uploads", headers: headers
        expect(response).to redirect_to("/enter")
      end
    end

    context "when logged-in" do
      it "returns json" do
        sign_in user
        post "/image_uploads", headers: headers
        expect(response.content_type).to eq("application/json")
      end

      it "provides a link" do
        # this test is a little flimsy
        sign_in user
        image = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "fixtures", "images", "image1.jpeg"), "image/jpeg")
        post "/image_uploads", headers: headers, params: { image: image }
        expect(response.body).to match("\/i\/.+\.")
      end

      it "prevents image with resolutions larger than 4096x4096" do
        sign_in user
        image = Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "fixtures", "images", "bad-image.jpg"), "image/jpeg")
        expect { post("/image_uploads", headers: headers, params: { image: image }) }.
          to raise_error(CarrierWave::IntegrityError)
      end
    end
  end
end
