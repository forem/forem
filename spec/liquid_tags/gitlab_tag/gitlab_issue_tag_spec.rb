require "rails_helper"

vcr_option = {
  cassette_name: "gitlab_api",
  allow_playback_repeats: "true"
}

RSpec.describe GitlabTag::GitlabIssueTag, type: :liquid_tag, vcr: vcr_option do
  setup { Liquid::Template.register_tag("gitlab", GitlabTag) }

  def generate_gitlab_issue(link)
    Liquid::Template.parse("{% gitlab #{link} %}")
  end

  describe "parse link correctly" do
    it "issue with dash" do
      output = generate_gitlab_issue("https://gitlab.com/gitlab-org/gitlab/-/issues/1").render
      Approvals.verify(output, name: "gitlab_liquid_tag_default", format: :html)
    end
  end

  describe "issue" do
    let(:gitlab_link) { "https://gitlab.com/gitlab-org/gitlab/issues/1" }

    it "rejects gitlab link without domain" do
      expect do
        generate_gitlab_issue("/gitlab/issues/1")
      end.to raise_error(StandardError)
    end

    it "rejects invalid gitlab issue link" do
      expect do
        generate_gitlab_issue("https://gitlab.com/issues/1")
      end.to raise_error(StandardError)
    end

    it "renders properly" do
      output = generate_gitlab_issue(gitlab_link).render
      Approvals.verify(output, name: "gitlab_liquid_tag_default", format: :html)
    end
  end

  describe "merge_request" do
    let(:gitlab_link) { "https://gitlab.com/gitlab-org/gitlab/merge_requests/1" }

    setup { Liquid::Template.register_tag("gitlab", GitlabTag) }

    def generate_gitlab_issue(link)
      Liquid::Template.parse("{% gitlab #{link} %}")
    end

    it "rejects gitlab link without domain" do
      expect do
        generate_gitlab_issue("/gitlab/merge_requests/1")
      end.to raise_error(StandardError)
    end

    it "rejects invalid gitlab issue link" do
      expect do
        generate_gitlab_issue("https://gitlab.com/merge_requests/1")
      end.to raise_error(StandardError)
    end

    it "renders properly" do
      output = generate_gitlab_issue(gitlab_link).render
      Approvals.verify(output, name: "gitlab_mr_liquid_tag_default", format: :html)
    end
  end
end
