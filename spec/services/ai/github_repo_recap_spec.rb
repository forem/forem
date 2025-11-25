require "rails_helper"

RSpec.describe Ai::GithubRepoRecap do
  let(:repo_name) { "forem/forem" }
  let(:days_ago) { 7 }
  let(:github_client) { double("Github::OauthClient") }
  let(:ai_client) { instance_double(Ai::Base) }
  let(:service) do
    described_class.new(
      repo_name,
      days_ago: days_ago,
      github_client: github_client,
      ai_client: ai_client,
    )
  end

  describe "#generate" do
    let(:merged_at) { 2.days.ago }
    let(:commit_date) { 3.days.ago }

    let(:pull_request) do
      double(
        number: 123,
        title: "Add new feature",
        html_url: "https://github.com/forem/forem/pull/123",
        merged_at: merged_at,
        user: double(login: "testuser"),
      )
    end

    let(:commit) do
      double(
        sha: "abc123def456",
        commit: double(message: "Fix bug in authentication"),
      )
    end

    let(:ai_response) do
      <<~RESPONSE
        TITLE: Weekly Recap: Significant Improvements to Forem

        BODY:
        This week saw some great progress on the Forem repository!

        ## Major Changes

        {% embed https://github.com/forem/forem/pull/123 %}

        The team shipped a significant new feature that improves user experience.

        ## Minor Updates

        - Several bug fixes and performance improvements
        - Documentation updates
        - Dependency updates (#{commit.commit.message})
      RESPONSE
    end

    before do
      # Stub auto_paginate for manual pagination control
      allow(github_client).to receive(:auto_paginate).and_return(true)
      allow(github_client).to receive(:auto_paginate=)
      
      allow(github_client).to receive(:pull_requests)
        .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
        .and_return([pull_request])
      allow(github_client).to receive(:commits)
        .with(repo_name, since: anything, per_page: 100, page: 1)
        .and_return([commit])
      allow(ai_client).to receive(:call).and_return(ai_response)
    end

    it "returns a RecapResult with title and body" do
      result = service.generate

      expect(result).to be_a(Ai::GithubRepoRecap::RecapResult)
      expect(result.title).to eq("Weekly Recap: Significant Improvements to Forem")
      expect(result.body).to include("{% embed https://github.com/forem/forem/pull/123 %}")
      expect(result.body).to include("Major Changes")
    end

    it "calls the AI client with a properly formatted prompt" do
      service.generate

      expect(ai_client).to have_received(:call) do |prompt|
        expect(prompt).to include("Repository:** #{repo_name}")
        expect(prompt).to include("Last #{days_ago} days")
        expect(prompt).to include("##{pull_request.number}: #{pull_request.title}")
        expect(prompt).to include(commit.sha[0..7])
        expect(prompt).to include("{% embed")
      end
    end

    context "when there is no activity" do
      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return([])
      end

      it "returns nil" do
        result = service.generate

        expect(result).to be_nil
        expect(ai_client).not_to have_received(:call)
      end
    end

    context "when there are only old pull requests" do
      let(:old_pr) do
        double(
          number: 100,
          title: "Old PR",
          html_url: "https://github.com/forem/forem/pull/100",
          merged_at: 30.days.ago,
          user: double(login: "olduser"),
        )
      end

      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([old_pr])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return([])
      end

      it "returns nil as there's no recent activity" do
        result = service.generate

        expect(result).to be_nil
      end
    end

    context "when there are only commits (no PRs)" do
      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return([commit])
      end

      it "generates a recap with commits only" do
        result = service.generate

        expect(result).to be_a(Ai::GithubRepoRecap::RecapResult)
        expect(result.title).to be_present
        expect(result.body).to be_present
      end

      it "includes commit information in the prompt" do
        service.generate

        expect(ai_client).to have_received(:call) do |prompt|
          expect(prompt).to include("Commits (1 total)")
          expect(prompt).to include(commit.sha[0..7])
        end
      end
    end

    context "when there are many commits" do
      let(:many_commits) do
        (1..60).map do |i|
          double(
            sha: "commit#{i}#{'0' * 32}",
            commit: double(message: "Commit message #{i}"),
          )
        end
      end

      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return(many_commits)
      end

      it "limits commits in the prompt to avoid token limits" do
        service.generate

        expect(ai_client).to have_received(:call) do |prompt|
          expect(prompt).to include("Commits (60 total)")
          expect(prompt).to include("and 10 more commits")
          expect(prompt).to include("Commit message 1")
          expect(prompt).to include("Commit message 50")
          expect(prompt).not_to include("Commit message 51")
        end
      end
    end

    context "when GitHub API returns an error" do
      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_raise(Github::Errors::NotFound.new("Repository not found"))
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_raise(Github::Errors::Unauthorized.new("Unauthorized"))
      end

      it "handles errors gracefully and returns nil" do
        result = service.generate

        expect(result).to be_nil
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)

        service.generate

        expect(Rails.logger).to have_received(:error).at_least(:once)
      end
    end

    context "when AI client fails" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError.new("API Error"))
      end

      it "handles errors gracefully and returns nil" do
        result = service.generate

        expect(result).to be_nil
      end

      it "logs the error with backtrace" do
        allow(Rails.logger).to receive(:error)

        service.generate

        expect(Rails.logger).to have_received(:error).with(/GitHub Recap generation failed/)
        expect(Rails.logger).to have_received(:error).with(/API Error/)
      end
    end

    context "when AI response is malformed" do
      let(:malformed_response) { "Just some text without proper formatting" }

      before do
        allow(ai_client).to receive(:call).and_return(malformed_response)
      end

      it "still extracts what it can and returns a result" do
        result = service.generate

        expect(result).to be_a(Ai::GithubRepoRecap::RecapResult)
        expect(result.title).to eq("Repository Activity Recap") # default title
        expect(result.body).to eq(malformed_response)
      end
    end

    context "when there are multiple pages of pull requests" do
      let(:recent_pr) do
        double(
          number: 200,
          title: "Recent PR",
          html_url: "https://github.com/forem/forem/pull/200",
          merged_at: 2.days.ago,
          user: double(login: "recentuser"),
        )
      end

      let(:old_pr) do
        double(
          number: 100,
          title: "Old PR",
          html_url: "https://github.com/forem/forem/pull/100",
          merged_at: 30.days.ago,
          user: double(login: "olduser"),
        )
      end

      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        # First page has recent PR
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([recent_pr, old_pr])
        # Should not request page 2 because we found an old PR
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 2)
          .and_return([])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return([])
      end

      it "stops fetching when it encounters PRs before the timeframe" do
        service.generate

        # Should only call page 1 and stop because old_pr is before timeframe
        expect(github_client).to have_received(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .once
        expect(github_client).not_to have_received(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 2)
      end

      it "includes only recent PRs in the recap" do
        result = service.generate

        expect(result).to be_a(Ai::GithubRepoRecap::RecapResult)
        expect(ai_client).to have_received(:call) do |prompt|
          expect(prompt).to include("#200: Recent PR")
          expect(prompt).not_to include("#100: Old PR")
        end
      end
    end

    context "with different timeframes" do
      let(:service_30_days) do
        described_class.new(
          repo_name,
          days_ago: 30,
          github_client: github_client,
          ai_client: ai_client,
        )
      end

      before do
        allow(github_client).to receive(:auto_paginate).and_return(true)
        allow(github_client).to receive(:auto_paginate=)
        
        # Mock for the 30-day service
        allow(github_client).to receive(:pull_requests)
          .with(repo_name, state: "closed", sort: "updated", direction: "desc", per_page: 100, page: 1)
          .and_return([pull_request])
        allow(github_client).to receive(:commits)
          .with(repo_name, since: anything, per_page: 100, page: 1)
          .and_return([commit])
      end

      it "uses the specified timeframe in the prompt" do
        service_30_days.generate

        expect(ai_client).to have_received(:call) do |prompt|
          expect(prompt).to include("Last 30 days")
        end
      end

      it "passes the correct since parameter to GitHub" do
        service_30_days.generate

        expect(github_client).to have_received(:commits) do |_repo, options|
          since_time = Time.parse(options[:since])
          expect(since_time).to be_within(1.minute).of(30.days.ago)
        end
      end
    end
  end

  describe "RecapResult" do
    it "can be instantiated with keyword arguments" do
      result = Ai::GithubRepoRecap::RecapResult.new(
        title: "Test Title",
        body: "Test Body",
      )

      expect(result.title).to eq("Test Title")
      expect(result.body).to eq("Test Body")
    end
  end
end

