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
    it "renders a gallery with slides" do
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

  describe "carousel mode" do
    subject(:result) do
      parse('{% slides mode="carousel" %}{% slide image="https://example.com/1.jpg" %}{% slide image="https://example.com/2.jpg" %}{% endslides %}').render
    end

    it "renders an accessible native scroll region" do
      fragment = Nokogiri::HTML.fragment(result)
      track = fragment.at_css(".ltag-slides__track")

      expect(track["role"]).to eq("region")
      expect(track["aria-label"]).to eq("Media gallery")
      expect(track["tabindex"]).to eq("0")
    end

    it "renders stable previous and next controls" do
      fragment = Nokogiri::HTML.fragment(result)
      previous_button = fragment.at_css(".ltag-slides__nav--prev")
      next_button = fragment.at_css(".ltag-slides__nav--next")

      expect(previous_button.name).to eq("button")
      expect(previous_button["aria-disabled"]).to eq("true")
      expect(next_button.name).to eq("button")
      expect(next_button["aria-disabled"]).to eq("true")
    end

    it "renders a progress rail without index dots or inline scripting" do
      expect(result).to include("ltag-slides__progress-thumb")
      expect(result).not_to include("ltag-slides__dots")
      expect(result).not_to include("<script")
    end
  end

  describe "video slides" do
    it "renders a video slide with play button" do
      result = parse('{% slides %}{% slide image="https://example.com/thumb.jpg" video="https://vimeo.com/12345" %}{% endslides %}').render
      expect(result).to include("ltag-slide__play")
      expect(result).to include('href="https://vimeo.com/12345"')
    end

    it "does not render play button for image-only slides" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" %}{% endslides %}').render
      expect(result).not_to include("ltag-slide__play")
    end

    it "renders title below image" do
      result = parse('{% slides %}{% slide image="https://example.com/photo.jpg" title="My Article" %}{% endslides %}').render
      expect(result).to include("ltag-slide__title")
      expect(result).to include("My Article")
    end
  end

  describe "validation" do
    it "raises error when image, video, and link are all missing" do
      expect do
        parse('{% slides %}{% slide alt="No image" %}{% endslides %}')
      end.to raise_error(StandardError, /requires at least one of/)
    end
  end

  describe "content filtering" do
    it "ignores whitespace and stray text between slides" do
      result = parse("{% slides %}\n  # Note: Slides are NOT blocks. \n  {% slide image=\"https://example.com/1.jpg\" %} \n{% endslides %}").render
      expect(result).to include("https://example.com/1.jpg")
      expect(result).not_to include("# Note: Slides are NOT blocks")
    end
  end
end
