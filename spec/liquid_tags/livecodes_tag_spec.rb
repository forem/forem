require "rails_helper"

RSpec.describe LivecodesTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_urls) do
      [
        "https://livecodes.io/?x=id/abc123",
        "https://v49.livecodes.io/?x=id/abc123",
        "https://next.livecodes.io/?x=id/abc123",
        "https://livecodes.io/?template=react",
        "https://livecodes.io/?js=console.log(1)&css=body{}&theme=light",
        "https://livecodes.io?x=id/abc123",
        "https://livecodes.io",
        "https://livecodes.io/#config=code/N4IgLglmA2CmIC4QFUB2kawCYAIAKATgPYBWsAxmCADQhawDO5BEADpEaoiDSABawAhlm4AeALawwgnOT6CCDKQF4AOigAqAMQC0ADnU4A9AD5VqCVJmpBktSABuEWAHdWRAmEPlOYWOnsXCCwwPmV6J3JYHSCQvmocCFQoCEFoHSY02GUARgA6AAZDU14%2BMHFoAEEwMEVuaEFUAHN7f28GhgZ7dV5pJoZEAG0AXVpBSggHWABRLCgPbnEFAGsAV1ZeJYI1jYRQBubVwSb4JDKK3h90fyoz2GhoIhAAX1oGMABPOER9xqajk7ccidS6%2BG7cF5vZhsW6-Q7HU4gEiCByCJgsdig67oCGvEDvL6MARSAYIEZQjFgUnkkDAhiERhSCG0VjEKKdDzU0a01bvIjiADKUkgzVJwDxEHE7k8Yrxn1YjB%2BcsYVJ%2BIAO-wR3HljGhmNoVz8OKQkMcsEUEE43AALABOXpEIjQMUgfyCABGcBESDS0F440gUyBnAYTvgb2kYF5QMeShEz2eQA",
      ]
    end

    let(:invalid_urls) do
      [
        "https://livecodes.io.evil.com/?x=id/abc123",
        "https://evil.com/https://livecodes.io/?x=id/abc123",
        "http://livecodes.io/?x=id/abc123",
        "https://livecodesxio/?x=id/abc123",
      ]
    end

    def generate_new_liquid(input)
      Liquid::Template.register_tag("livecodes", described_class)
      Liquid::Template.parse("{% livecodes #{input} %}")
    end

    it "renders an iframe for all valid URL patterns" do
      valid_urls.each do |url|
        rendered = generate_new_liquid(url).render
        expect(rendered).to include("<iframe")
        # ERB HTML-escapes "&" → "&amp;" in attributes, so we compare
        # against the escaped form.
        escaped_url = url.gsub("&", "&amp;")
        expect(rendered).to include(escaped_url)
      end
    end

    it "does not modify the URL" do
      url = "https://livecodes.io/?x=id/abc123"
      rendered = generate_new_liquid(url).render
      expect(rendered).not_to include("embed=true")
    end

    it "uses the default height when none is given" do
      rendered = generate_new_liquid(valid_urls.first).render
      expect(rendered).to include("height: 400px")
    end

    it "accepts a height option" do
      rendered = generate_new_liquid("#{valid_urls.first} height=500").render
      expect(rendered).to include("height: 500px")
    end

    it "raises an error for invalid URLs" do
      invalid_urls.each do |url|
        expect { generate_new_liquid(url).render }.to raise_error(StandardError)
      end
    end

    it "raises an error for invalid options" do
      expect { generate_new_liquid("#{valid_urls.first} height=abc").render }
        .to raise_error(StandardError)
      expect { generate_new_liquid("#{valid_urls.first} width=500").render }
        .to raise_error(StandardError)
    end

    it "decodes HTML-encoded ampersands in the URL" do
      rendered = generate_new_liquid("https://livecodes.io/?js=x&amp;css=y&amp;theme=light").render
      # ERB re-encodes "&" as "&amp;" in the attribute (correct HTML),
      # but it must not be double-encoded as "&amp;amp;"
      expect(rendered).to include("js=x&amp;css=y&amp;theme=light")
      expect(rendered).not_to include("&amp;amp;")
    end
  end
end
