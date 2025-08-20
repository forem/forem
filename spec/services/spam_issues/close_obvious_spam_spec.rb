# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpamIssues::CloseObviousSpam, type: :service do
  let(:service) { described_class.new(dry_run: true) }
  let(:github_client) { instance_double(Github::OauthClient) }

  before do
    allow(Github::OauthClient).to receive(:new).and_return(github_client)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe "#call" do
    context "when no issues are found" do
      before do
        allow(github_client).to receive(:list_issues).and_return([])
      end

      it "returns empty result" do
        result = service.call
        expect(result[:closed]).to eq(0)
        expect(result[:issues]).to be_empty
      end
    end

    context "when obvious spam issues are found" do
      let(:spam_issue) do
        double(
          "Issue",
          number: 12345,
          title: "Aaaa",
          body: "<!-- Before creating a bug report, try disabling browser extensions to see if the bug is still pres@nsnsnsnbs:199.193.182.172.91.200ent. -->",
          pull_request: nil,
          user: double(login: "spammer"),
          created_at: Time.current,
          html_url: "https://github.com/forem/forem/issues/12345"
        )
      end

      let(:legitimate_issue) do
        double(
          "Issue",
          number: 12346,
          title: "Real bug in user authentication",
          body: "**Describe the bug**\n\nWhen users try to log in with GitHub, they get an error message.\n\n**To Reproduce**\n\n1. Go to login page\n2. Click GitHub login\n3. See error",
          pull_request: nil,
          user: double(login: "legitimate_user"),
          created_at: Time.current,
          html_url: "https://github.com/forem/forem/issues/12346"
        )
      end

      before do
        allow(github_client).to receive(:list_issues).and_return([spam_issue, legitimate_issue])
      end

      it "identifies spam issues correctly" do
        result = service.call
        expect(result[:issues].length).to eq(1)
        expect(result[:issues].first[:number]).to eq(12345)
        expect(result[:issues].first[:title]).to eq("Aaaa")
      end

      it "does not close issues in dry run mode" do
        expect(github_client).not_to receive(:close_issue)
        expect(github_client).not_to receive(:add_comment)
        
        result = service.call
        expect(result[:closed]).to eq(0)
      end

      context "when not in dry run mode" do
        let(:service) { described_class.new(dry_run: false) }

        before do
          allow(github_client).to receive(:close_issue)
          allow(github_client).to receive(:add_comment)
          allow(service).to receive(:sleep) # Speed up tests
        end

        it "closes spam issues" do
          expect(github_client).to receive(:close_issue).with("forem/forem", 12345)
          expect(github_client).to receive(:add_comment).with("forem/forem", 12345, anything)
          
          result = service.call
          expect(result[:closed]).to eq(1)
        end
      end
    end

    context "when GitHub API fails" do
      before do
        allow(github_client).to receive(:list_issues).and_raise(Github::Errors::Error, "API Error")
      end

      it "handles errors gracefully" do
        result = service.call
        expect(result[:closed]).to eq(0)
        expect(result[:issues]).to be_empty
        expect(Rails.logger).to have_received(:error).with("Failed to fetch issues: API Error")
      end
    end
  end

  describe "#obviously_spam?" do
    context "with meaningless title and short body" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Aaaa",
          body: "Short text"
        )
      end

      it "identifies as spam" do
        expect(service.send(:obviously_spam?, issue)).to be true
      end
    end

    context "with suspicious IP pattern" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Bug report",
          body: "This contains a suspicious pattern @nsnsnsnbs:199.193.182.172.91.200ent"
        )
      end

      it "identifies as spam" do
        expect(service.send(:obviously_spam?, issue)).to be true
      end
    end

    context "with random email pattern" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Bug report",
          body: "Contact me @abcdefgh123: for more info"
        )
      end

      it "identifies as spam" do
        expect(service.send(:obviously_spam?, issue)).to be true
      end
    end

    context "with empty template sections and short title" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Bug",
          body: "**Describe the bug**\n\n\n**To Reproduce**\n\n\n**Expected behavior**\n\n\n"
        )
      end

      it "identifies as spam" do
        expect(service.send(:obviously_spam?, issue)).to be true
      end
    end

    context "with legitimate content" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Authentication fails with GitHub OAuth",
          body: "**Describe the bug**\n\nUsers cannot log in using GitHub OAuth\n\n**To Reproduce**\n\n1. Go to login\n2. Click GitHub\n3. See error\n\n**Expected behavior**\n\nShould log in successfully"
        )
      end

      it "does not identify as spam" do
        expect(service.send(:obviously_spam?, issue)).to be false
      end
    end

    context "with borderline content" do
      let(:issue) do
        double(
          "Issue",
          number: 123,
          title: "Bug in feature",
          body: "There is a bug in the feature. It doesn't work as expected."
        )
      end

      it "errs on the side of caution and does not identify as spam" do
        expect(service.send(:obviously_spam?, issue)).to be false
      end
    end
  end
end