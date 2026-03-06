require "rails_helper"

RSpec.describe "Slides and Slide liquid tags", type: :liquid_tag do
  before do
    Liquid::Template.register_tag("slides", SlidesTag)
    Liquid::Template.register_tag("slide", SlideTag)
  end

  def parse(template)
    Liquid::Template.parse(template)
  end

  describe "basic rendering" do
    it "renders a carousel with slides" do
      result = parse('{% slides %}{% slide image="https://example.com/1.jpg" %}{% slide image="https://example.com/2.jpg" %}{% endslides %}').render
      expect(result).to include('class="ltag-slides"')
      expect(result).to include("ltag-slides__track")
      expect(result.scan("ltag-slide").count { |m| m == "ltag-slide" }).to be >= 2
    end

    it "renders a single slide" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" %}{% endslides %}').render
      expect(result).to include("ltag-slide__image")
      expect(result).to include("https://example.com/photo.jpg")
    end

    it "renders alt text" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" alt="A sunset" %}{% endslides %}').render
      expect(result).to include('alt="A sunset"')
    end

    it "defaults alt to empty string" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" %}{% endslides %}').render
      expect(result).to include('alt=""')
    end
  end

  describe "video slides" do
    it "renders a video slide with play button" do
      result = parse('{% slides %}{% slide image="https://example.com/thumb.jpg" video="https://youtube.com/watch?v=abc" %}{% endslides %}').render
      expect(result).to include("ltag-slide--video")
      expect(result).to include("ltag-slide__play")
      expect(result).to include('href="https://youtube.com/watch?v=abc"')
    end

    it "does not render play button for image-only slides" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" %}{% endslides %}').render
      expect(result).not_to include("ltag-slide__play")
      expect(result).not_to include("ltag-slide--video")
    end
  end

  describe "validation" do
    it "raises error when image is missing" do
      expect do
        parse('{% slides %}{% slide alt="No image" %}{% endslides %}')
      end.to raise_error(StandardError, /requires an image/)
    end
  end
end
