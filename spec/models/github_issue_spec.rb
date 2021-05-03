require "rails_helper"

RSpec.describe GithubIssue, type: :model, vcr: true do
  let(:url_issue) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/7434" }
  let(:url_pull_request) { "https://api.github.com/repos/thepracticaldev/dev.to/pulls/7653" }
  let(:url_comment) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/comments/621043602" }
  let(:url_not_found) { "https://api.github.com/repos/thepracticaldev/dev.to/issues/0" }

  it { is_expected.to validate_length_of(:url).is_at_most(400) }
  it { is_expected.to validate_inclusion_of(:category).in_array(%w[issue issue_comment]) }
  it { is_expected.to validate_presence_of(:url) }

  describe ".find_or_fetch" do
    context "when retrieving an issue", vcr: { cassette_name: "github_client_issue" } do
      it "saves a new issue" do
        expect do
          described_class.find_or_fetch(url_issue)
        end.to change(described_class, :count).by(1)
      end

      it "retrieves an existing issue" do
        created_issue = described_class.find_or_fetch(url_issue)

        expect do
          found_issue = described_class.find_or_fetch(url_issue)
          expect(found_issue.id).to eq(created_issue.id)
        end.not_to change(described_class, :count)
      end

      it "saves the proper fields" do
        issue = described_class.find_or_fetch(url_issue)

        expect(issue.url).to eq(url_issue)
        expect(issue.issue_serialized[:title]).to be_present
        expect(issue.category).to eq("issue")
      end
    end

    context "when retrieving a pull request", vcr: { cassette_name: "github_client_pull_request" } do
      it "saves a new issue" do
        expect do
          described_class.find_or_fetch(url_pull_request)
        end.to change(described_class, :count).by(1)
      end

      it "retrieves an existing issue" do
        created_issue = described_class.find_or_fetch(url_pull_request)

        expect do
          found_issue = described_class.find_or_fetch(url_pull_request)
          expect(found_issue.id).to eq(created_issue.id)
        end.not_to change(described_class, :count)
      end

      it "saves the proper fields" do
        issue = described_class.find_or_fetch(url_pull_request)

        expect(issue.url).to eq(url_pull_request)
        expect(issue.issue_serialized[:title]).to be_present
        expect(issue.category).to eq("issue")
      end
    end

    context "when retrieving a comment", vcr: { cassette_name: "github_client_comment" } do
      it "saves a new issue comment" do
        expect do
          described_class.find_or_fetch(url_comment)
        end.to change(described_class, :count).by(1)
      end

      it "retrieves an existing issue comment" do
        created_issue = described_class.find_or_fetch(url_comment)

        expect do
          found_issue = described_class.find_or_fetch(url_comment)
          expect(found_issue.id).to eq(created_issue.id)
        end.not_to change(described_class, :count)
      end

      it "saves the proper fields" do
        issue = described_class.find_or_fetch(url_comment)

        expect(issue.url).to eq(url_comment)
        expect(issue.issue_serialized[:title]).not_to be_present
        expect(issue.issue_serialized[:body]).to be_present
        expect(issue.category).to eq("issue_comment")
      end
    end
  end

  it "saves HTML in .processed_html" do
    VCR.use_cassette("github_client_issue") do
      issue = described_class.find_or_fetch(url_issue)

      expect(issue.processed_html).to include("<p><strong>Describe the bug</strong></p>")
      expect(issue.processed_html).to include("<p><strong>To Reproduce</strong></p>")
    end
  end

  it "raises Github::Errors::NotFound if the issue is not found" do
    VCR.use_cassette("github_client_issue_not_found") do
      expect do
        described_class.find_or_fetch(url_not_found)
      end.to raise_error(Github::Errors::NotFound)
    end
  end
end
