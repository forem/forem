require "rails_helper"

vcr_option = {
  cassette_name: "gitlab_api_readme",
  allow_playback_repeats: "true"
}

RSpec.describe GitlabTag::GitlabReadmeTag, type: :liquid_tag, vcr: vcr_option do
  describe "#id" do
    let(:path) { "gitlab-org/gitlab" }
    let(:user) { create(:user) }
    let(:identity) do
      create(:identity, user_id: user.id, token: "ebd80ff5515c4d14dd1af2e0c33ff570114d1f99")
    end

    setup { Liquid::Template.register_tag("gitlab", GitlabTag) }

    def generate_gitlab_readme(path, options = "")
      Liquid::Template.parse("{% gitlab #{path} #{options} %}")
    end

    it "accepts proper gitlab link" do
      expect(generate_gitlab_readme(path).render).to include(path)
    end

    it "rejects gitlab link without domain" do
      expect do
        generate_gitlab_readme("dsdsdsdsdssd3")
      end.to raise_error(StandardError)
    end

    it "handles 'no-readme' option" do
      template = generate_gitlab_readme(path, "no-readme").render
      readme_class = "ltag-gitlab-body"
      expect(template).not_to include(readme_class)
    end

    it "handles respositories with a missing README" do
      allow(instance_double(described_class)).to receive(:readme_url).and_return(nil)

      template = generate_gitlab_readme(path, "no-readme").render
      readme_class = "ltag-gitlab-body"

      expect(template).not_to include(readme_class)
    end
  end
end
