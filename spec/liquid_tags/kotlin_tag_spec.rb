require "rails_helper"

RSpec.describe KotlinTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_link) { "https://pl.kotl.in/owreUFFUG?theme=darcula&from=3&to=6&readOnly=true" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("kotlin", KotlinTag)
      Liquid::Template.parse("{% kotlin #{link} %}")
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

    def check(url, expected)
      expect(described_class.parse_link(url)).to eq(expected)
    end

    it "parses URL correctly" do
      check("https://pl.kotl.in/owreUFFUG", from: nil, readOnly: nil, short: "owreUFFUG", theme: nil, to: nil)

      check(
        "https://pl.kotl.in/owreUFFUG?theme=dracula&from=3&to=6&readOnly=true",
        from: "3", readOnly: "true", short: "owreUFFUG", theme: "dracula", to: "6",
      )

      check(
        "https://pl.kotl.in/owreUFFUG?theme=dracula&readOnly=true",
        from: nil, readOnly: "true", short: "owreUFFUG", theme: "dracula", to: nil,
      )

      check(
        "https://pl.kotl.in/owreUFFUG?from=3&to=6",
        from: "3", readOnly: nil, short: "owreUFFUG", theme: nil, to: "6",
      )
    end

    it "produces a correct final URL" do
      expected = "https://play.kotlinlang.org/embed?short=owreUFFUG&from=3&to=6&theme=darcula&readOnly=true"
      expect(described_class.embedded_url(valid_link)).to eq(expected)
    end

    it "renders correctly a Kotlin Playground link" do
      liquid = generate_new_liquid(valid_link)

      # rubocop:disable Style/StringLiterals
      expect(liquid.render).to include('<iframe')
        .and include(
          "https://play.kotlinlang.org/embed?short=owreUFFUG&amp;from&amp;to&amp;theme=darcula&amp;readOnly",
        )
      # rubocop:enable Style/StringLiterals
    end
  end
end
