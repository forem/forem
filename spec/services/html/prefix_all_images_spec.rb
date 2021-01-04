require "rails_helper"

RSpec.describe Html::PrefixAllImages, type: :service do
  describe "#call" do
    context "when the html argument is nil" do
      it "doesn't raise an error" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end

    context "when using gifs from Giphy as images" do
      it "does not wrap giphy images with Cloudinary" do
        html = "<img src='https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif'>"
        parsed_html = Nokogiri::HTML(described_class.call(html))
        img_src = parsed_html.search("img")[0]["src"]
        expect(img_src).not_to include("https://res.cloudinary.com")
      end

      it "uses the raw gif from i.giphy.com" do
        html = "<img src='https://media.giphy.com/media/3ow0TN2M8TH2aAn67F/giphy.gif'>"
        parsed_html = Nokogiri::HTML(described_class.call(html))
        img_src = parsed_html.search("img")[0]["src"]
        expect(img_src).to start_with("https://i.giphy.com")
      end
    end

    context "when an image is used" do
      it "wraps the image with Cloudinary" do
        html = "<img src='https://image.com/image.jpg'>"
        expect(described_class.call(html)).to include("https://res.cloudinary.com")
      end
    end
  end
end
