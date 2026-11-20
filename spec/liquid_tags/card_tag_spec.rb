require "rails_helper"

RSpec.describe CardTag, type: :liquid_tag do
  describe "#render" do
    let(:body) { "# Hello\n\n`heyhey`\n\n" }

    def generate_details_liquid(body)
      Liquid::Template.register_tag("card", described_class)
      Liquid::Template.parse("{% card %} #{body} {% endcard %}")
    end

    it "contains the correct static attributes" do
      rendered = generate_details_liquid(body).render

      expect(rendered).to include("class=\"crayons-card c-embed")
    end

    it "contains the correct body" do
      rendered = generate_details_liquid(body).render
      p rendered
      expect(rendered).to include("Hello")
      expect(rendered).to include("heyhey")
    end

    it "sanitizes unpermitted HTML in the card body while preserving safe markup" do
      unsafe_body = '<p>Safe</p><script>alert(1)</script>' \
                    '<img src="x" onerror="alert(1)"><a href="javascript:alert(1)">bad</a>'
      rendered = generate_details_liquid(unsafe_body).render

      expect(rendered).to include("<p>Safe</p>")
      expect(rendered).not_to include("<script")
      expect(rendered).not_to include("onerror")
      expect(rendered).not_to include("javascript:")
    end
  end
end
