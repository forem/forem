require "rails_helper"

RSpec.describe Spam::Handler, type: :service do
  describe ".handle_article!" do
    subject(:handler) { described_class.handle_article!(article: article) }

    let!(:article) { create(:article) }
    let(:mascot_user) { create(:user) }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
    end

    context "when non-spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
      end

      it { is_expected.to eq(:not_spam) }
    end

    context "when first time spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(true)
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
          .with(user: article.user, include_user_profile: false).and_return(false)
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(article.user.reload).not_to be_suspended
      end
    end

    context "when multiple offender of spammy" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(true)
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
          .with(user: article.user, include_user_profile: false).and_return(true)
      end

      it "creates a reaction, suspends the user, and creates a note for the user" do
        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(article.user.reload).to be_suspended
        expect(Note.where(noteable: article.user, reason: "automatic_suspend").count).to eq(1)
      end

      it "creates a reaction, notes, suspends, and unpublishes all posts when applicable" do
        allow(described_class).to receive(:unpublish_all_posts_when_user_auto_suspended?).and_return(true)
        expect(article).to be_published
        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(article.user.reload).to be_suspended
        expect(article.reload).not_to be_published
        expect(Note.where(noteable: article.user, reason: "automatic_suspend").count).to eq(1)
      end
    end
  end

  describe ".handle_comment!" do
    subject(:handler) { described_class.handle_comment!(comment: comment) }

    let!(:comment) { create(:comment) }
    let(:mascot_user) { create(:user) }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
    end

    context "when user has more than 6 badge achievements" do
      before do
        comment.user.update!(badge_achievements_count: 7)
      end

      it "returns :not_spam and does not create a reaction" do
        expect { handler }.not_to change { Reaction.where(reactable: comment).count }
        is_expected.to eq(:not_spam)
      end
    end

    context "when user is base subscriber" do
      before do
        comment.user.add_role(:base_subscriber)
      end
      it "returns :not_spam and does not create a reaction" do
        expect { handler }.not_to change { Reaction.where(reactable: comment).count }
        is_expected.to eq(:not_spam)
      end
    end

    context "when non-spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?)
          .with(text: comment.body_markdown).and_return(false)
        allow(comment).to receive(:processed_html).and_return("<p>hello</p>")
      end

      it { is_expected.to eq(:not_spam) }
    end

    context "when AI spam check flags spam" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?)
          .with(text: comment.body_markdown).and_return(false)
        allow(comment).to receive(:processed_html).and_return("<a href='spam'>")
        allow(Ai::CommentCheck).to receive(:new)
          .with(comment).and_return(double(spam?: true))

        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_comment_reactions?)
          .with(user: comment.user, include_user_profile: false).and_return(false)
        ENV["GEMINI_API_KEY"] = "Present"
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }
          .to change { Reaction.where(reactable: comment, category: "vomit").count }
          .by(1)
        expect(comment.user.reload).not_to be_suspended
      end
    end

    context "when first time spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?)
          .with(text: comment.body_markdown).and_return(true)
        allow(comment).to receive(:processed_html).and_return("<p>no links</p>")
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_comment_reactions?)
          .with(user: comment.user, include_user_profile: false).and_return(false)
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }
          .to change { Reaction.where(reactable: comment, category: "vomit").count }
          .by(1)
        expect(comment.user.reload).not_to be_suspended
      end
    end

    context "when multiple offender of spammy" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?)
          .with(text: comment.body_markdown).and_return(true)
        allow(comment).to receive(:processed_html).and_return("<p>no links</p>")
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_comment_reactions?)
          .with(user: comment.user, include_user_profile: false).and_return(true)
      end

      it "creates a reaction, suspends the user, and creates a note for the user" do
        expect { handler }
          .to change { Reaction.where(reactable: comment, category: "vomit").count }
          .by(1)
        expect(comment.user.reload).to be_suspended
        expect(
          Note.where(noteable: comment.user, reason: "automatic_suspend").count
        ).to eq(1)
      end
    end
  end

  describe ".handle_user!" do
    subject(:handler) { described_class.handle_user!(user: user) }

    let!(:user) { create(:user) }
    let(:mascot_user) { create(:user) }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
    end

    context "when using :more_rigorous_user_profile_spam_checking but there's no spam" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:more_rigorous_user_profile_spam_checking).and_return(true)
      end

      it { is_expected.to eq(:not_spam) }
    end

    context "when using :more_rigorous_user_profile_spam_checking but there spam in the summary" do
      before do
        user.profile.update(summary: "Please Not This")
        allow(FeatureFlag).to receive(:enabled?).with(:more_rigorous_user_profile_spam_checking).and_return(true)
        allow(Settings::RateLimit).to receive(:spam_trigger_terms).and_return(["Please Not This"])
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }.to change { Reaction.where(reactable: user, category: "vomit").count }.by(1)
      end
    end

    context "when non-spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
      end

      it { is_expected.to eq(:not_spam) }
    end

    context "when first time spammy content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(true)
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }.to change { Reaction.where(reactable: user, category: "vomit").count }.by(1)
      end
    end
  end
end
