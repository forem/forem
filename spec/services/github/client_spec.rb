require "rails_helper"

RSpec.describe Github::Client, type: :service, vcr: true do
  let(:repo) { "thepracticaldev/dev.to" }

  describe ".issue" do
    it "returns a an issue" do
      VCR.use_cassette("github_client_issue") do
        issue = described_class.issue(repo, 7434)
        expect(issue.title).to be_present
      end
    end

    it "raises NotFound if the issue does not exist" do
      VCR.use_cassette("github_client_issue_not_found") do
        expect do
          described_class.issue(repo, 0)
        end.to raise_error(Github::Errors::NotFound)
      end
    end
  end
end
