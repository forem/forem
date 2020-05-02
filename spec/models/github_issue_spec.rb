require "rails_helper"

RSpec.describe GithubIssue, type: :model, vcr: VCR_OPTIONS[:github_issue_api] do
  let(:url) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/510#issue-354483683" }
  let(:pr_url) { "https://api.github.com/repos/thepracticaldev/dev.to/pulls/1784" }
  let(:url_not_found) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/0" }

  it { is_expected.to validate_length_of(:url).is_at_most(400) }
  it { is_expected.to validate_inclusion_of(:category).in_array(%w[issue issue_comment]) }
  it { is_expected.to validate_presence_of(:url) }

  describe ".find_or_fetch" do
    it "saves a new issue" do
      expect do
        described_class.find_or_fetch(url)
      end.to change(described_class, :count).by(1)
    end

    it "retrieves an existing issue" do
      created_issue = described_class.find_or_fetch(url)

      expect do
        found_issue = described_class.find_or_fetch(url)
        expect(found_issue.id).to eq(created_issue.id)
      end.not_to change(described_class, :count)
    end

    it "retrieves an existing pull request" do
      VCR.use_cassette("github_client_issue_pull_request") do
        expect do
          described_class.find_or_fetch(pr_url)
        end.to change(described_class, :count).by(1)
      end
    end

    it "saves HTML in .processed_html" do
      issue = described_class.find_or_fetch(url)
      Approvals.verify(issue.processed_html, name: "github_issue_test", format: :html)
    end

    it "raises Github::Errors::NotFound if the issue is not found" do
      VCR.use_cassette("github_client_issue_not_found") do
        expect do
          described_class.find_or_fetch(url_not_found)
        end.to raise_error(Github::Errors::NotFound)
      end
    end
  end
end
