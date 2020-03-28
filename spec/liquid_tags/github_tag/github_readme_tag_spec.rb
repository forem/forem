# Sigh, this is tough to test.

require "rails_helper"

vcr_option = {
  cassette_name: "github_api_readme",
  allow_playback_repeats: "true"
}

RSpec.describe GithubTag::GithubReadmeTag, type: :liquid_tag, vcr: vcr_option do
  describe "#id" do
    let(:path) { "facebook/react" }
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:user) { create(:user) }
    let(:identity) do
      create(:identity, user_id: user.id, token: "ebd80ff5515c4d14dd1af2e0c33ff570114d1f99")
    end

    setup { Liquid::Template.register_tag("github", GithubTag) }

    def generate_github_readme(path, options = "")
      Liquid::Template.parse("{% github #{path} #{options} %}")
    end

    it "accepts proper github link" do
      expect(generate_github_readme(path).render).to include(path)
    end

    it "rejects github link without domain" do
      expect do
        generate_github_readme("dsdsdsdsdssd3")
      end.to raise_error(StandardError)
    end

    it "rejects invalid github issue link" do
      expect do
        generate_github_readme("/hello/hey/hey/hey")
      end.to raise_error(StandardError)
    end

    it "handles 'no-readme' option" do
      template = generate_github_readme(path, "no-readme").render
      readme_class = "ltag-github-body"
      expect(template).not_to include(readme_class)
    end

    it "handles respositories with a missing README" do
      allow(my_ocktokit_client).to receive(:readme).and_raise(Octokit::NotFound)

      template = generate_github_readme(path, "no-readme").render
      readme_class = "ltag-github-body"

      expect(template).not_to include(readme_class)
    end
  end
end
