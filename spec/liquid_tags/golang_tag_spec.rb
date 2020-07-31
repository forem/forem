require "rails_helper"

RSpec.describe GolangTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_link) { "https://play.golang.org/p/HmnNoBf0p1z" }
    let(:missing_link) { "https://play.golang.org/p/HmnNoBf0p1z" }

    def generate_tag(link)
      Liquid::Template.register_tag("golang", GolangTag)
      Liquid::Template.parse("{% golang #{link} %}")
    end

    it "accepts valid input" do
      expect { generate_tag(valid_link) }.not_to raise_error
    end

    it "renders valid input" do
      template = generate_tag(valid_link)
      expected = 'src="https://play.golang.org/p/HmnNoBf0p1z"'
      expect(template.render(nil)).to include(expected)
    end

    it "accepts only Kotlin Playground links" do
      badurl = "https://example.com"
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)

      badurl = "not even an URL"
      expect do
        generate_new_liquid(badurl)
      end.to raise_error(StandardError)
    end

    it "renders iframe" do
      liquid = generate_tag(valid_link)
      expect(liquid.render).to include("<iframe")
    end
  end
end
