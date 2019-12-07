require "rails_helper"

vcr_option = {
  cassette_name: "github_api_code",
  allow_playback_repeats: "true"
}

RSpec.describe GithubTag::GithubCodeTag, vcr: vcr_option do
  describe "#id" do
    let(:file_name) { "johnpapa/vscode-peacock/.vscodeignore" }
    let(:path) { "https://github.com/johnpapa/vscode-peacock/blob/master/.vscodeignore" }
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:user) { create(:user) }
    let(:identity) do
      create(:identity, user_id: user.id, token: "6fa0a620b762d0c20d0390589009a89f578800ba")
    end

    setup { Liquid::Template.register_tag("github", GithubTag) }

    def generate_github_code(path, line_number, _options = "")
      Liquid::Template.parse("{% github #{path}#{line_number} %}")
    end

    it "accepts proper github link" do
      expect(generate_github_code(path, "#L12-L17").render).to include(file_name)
    end

    it "handles end line smaller than start line" do
      expect(generate_github_code(path, "#L17-L12").render).to include("Lines 12 to 17")
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
