require "rails_helper"

RSpec.describe YoutubeTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id) { "vKeCr-MAyH4" }

    def generate_tag(input)
      Liquid::Template.parse("{% embed #{input} %}").render
    end

    it "accepts a short URL" do
      result = generate_tag("https://youtu.be/#{valid_id}")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}")
    end

    it "accepts a short URL with 'si' parameter" do
      result = generate_tag("https://youtu.be/#{valid_id}?si=FPFWKE9g0PhQjAUE")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}")
    end

    it "accepts a short URL with 't' parameter" do
      result = generate_tag("https://youtu.be/#{valid_id}?t=231")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}?start=231")
    end

    it "accepts a short URL with both 'si' and 't' parameters" do
      result = generate_tag("https://youtu.be/#{valid_id}?si=FPFWKE9g0PhQjAUE&t=231")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}?start=231")
    end

    it "accepts a full URL with 'v' parameter" do
      result = generate_tag("https://www.youtube.com/watch?v=#{valid_id}")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}")
    end

    it "accepts a full URL with 'v' and 't' parameters" do
      result = generate_tag("https://www.youtube.com/watch?v=#{valid_id}&t=231s")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}?start=231")
    end

    it "accepts a full URL with 'si' and 'v' parameters in different order" do
      result = generate_tag("https://www.youtube.com/watch?si=FPFWKE9g0PhQjAUE&v=#{valid_id}")
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}")
    end

    it "accepts an ID only" do
      result = Liquid::Template.parse("{% youtube #{valid_id} %}").render
      expect(result).to include("https://www.youtube.com/embed/#{valid_id}")
    end

    it "raises an error for invalid IDs" do
      expect do
        generate_tag("invalid-id")
      end.to raise_error(StandardError)
    end

    it "raises an error for invalid URLs" do
      stub_request(:any, "https://example.com/not-a-youtube-url").to_return(status: 404)
      expect do
        generate_tag("https://example.com/not-a-youtube-url")
      end.to raise_error(StandardError)
    end
  end
end