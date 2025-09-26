require "rails_helper"

RSpec.describe Spam::Handler, type: :service do
  describe ".handle_article!" do
    subject(:handler) { described_class.handle_article!(article: article) }

    let!(:article) { create(:article) }
    let(:mascot_user) { create(:user) }
    let(:text_to_check) { [article.title, article.body_markdown].join("\n") }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
    end

    context "when content is not spam" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        # Mock content moderation labeling
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("no_moderation_label")
      end

      it { is_expected.to eq(:not_spam) }
    end

    shared_examples "first-time spam offender" do
      before do
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
          .with(user: article.user, include_user_profile: false).and_return(false)
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(article.user.reload).not_to be_suspended
      end
    end

    shared_examples "multiple spam offender" do
      before do
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

    context "when spam is triggered by RateLimit" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).with(text: text_to_check).and_return(true)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        # Mock content moderation labeling
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("no_moderation_label")
      end

      context "for a first-time offender" do
        it_behaves_like "first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "multiple spam offender"
      end
    end

    context "when spam is triggered by AI check" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        article.user.update!(badge_achievements_count: 3)
        allow(article).to receive(:processed_html).and_return("<p>contains a <a href='spam.com'>link</a></p>")
        allow(Ai::ArticleCheck).to receive(:new).with(article).and_return(double(spam?: true))
        # Mock content moderation labeling
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("no_moderation_label")
      end

      context "for a first-time offender" do
        it_behaves_like "first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "multiple spam offender"
      end
    end

    context "when content moderation labeler identifies spam" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("clear_and_obvious_spam")
        allow(article).to receive(:automod_label).and_return("clear_and_obvious_spam")
        allow(article).to receive(:update_column)
      end

      context "for a first-time offender" do
        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: article.user, include_user_profile: false).and_return(false)
        end

        it "creates a reaction but does not suspend the user" do
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.user.reload).not_to be_suspended
        end

        it "returns :spam" do
          expect(handler).to eq(:spam)
        end
      end

      context "for a multiple offender" do
        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: article.user, include_user_profile: false).and_return(true)
        end

        it "creates a reaction, suspends the user, and returns :spam" do
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.user.reload).to be_suspended
          expect(handler).to eq(:spam)
        end
      end
    end

    context "when content moderation labeler identifies clear and obvious harmful content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("clear_and_obvious_harmful")
        allow(article).to receive(:automod_label).and_return("clear_and_obvious_harmful")
        allow(article).to receive(:update_column)
      end

      context "for a first-time offender" do
        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: article.user, include_user_profile: false).and_return(false)
        end

        it "creates a reaction but does not suspend the user" do
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.user.reload).not_to be_suspended
        end

        it "returns :spam" do
          expect(handler).to eq(:spam)
        end
      end
    end

    context "when content moderation labeler identifies likely harmful content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("likely_harmful")
        allow(article).to receive(:automod_label).and_return("likely_harmful")
        allow(article).to receive(:update_column)
      end

      it "bypasses badge count restrictions but still runs checks" do
        article.user.update!(badge_achievements_count: 10) # High badge count
        allow(Ai::ArticleCheck).to receive(:new).with(article).and_return(double(spam?: false))
        
        expect(handler).to eq(:not_spam)
      end
    end

    context "when content moderation labeler identifies clear and obvious inciting content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("clear_and_obvious_inciting")
        allow(article).to receive(:automod_label).and_return("clear_and_obvious_inciting")
        allow(article).to receive(:update_column)
      end

      context "for a first-time offender" do
        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: article.user, include_user_profile: false).and_return(false)
        end

        it "creates a reaction but does not suspend the user" do
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.user.reload).not_to be_suspended
        end

        it "returns :spam" do
          expect(handler).to eq(:spam)
        end
      end
    end

    context "when content moderation labeler identifies likely inciting content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("likely_inciting")
        allow(article).to receive(:automod_label).and_return("likely_inciting")
        allow(article).to receive(:update_column)
      end

      it "bypasses badge count restrictions but still runs checks" do
        article.user.update!(badge_achievements_count: 10) # High badge count
        allow(Ai::ArticleCheck).to receive(:new).with(article).and_return(double(spam?: false))
        
        expect(handler).to eq(:not_spam)
      end
    end

    context "when content moderation labeler identifies likely spam" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("likely_spam")
        allow(article).to receive(:automod_label).and_return("likely_spam")
        allow(article).to receive(:update_column)
      end

      it "bypasses badge count restrictions but still runs checks" do
        article.user.update!(badge_achievements_count: 10) # High badge count
        allow(Ai::ArticleCheck).to receive(:new).with(article).and_return(double(spam?: false))
        
        expect(handler).to eq(:not_spam)
      end
    end

    context "when content moderation labeler identifies high quality content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(true) # Would normally trigger spam
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(true) # Would normally trigger spam
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("very_good_and_on_topic")
        allow(article).to receive(:automod_label).and_return("very_good_and_on_topic")
        allow(article).to receive(:update_column)
      end

      it "bypasses all spam checks" do
        expect(handler).to eq(:not_spam)
      end
    end

    context "when content moderation labeler identifies great content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(true) # Would normally trigger spam
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(true) # Would normally trigger spam
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:label).and_return("great_and_on_topic")
        allow(article).to receive(:automod_label).and_return("great_and_on_topic")
        allow(article).to receive(:update_column)
      end

      it "bypasses all spam checks" do
        expect(handler).to eq(:not_spam)
      end
    end
  end

  describe ".handle_comment!" do
    subject(:handler) { described_class.handle_comment!(comment: comment) }

    let!(:comment) { create(:comment) }
    let(:mascot_user) { create(:user) }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
      stub_const("Ai::Base::DEFAULT_KEY", "present")
    end

    shared_examples "comment first-time spam offender" do
      before do
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_comment_reactions?)
          .with(user: comment.user, include_user_profile: false).and_return(false)
      end

      it "creates a reaction but does not suspend the user" do
        expect { handler }.to change { Reaction.where(reactable: comment, category: "vomit").count }.by(1)
        expect(comment.user.reload).not_to be_suspended
      end
    end

    shared_examples "comment multiple spam offender" do
      before do
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_comment_reactions?)
          .with(user: comment.user, include_user_profile: false).and_return(true)
      end

      it "creates a reaction, suspends the user, and creates a note" do
        expect { handler }.to change { Reaction.where(reactable: comment, category: "vomit").count }.by(1)
        expect(comment.user.reload).to be_suspended
        expect(Note.where(noteable: comment.user, reason: "automatic_suspend").count).to eq(1)
      end
    end

    context "when user is trusted" do
      it "returns :not_spam if user has > 6 badges" do
        comment.user.update!(badge_achievements_count: 7)
        expect(handler).to eq(:not_spam)
      end

      it "returns :not_spam if user is a base subscriber" do
        comment.user.add_role(:base_subscriber)
        expect(handler).to eq(:not_spam)
      end
    end

    context "when domain-based spam is triggered" do
      let(:spam_domain) { "spam-site-dot-com" }
      let!(:comment) { create(:comment, body_markdown: "Spammy: <a href=\"https://#{spam_domain}\">spam</a>") }

      before do
        11.times do
          create(:comment,
                 created_at: 24.hours.ago,
                 body_markdown: "<p>I love <a href=\"https://#{spam_domain}\">this site</a></p>")
        end

        other_spam_comments = Comment.where("processed_html LIKE ?", "%#{spam_domain}%").where.not(id: comment.id)
        other_spam_comments.limit(9).update_all(score: -101)
      end

      it "returns :spam" do
        expect(handler).to eq(:spam)
      end

      it "does not trigger RateLimit or AI checks" do
        expect(Settings::RateLimit).not_to receive(:trigger_spam_for?)
        expect(Ai::CommentCheck).not_to receive(:new)
        handler
      end

      context "for a first-time offender" do
        it_behaves_like "comment first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "comment multiple spam offender"
      end
    end

    # NEW: Tests to ensure adjacent, non-spammy behavior is ignored.
    context "when domain-based check has no false positives" do
      let(:spam_domain) { "not-really-spam-dot-com" }
      let!(:comment) { create(:comment, body_markdown: "Check this: <a href=\"https://#{spam_domain}\">link</a>") }

      before do
        # Ensure other spam checks are off
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::CommentCheck).to receive_message_chain(:new, :spam?).and_return(false)
      end

      it "does not trigger spam if there are exactly 10 other comments" do
        10.times do
          create(:comment, created_at: 24.hours.ago,
                           body_markdown: "<a href=\"https://#{spam_domain}\">link</a>")
        end
        # Make all 10 low-scoring (100%), but the count is not > 10
        Comment.where("processed_html LIKE ?", "%#{spam_domain}%").where.not(id: comment.id).update_all(score: -101)

        expect(handler).to eq(:not_spam)
        expect { handler }.not_to(change { Reaction.count })
      end

      it "does not trigger spam if 80% or fewer comments are low-scoring" do
        # Create 15 other comments
        15.times do
          create(:comment, created_at: 24.hours.ago,
                           body_markdown: "<a href=\"https://#{spam_domain}\">link</a>")
        end
        # Make 12 of them (exactly 80%) low-scoring. The threshold is > 80%.
        Comment.where("processed_html LIKE ?", "%#{spam_domain}%").where.not(id: comment.id).limit(12).update_all(score: -101)

        expect(handler).to eq(:not_spam)
      end

      it "does not trigger spam if comments are older than 48 hours" do
        11.times do
          # These comments are outside the 48-hour window
          create(:comment, created_at: 50.hours.ago,
                           body_markdown: "<a href=\"https://#{spam_domain}\">link</a>")
        end
        Comment.where("processed_html LIKE ?", "%#{spam_domain}%").where.not(id: comment.id).update_all(score: -101)

        expect(handler).to eq(:not_spam)
      end

      it "does not trigger a domain check if the domain is not in a link" do
        # This comment has no <a> tag, so extract_first_domain_from will return nil
        non_link_comment = create(:comment, body_markdown: "I heard that #{spam_domain} is a cool site.")

        expect(described_class.handle_comment!(comment: non_link_comment)).to eq(:not_spam)
      end
    end

    context "when spam is triggered by RateLimit" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).with(text: comment.body_markdown).and_return(true)
      end

      it "does not perform the AI check" do
        expect(Ai::CommentCheck).not_to receive(:new)
        handler
      end

      context "for a first-time offender" do
        it_behaves_like "comment first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "comment multiple spam offender"
      end
    end

    context "when spam is triggered by AI check" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(comment).to receive(:processed_html).and_return("<a href=\"spam.com\">spam</a>")
        allow(Ai::CommentCheck).to receive_message_chain(:new, :spam?).and_return(true)
      end

      context "for a first-time offender" do
        it_behaves_like "comment first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "comment multiple spam offender"
      end
    end
  end

  # No changes to .handle_user! tests
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