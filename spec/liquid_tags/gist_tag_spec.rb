require "rails_helper"

RSpec.describe GistTag, type: :liquid_template do
  describe "#link" do
    let(:gist_links) do
      [
        "https://gist.github.com/amochohan/8cb599ee5dc0af5f4246",
        "https://gist.github.com/vaidehijoshi/6536e03b81e93a78c56537117791c3f1",
        "https://gist.github.com/CristinaSolana/1885435",
      ]
    end

    let(:bad_links) do
      [
        "//pastebin.com/raw/b77FrXUA#gist.github.com",
        "https://gist.github.com@evil.com",
        "https://gist.github.com.evil.com",
        "https://gist.github.com/string/string/raw/string/file",
      ]
    end

    let(:gist_link) { "https://gist.github.com/amochohan/8cb599ee5dc0af5f4246" }
    let(:link_with_file_option) { "#{gist_link} file=01_Laravel 5 Simple ACL manager_Readme.md" }
    let(:gist_link_with_version) { "https://gist.github.com/suntong/3a31faf8129d3d7a380122d5a6d48ff6/44c4e7fa81592f917fffacf689dd76f469ca954c" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("gist", GistTag)
      Liquid::Template.parse("{% gist #{link} %}")
    end

    def generate_script(link, option = "")
      uri = option.presence ? "#{link}.js?#{option}" : "#{link}.js"
      html = <<~HTML
        <div class="ltag_gist-liquid-tag">
            <script id="gist-ltag" src="#{uri}"></script>
        </div>
      HTML
      html.tr("\n", " ").delete(" ")
    end

    it "accepts proper gist url" do
      gist_links.each do |link|
        liquid = generate_new_liquid(link)
        expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(link))
      end
    end

    it "handles 'file' option" do
      liquid = generate_new_liquid(link_with_file_option)
      link, option = link_with_file_option.split(" ", 2)
      expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(link, option))
    end

    it "allows embed of specific version" do
      liquid = generate_new_liquid(gist_link_with_version)
      expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(gist_link_with_version))
    end

    it "allows embed of specific version with 'file' option" do
      version_with_file_option = gist_link_with_version.concat(" file=Images.tmpl")
      liquid = generate_new_liquid(version_with_file_option)
      link, option = version_with_file_option.split(" ", 2)
      expect(liquid.render.tr("\n", " ").delete(" ")).to eq(generate_script(link, option))
    end

    it "rejects invalid gist url" do
      expect do
        generate_new_liquid("really_long_invalid_id")
      end.to raise_error(StandardError)
    end

    it "rejects XSS attempts" do
      bad_links.each do |link|
        expect { generate_new_liquid(link) } .to raise_error(StandardError)
      end
    end
  end
end
