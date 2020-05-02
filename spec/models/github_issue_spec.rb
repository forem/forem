require "rails_helper"

RSpec.describe GithubIssue, type: :model, vcr: VCR_OPTIONS[:github_issue_api] do
  let(:url) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/510#issue-354483683" }

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

    it "saves HTML in .processed_html" do
      issue = described_class.find_or_fetch(url)
      Approvals.verify(issue.processed_html, name: "github_issue_test", format: :html)
    end
  end
end
