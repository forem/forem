require "rails_helper"

RSpec.describe Images::Optimizer, type: :service do
  include CloudinaryHelper

  let(:image_url) { "https://i.imgur.com/fKYKgo4.png" }

  it "performs exactly like cl_image_path" do
    cloudinary_url = cl_image_path(image_url,
                                   type: "fetch",
                                   width: 50, height: 50,
                                   crop: "imagga_scale",
                                   quality: "auto",
                                   flags: "progressive",
                                   fetch_format: "auto",
                                   sign_url: true)
    expect(described_class.call(image_url, width: 50, height: 50, crop: "imagga_scale")).to eq(cloudinary_url)
  end

  it "generates correct url by relying on DEFAULT_CL_OPTIONS" do
    cloudinary_url = cl_image_path(image_url,
                                   type: "fetch",
                                   quality: "auto",
                                   sign_url: true,
                                   flags: "progressive",
                                   fetch_format: "jpg")
    expect(described_class.call(image_url, crop: nil, fetch_format: "jpg")).to eq(cloudinary_url)
  end
end
