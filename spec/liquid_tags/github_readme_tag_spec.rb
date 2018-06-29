# Sigh, this is tough to test.

require "rails_helper"

vcr_option = {
  cassette_name: "github_api_readme",
  allow_playback_repeats: "true",
}

RSpec.describe GithubTag::GithubReadmeTag, vcr: vcr_option do
  describe "#id" do
    let(:path) { "facebook/react" }
    let(:my_ocktokit_client) { instance_double(Octokit::Client) }
    let(:user) { create(:user) }
    let(:identity) { create(:identity, user_id: user.id, token: "ebd80ff5515c4d14dd1af2e0c33ff570114d1f99") }
    setup { Liquid::Template.register_tag("github", GithubTag) }

    before do
      user = create(:user)
      # create(:identity, user_id: user.id)
    end
    def generate_github_readme(path)
      Liquid::Template.parse("{% github #{path} %}")
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
  end
end
