require "rails_helper"

RSpec.describe Github::OauthClient, :vcr, type: :service do
  let(:repo) { "forem/forem" }
  let(:issue_id) { 7434 }

  describe "initialization" do
    it "raises ArgumentError if credentials are missing" do
      expect { described_class.new({}) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if access_token is empty" do
      expect { described_class.new(access_token: "") }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError if client_id or client_secret are empty" do
      expect { described_class.new(client_id: "value", client_secret: "") }.to raise_error(ArgumentError)
    end

    it "succeeds if access_token is present" do
      expect { described_class.new(access_token: "value") }.not_to raise_error
    end

    it "succeeds if both client_id and client_secret are present" do
      expect { described_class.new(client_id: "value", client_secret: "value") }.not_to raise_error
    end
  end

  describe ".repository" do
    subject(:client) { described_class.new(client_id: "value", client_secret: "value") }

    let(:repo_id) { 100 }

    context "when the Github account to which the repo belongs to is suspended" do
      it "returns a Github::Errors::AccountSuspended error" do
        stub_request(:get, %r{repositories/#{repo_id}}).to_return(body: "account was suspended", status: 403)

        expect { client.repository(repo_id) }.to raise_error(Github::Errors::AccountSuspended)
      end
    end

    context "when the repo is unavailable" do
      it "returns a Github::Errors::RepositoryUnavailable error" do
        stub_request(:get, %r{repositories/#{repo_id}}).to_return(body: "repository access blocked", status: 403)

        expect { client.repository(repo_id) }.to raise_error(Github::Errors::RepositoryUnavailable)
      end
    end
  end

  describe ".issue" do
    it "returns a an issue using the client_id/client_secret" do
      VCR.use_cassette("github_client_issue") do
        client = described_class.new(
          client_id: ApplicationConfig["GITHUB_KEY"],
          client_secret: ApplicationConfig["GITHUB_SECRET"],
        )
        issue = client.issue(repo, issue_id)
        expect(issue.title).to be_present
      end
    end

    it "returns a an issue using the access_token" do
      VCR.use_cassette("github_client_issue_access_token") do
        client = described_class.new(access_token: "value")
        issue = client.issue(repo, issue_id)
        expect(issue.title).to be_present
      end
    end
  end
end
