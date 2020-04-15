require "rails_helper"

vcr_option = {
  cassette_name: "gitlab_issue_api",
  allow_playback_repeats: "true"
}

RSpec.describe GitlabIssue, type: :model, vcr: vcr_option do
  let(:link) { "https://gitlab.com/api/v4/projects/gitlab-org/gitlab/issues/1" }

  describe "finds or fetches based on URL" do
    it "fetch issue if no present in database" do
      expect { described_class.find_or_fetch(link) }.to change(described_class, :count).by(1)
    end

    it "return issue from database if present" do
      described_class.find_or_fetch(link)
      expect { described_class.find_or_fetch(link) }.not_to change(described_class, :count)
    end

    it "storage html from GitLab at processed_html attribute" do
      issue = described_class.find_or_fetch(link)
      Approvals.verify(issue.processed_html, name: "gitlab_issue_test", format: :html)
    end

    it "raise friendly error for not exist repository" do
      url = "https://gitlab.com/api/v4/projects/not-exist/not-exist/issues/0"
      expected_error_message = "A GitLab issue 404'ed and could not be found!"
      expect { described_class.find_or_fetch(url) }.to raise_error(StandardError, expected_error_message)
    end

    it "raise  error for not exist repository" do
      allow(described_class).to receive(:try_to_get_issue).and_raise(StandardError.new("Foo Bar"))
      expect { described_class.find_or_fetch(link) }.to raise_error(StandardError, "Foo Bar")
    end
  end

  describe "#merge_request?" do
    it "return true for GitlabIssue with Merge Request path" do
      link = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/merge_requests/1"
      issue = described_class.new(url: link)
      expect(issue).to be_merge_request
    end

    it "return false for GitlabIssue with Issue path" do
      link = "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/issue/1"
      issue = described_class.new(url: link)
      expect(issue).not_to be_merge_request
    end
  end
end
