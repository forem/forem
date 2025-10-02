require "rails_helper"

RSpec.describe CloudCoverUrl, cloudinary: true, type: :view_object do
  let(:article) { create(:article, main_image: "https://robohash.org/articlefactory.png") }
  let(:cloudinary_prefix) { "https://res.cloudinary.com/#{Cloudinary.config.cloud_name}/image/fetch/" }

  it "returns proper url" do
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and include("/c_fill,f_auto,fl_progressive,h_420,q_auto,w_1000/https://robohash.org/")
  end

  it "returns proper url when nested cloudinary" do
    image_url = "https://res.cloudinary.com/practicaldev/image/fetch/s--A-gun7rr--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://res.cloudinary.com/practicaldev/image/fetch/s--hcD8ZkbP--/c_imagga_scale%2Cf_auto%2Cfl_progressive%2Ch_420%2Cq_auto%2Cw_1000/https://dev-to-uploads.s3.amazonaws.com/i/th93d625o27nuz63oeen.png" # rubocop:disable Layout/LineLength
    cloudinary_string = "/c_fill,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/i/th93d625o27nuz63oeen.png" # rubocop:disable Layout/LineLength

    article.update_column(:main_image, image_url)
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and end_with(cloudinary_string)
  end

  it "returns proper url when single cloudinary" do
    image_url = "https://res.cloudinary.com/practicaldev/image/fetch/s--hcD8ZkbP--/c_imagga_scale%2Cf_auto%2Cfl_progressive%2Ch_420%2Cq_auto%2Cw_1000/https://dev-to-uploads.s3.amazonaws.com/i/th93d625o27nuz63oeen.png" # rubocop:disable Layout/LineLength
    cloudinary_string = "/c_fill,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/i/th93d625o27nuz63oeen.png" # rubocop:disable Layout/LineLength

    article.update_column(:main_image, image_url)
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and end_with(cloudinary_string)
  end

  it "returns proper url when config set to limit" do
    allow(Settings::UserExperience).to receive(:cover_image_fit).and_return("limit")
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and include("/c_limit,f_auto,fl_progressive,h_420,q_auto,w_1000/https://robohash.org/")
  end

  it "returns proper url when a subforem_id is set" do
    subforem_id = create(:subforem, domain: "#{rand(10_000)}.com").id
    allow(Settings::UserExperience).to receive(:cover_image_height).with(subforem_id: subforem_id).and_return("450")
    allow(Settings::UserExperience).to receive(:cover_image_fit).with(subforem_id: subforem_id).and_return("limit")
    expect(described_class.new(article.main_image, subforem_id).call)
      .to start_with(cloudinary_prefix)
      .and include("/c_limit,f_auto,fl_progressive,h_450,q_auto,w_1000/https://robohash.org/")
  end

  it "returns proper url when height is set" do
    allow(Settings::UserExperience).to receive(:cover_image_height).and_return("902")
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and include("/c_fill,f_auto,fl_progressive,h_902,q_auto,w_1000/https://robohash.org/")
  end

  it "returns proper url when ytimg.com is used" do
    article.update_column(:main_image, "https://i.ytimg.com/vi/some_video_id/maxresdefault.jpg")
    expect(described_class.new(article.main_image).call)
      .to start_with(cloudinary_prefix)
      .and include("/c_fill,f_auto,fl_progressive,h_500,q_auto,w_1000/https://i.ytimg.com/vi/some_video_id/maxresdefault.jpg")
  end
end
