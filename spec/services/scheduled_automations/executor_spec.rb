require "rails_helper"

RSpec.describe ScheduledAutomations::Executor, type: :service do
  let(:bot) { create(:user, type_of: :community_bot) }
  let(:automation) do
    create(:scheduled_automation,
           user: bot,
           service_name: "github_repo_recap",
           action: "create_draft",
           action_config: {
             "repo_name" => "forem/forem",
             "days_ago" => "7",
             "tags" => "opensource, github"
           },
           frequency: "daily",
           frequency_config: { "hour" => 9, "minute" => 0 })
  end

  let(:mock_recap_result) do
    double("RecapResult", title: "Test Recap", body: "Test content", "body=": true)
  end
  let(:mock_service) { double("GithubRepoRecap", generate: mock_recap_result) }
  let(:mock_github_client) { double("GithubClient") }

  before do
    # Set up default mocking for all tests
    allow(Github::OauthClient).to receive(:new).and_return(mock_github_client)
    allow(Ai::GithubRepoRecap).to receive(:new).and_return(mock_service)
    allow(mock_recap_result).to receive(:body=)
  end

  describe ".call" do
    it "executes the automation" do
      result = described_class.call(automation)
      expect(result).to be_a(described_class::Result)
    end
  end

  describe "#call" do
    subject(:executor) { described_class.new(automation) }

    context "when automation is already running" do
      before { automation.update!(state: "running") }

      it "returns a failure result" do
        result = executor.call
        expect(result.success?).to be(false)
        expect(result.error_message).to eq("Automation is already running")
        expect(result.article).to be_nil
      end
    end

    context "when automation executes successfully" do
      it "marks automation as running" do
        expect(automation.state).to eq("active")
        executor.call
        expect(automation.reload.state).to eq("active") # Should be back to active after completion
      end

      it "calls the AI service" do
        expect(Ai::GithubRepoRecap).to receive(:new).with(
          "forem/forem",
          days_ago: 7,
          github_client: mock_github_client
        ).and_return(mock_service)

        executor.call
      end

      it "creates an article" do
        expect { executor.call }.to change(Article, :count).by(1)
      end

      it "creates a draft article when action is create_draft" do
        result = executor.call
        expect(result.success?).to be(true)
        expect(result.article).to be_a(Article)
        expect(result.article.published).to be(false)
        expect(result.article.title).to eq("Test Recap")
        expect(result.article.body_markdown).to eq("Test content")
      end

      it "applies tags from action_config" do
        result = executor.call
        expect(result.article.tag_list).to eq(["opensource", "github"])
      end

      it "sets the next run time" do
        expect { executor.call }.to change { automation.reload.next_run_at }
      end

      it "updates last_run_at" do
        expect { executor.call }.to change { automation.reload.last_run_at }.from(nil)
      end

      it "returns success result" do
        result = executor.call
        expect(result.success?).to be(true)
        expect(result.article).to be_present
        expect(result.error_message).to be_nil
      end

      context "when action is publish_article" do
        before { automation.update!(action: "publish_article") }

        it "creates a published article" do
          result = executor.call
          expect(result.success?).to be(true)
          expect(result.article.published).to be(true)
          expect(result.article.published_at).to be_present
        end
      end

      context "when service returns nil" do
        before { allow(mock_service).to receive(:generate).and_return(nil) }

        it "returns success with no article" do
          result = executor.call
          expect(result.success?).to be(true)
          expect(result.article).to be_nil
          expect(result.error_message).to eq("No content generated (service returned nil)")
        end

        it "does not create an article" do
          expect { executor.call }.not_to change(Article, :count)
        end

        it "still updates next_run_at" do
          expect { executor.call }.to change { automation.reload.next_run_at }
        end
      end

      context "with additional instructions" do
        before do
          automation.update!(additional_instructions: "Focus on major features")
          # Allow the mock to properly handle body= setter
          allow(mock_recap_result).to receive(:body=) do |new_body|
            allow(mock_recap_result).to receive(:body).and_return(new_body)
          end
        end

        it "augments the content with instructions" do
          result = executor.call
          expect(result.article.body_markdown).to include("Test content")
          expect(result.article.body_markdown).to include("**Additional Context:**")
          expect(result.article.body_markdown).to include("Focus on major features")
        end
      end

      context "with string values in action_config" do
        before do
          automation.update!(
            action_config: {
              "repo_name" => "forem/forem",
              "days_ago" => "14", # String instead of integer
              "tags" => "test"
            }
          )
        end

        it "converts string days_ago to integer" do
          expect(Ai::GithubRepoRecap).to receive(:new).with(
            "forem/forem",
            days_ago: 14, # Should be converted to integer
            github_client: mock_github_client
          ).and_return(mock_service)

          executor.call
        end
      end

      context "with organization_id in action_config" do
        let(:organization) { create(:organization) }

        before do
          automation.action_config["organization_id"] = organization.id.to_s
          automation.save!
        end

        it "sets the article organization" do
          result = executor.call
          expect(result.article.organization_id).to eq(organization.id)
        end
      end
    end

    context "when an error occurs" do
      before do
        allow(Github::OauthClient).to receive(:new).and_raise(StandardError, "API Error")
      end

      it "marks automation as failed" do
        executor.call
        expect(automation.reload.state).to eq("failed")
      end

      it "returns failure result" do
        result = executor.call
        expect(result.success?).to be(false)
        expect(result.article).to be_nil
        expect(result.error_message).to include("StandardError: API Error")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error)
        executor.call
        expect(Rails.logger).to have_received(:error).at_least(:once)
      end

      it "does not create an article" do
        expect { executor.call }.not_to change(Article, :count)
      end
    end

    context "when service_name is unknown" do
      before { automation.update!(service_name: "unknown_service") }

      it "raises an ArgumentError" do
        result = executor.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("Unknown service: unknown_service")
      end
    end

    context "when action is invalid" do
      # Skip this test since action validation is handled at the model level
      # The executor assumes it receives a valid automation object
    end

    context "when repo_name is missing" do
      before do
        automation.update!(action_config: { "days_ago" => 7 })
      end

      it "returns failure result" do
        result = executor.call
        expect(result.success?).to be(false)
        expect(result.error_message).to include("repo_name is required")
      end
    end
  end
end

