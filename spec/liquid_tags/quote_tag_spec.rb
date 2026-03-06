require "rails_helper"

RSpec.describe "Quote liquid tag", type: :liquid_tag do
  before do
    Liquid::Template.register_tag("quote", QuoteTag)
  end

  def parse(template)
    Liquid::Template.parse(template)
  end

  describe "basic rendering" do
    it "renders a quote with author" do
      result = parse('{% quote author="Jane Doe" %}Great platform!{% endquote %}').render
      expect(result).to include('class="ltag-quote"')
      expect(result).to include("ltag-quote__body")
      expect(result).to include("Great platform!")
      expect(result).to include("Jane Doe")
    end

    it "renders author with role" do
      result = parse('{% quote author="Jane Doe" role="CTO at Acme" %}Quote text{% endquote %}').render
      expect(result).to include("ltag-quote__role")
      expect(result).to include("CTO at Acme")
    end

    it "renders author with avatar image" do
      result = parse('{% quote author="Jane" image="https://example.com/avatar.png" %}Text{% endquote %}').render
      expect(result).to include("ltag-quote__avatar")
      expect(result).to include("https://example.com/avatar.png")
    end

    it "renders author with link" do
      result = parse('{% quote author="Jane" link="https://example.com" %}Text{% endquote %}').render
      expect(result).to include('<a href="https://example.com">Jane</a>')
    end

    it "renders without optional fields" do
      result = parse('{% quote author="Jane" %}Simple quote{% endquote %}').render
      expect(result).not_to include("ltag-quote__role")
      expect(result).not_to include("ltag-quote__avatar")
      expect(result).not_to include("ltag-quote__rating")
      expect(result).not_to include("ltag-quote__source")
    end
  end

  describe "rating (review mode)" do
    it "renders star rating" do
      result = parse('{% quote author="Jane" rating=4 %}Good product{% endquote %}').render
      expect(result).to include("ltag-quote__rating")
      expect(result).to include("4 out of 5 stars")
      filled_count = result.scan("ltag-quote__star--filled").size
      expect(filled_count).to eq(4)
    end

    it "renders 5-star rating" do
      result = parse('{% quote author="Jane" rating=5 %}Perfect{% endquote %}').render
      filled_count = result.scan("ltag-quote__star--filled").size
      expect(filled_count).to eq(5)
    end

    it "renders 1-star rating" do
      result = parse('{% quote author="Jane" rating=1 %}Not great{% endquote %}').render
      filled_count = result.scan("ltag-quote__star--filled").size
      expect(filled_count).to eq(1)
    end

    it "renders source text" do
      result = parse('{% quote author="Jane" source="Product Hunt" %}Nice{% endquote %}').render
      expect(result).to include("ltag-quote__source")
      expect(result).to include("Product Hunt")
    end

    it "raises error for rating=0" do
      expect do
        parse('{% quote author="Jane" rating=0 %}Bad{% endquote %}')
      end.to raise_error(StandardError, /between 1 and 5/)
    end

    it "raises error for rating=6" do
      expect do
        parse('{% quote author="Jane" rating=6 %}Bad{% endquote %}')
      end.to raise_error(StandardError, /between 1 and 5/)
    end
  end

  describe "validation" do
    it "raises error when author is missing" do
      expect do
        parse('{% quote role="CTO" %}No author{% endquote %}')
      end.to raise_error(StandardError, /requires an author/)
    end
  end

  describe "combined options" do
    it "renders a full review with all options" do
      result = parse('{% quote author="Jane Doe" role="Verified Buyer" image="https://example.com/jane.jpg" rating=5 source="App Store" link="https://example.com" %}Amazing product, 10/10 would recommend!{% endquote %}').render
      expect(result).to include("Jane Doe")
      expect(result).to include("Verified Buyer")
      expect(result).to include("https://example.com/jane.jpg")
      expect(result).to include("App Store")
      expect(result).to include("ltag-quote__star--filled")
      expect(result).to include("Amazing product")
    end
  end
end
