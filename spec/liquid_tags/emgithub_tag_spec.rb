require "rails_helper"

RSpec.describe EmgithubTag, type: :liquid_tag do
  describe "#link" do
    let(:github_links) do
      [
        "https://github.com/abcdefg/hijkl-2020/blob/master/ABC.md#L4-L8",
        "https://github.com/abcdefg/mnop/blob/masterWorker/ABC.md#L4-L8",
        "https://github.com/amochohan/wzta/blob/dev/aws_is_great.js#L1-L9",
        "https://github.com/amochohan/wzta/blob/dev/aws_is_great.js",
      ]
    end

    let(:bad_links) do
      [
        "//pastebin.com/raw/b77FrXUA#github.com",
        "https://github.com@evil.com/repo//blob//abc.mdx#L1-L9",
        "https://github.com.evil.com",
        "https://github.com/string////file",
      ]
    end

    let(:github_link) { "https://github.com/amochohan/repoName/blob/master/awesomeForem.py#L4-L9" }

    def generate_new_liquid(link:)
      Liquid::Template.register_tag("emgithub", EmgithubTag)
      Liquid::Template.parse("{% emgithub #{link} %}")
    end

    def generate_script(link)
      uri = "https://emgithub.com/embed.js?target=#{CGI.escape(link)}&amp;style=a11y-dark"
      uri += "&amp;showBorder=on&amp;showLineNumbers=on&amp;showFileMeta=on"
      html = <<~HTML
        <div class="ltag_emgithub-liquid-tag">
            <script src="#{uri}"></script>
        </div>
      HTML
      html.tr("\n", " ").delete(" ")
    end

    it "accepts proper GitHub url" do
      github_links.each do |link|
        liquid = generate_new_liquid(link: link)
        expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(link))
      end
    end

    it "rejects invalid emgithub url" do
      expect do
        generate_new_liquid("really_long_invalid_gtihub_link")
      end.to raise_error(StandardError)
    end

    it "rejects empty emgithub url" do
      expect do
        generate_new_liquid
      end.to raise_error(StandardError)
    end

    it "rejects XSS attempts" do
      bad_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
