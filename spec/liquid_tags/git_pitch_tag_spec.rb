require "rails_helper"

RSpec.describe GitPitchTag, type: :liquid_tag do
  describe "#link" do
    let(:valid_links) do
      [
        "https://gitpitch.com/gitpitch/in-60-seconds",
        "https://gitpitch.com/gitpitch/what-is-gitpitch",
        "https://gitpitch.com/gitpitch/demo-deck",
      ]
    end

    let(:bad_links) do
      [
        "//pastebin.com/raw/b77FrXUA#gist.github.com",
        "https://gitpitch.com/gitpitch/github.com@evil.com",
        "https://gitpitch.github.com.evil.com",
        "https://github.com/string/string/raw/string/file",
      ]
    end

    def generate_tag(link)
      Liquid::Template.register_tag("gitpitch", GitPitchTag)
      Liquid::Template.parse("{% gitpitch #{link} %}")
    end

    def generate_script(link)
      html = <<~HTML
        <iframe height="450" src="#{link}" loading="lazy"></iframe>
      HTML
      html.tr("\n", " ").delete(" ")
    end

    it "rejects invalid gitpitch url" do
      expect do
        generate_new_liquid("really_long_invalid_link")
      end.to raise_error(StandardError)
    end

    it "accepts valid gitpitch url" do
      valid_links.each do |link|
        liquid = generate_tag(link)
        expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(link))
      end
    end
  end
end
