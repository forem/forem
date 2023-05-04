require "rails_helper"

RSpec.describe ReactionHandler, type: :service do
  # existing reaction by other user
  # existing reaction by same user, other category
  # no existing reaction = create
  # existing reaction = no-op
  # existing contradictory mod reaction

  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:category) { "like" }

  let!(:other_category) { article.reactions.create! user: user, category: "hands" }
  let!(:other_existing) { article.reactions.create! user: create(:user), category: "like" }

  let(:moderator) { create(:user, :trusted) }
  let!(:contradictory_mod) { article.reactions.create! user: moderator, category: "thumbsup" }

  let(:params) do
    {
      reactable_id: article.id,
      reactable_type: article.class.polymorphic_name,
      category: category
    }
  end

  let(:reactable_data) do
    {
      reactable_id: article.id,
      reactable_type: "Article",
      reactable_user_id: article.user.id
    }
  end

  describe "#create" do
    subject(:result) { described_class.new(params, current_user: user).create }

    context "when no existing/matching reaction by user" do
      it "justs create" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "ignores other existing reactions" do
        expect(result).to be_success
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id)
      end

      it "sends a notification to the author" do
        receiver = { klass: "User", id: article.user.id }
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, receiver]) do
          expect(result).to be_success
        end
      end
    end

    context "when the article is written for an organization" do
      let(:org_author) { create(:user, :org_member) }
      let(:organization) { org_author.organizations.first }
      let(:article) { create(:article, organization: organization, user: org_author) }

      it "sends a notification to both the author and the organization" do
        author = { klass: "User", id: article.user.id }
        org = { klass: "Organization", id: organization.id }

        expect(result).to be_success
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, author])
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, org])
      end
    end

    context "when there's an existing/matching reaction by user" do
      let!(:existing) { article.reactions.create! user: user, category: "like" }

      it "does nothing" do
        expect(result).to be_success
        expect(result.action).to eq("none")
      end

      it "ignores other existing reactions" do
        expect(result).to be_success
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id, existing.id)
      end

      it "does not send a notification to the author" do
        sidekiq_assert_no_enqueued_jobs(only: Notifications::NewReactionWorker) do
          expect(result).to be_success
        end
      end
    end

    context "when the reaction is not in a notifiable category" do
      let(:category) { "readinglist" }

      it "does not send a notification to the author" do
        sidekiq_assert_no_enqueued_jobs(only: Notifications::NewReactionWorker) do
          expect(result).to be_success
          expect(result.action).to eq("create")
        end
      end
    end

    context "when there's an existing, contradictory mod reaction" do
      let(:user) { moderator }
      let(:category) { "vomit" }

      it "creates" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "destroys the other reaction as a side-effect" do
        expect(result).to be_success
        expect(Reaction.ids).not_to include(contradictory_mod.id)
      end
    end

    it "updates the last_reacted_at field" do
      Timecop.freeze(Time.current) do
        reaction_handler = described_class.new(params, current_user: user).create
        expect(reaction_handler.reaction.user.last_reacted_at).to eq Time.current
      end
    end
  end

  describe "#toggle" do
    subject(:result) { described_class.new(params, current_user: user).toggle }

    context "when no existing/matching reaction by user" do
      it "justs create" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "ignores other existing reactions" do
        expect(result).to be_success
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id)
      end

      it "sends a notification to the author" do
        receiver = { klass: "User", id: article.user.id }
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, receiver]) do
          expect(result).to be_success
        end
      end
    end

    context "when the reaction is not in a notifiable category" do
      let(:category) { "readinglist" }

      it "does not send a notification to the author" do
        sidekiq_assert_no_enqueued_jobs(only: Notifications::NewReactionWorker) do
          expect(result).to be_success
          expect(result.action).to eq("create")
        end
      end
    end

    context "when there's an existing/matching reaction by user" do
      let!(:existing) { article.reactions.create! user: user, category: "like" }

      it "un-likes" do
        expect(result).to be_success
        expect(result.action).to eq("destroy")
        expect(Reaction.ids).not_to include(existing.id)
      end

      it "ignores other existing reactions" do
        expect(result).to be_success
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id)
      end

      it "immediately sends a notification to the author" do
        allow(Notifications::Reactions::Send).to receive(:call)

        expect(result).to be_success

        expect(Notifications::Reactions::Send).to have_received(:call).with(reactable_data, article.user)
      end
    end

    context "when the article is written for an organization" do
      let(:org_author) { create(:user, :org_member) }
      let(:organization) { org_author.organizations.first }
      let(:article) { create(:article, organization: organization, user: org_author) }

      it "sends a notification to both the author and the organization" do
        author = { klass: "User", id: article.user.id }
        org = { klass: "Organization", id: organization.id }

        expect(result).to be_success
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, author])
        sidekiq_assert_enqueued_with(job: Notifications::NewReactionWorker, args: [reactable_data, org])
      end

      it "sends the notifications immediately if there was an existing reaction" do
        allow(Notifications::Reactions::Send).to receive(:call)

        article.reactions.create! user: user, category: "like"
        expect(result).to be_success

        expect(Notifications::Reactions::Send).to have_received(:call).with(reactable_data, org_author)
        expect(Notifications::Reactions::Send).to have_received(:call).with(reactable_data, organization)
      end
    end

    context "when there's an existing, contradictory mod reaction" do
      let(:user) { moderator }
      let(:category) { "vomit" }

      it "creates" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "destroys the other reaction as a side-effect" do
        expect(result).to be_success
        expect(Reaction.ids).not_to include(contradictory_mod.id)
      end
    end
  end
end
