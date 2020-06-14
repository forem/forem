require "rails_helper"

RSpec.describe GithubTag::GithubCodeTag, type: :liquid_tag, vcr: true do
  describe "#id" do
    let(:file_name) { "johnpapa/vscode-peacock/.vscodeignore" }
    let(:line_range) { "Lines 12 to 17" }
    let(:path) { "https://github.com/johnpapa/vscode-peacock/blob/master/.vscodeignore" }

    setup { Liquid::Template.register_tag("github", GithubTag) }

    def generate_github_code(path, line_number, _options = "")
      Liquid::Template.parse("{% github #{path}#{line_number} %}")
    end

    it "accepts proper github link" do
      VCR.use_cassette("github_code_snippet_render") do
        html = generate_github_code(path, "#L12-L17").render
        expect(html).to include(file_name)
      end
    end

    it "handles end line smaller than start line" do
      VCR.use_cassette("github_code_snippet_render") do
        html = generate_github_code(path, "#L12-L17").render
        expect(html).to include(line_range)
      end
    end

    it "rejects github link without domain" do
      expect do
        generate_github_code("dsdsdsdsdssd3", "")
      end.to raise_error(StandardError)
    end

    it "rejects files with start line exceed file total number of lines" do
      expect do
        generate_github_code(path, "#L5000-L5001")
      end.to raise_error(StandardError)
    end

    it "rejects files with invalid line numbers" do
      expect do
        generate_github_code(path, "#L13-17")
      end.to raise_error(StandardError)
    end
  end
end
