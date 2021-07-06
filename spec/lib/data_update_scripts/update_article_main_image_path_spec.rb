require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20201015190914_update_article_main_image_path.rb")

describe DataUpdateScripts::UpdateArticleMainImagePath do
  it "update main_image to a raw path" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("FOREM_CONTEXT").and_return("forem_cloud")

    bad_path = "https://res.cloudinary.com/practicaldev/image/fetch/s--d-pOh1Z_--/c_imagga_scale,f_auto," \
               "fl_progressive,h_420,q_auto,w_1000/#{URL.url}/images/i/some-image.jpeg"
    article = create(:article, main_image: bad_path)

    described_class.new.run

    expect(article.reload.main_image).to eq(URL.url("/remoteimages/i/some-image.jpeg"))
  end
end
