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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "no_moderation_label", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "no_moderation_label", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "no_moderation_label", compellingness_score: 0.5 })
      end

      context "for a first-time offender" do
        it_behaves_like "first-time spam offender"
      end

      context "for a multiple offender" do
        it_behaves_like "multiple spam offender"
      end

      it "marks the author as spam once most of their recent posts are flagged" do
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?).and_return(false)
        create_list(:article, 2, user: article.user).each do |earlier|
          create(:reaction, user: mascot_user, reactable: earlier, category: "vomit")
        end

        handler
        expect(article.user.reload).to be_spam
      end
    end

    context "when the author publishes the same title for the third time in a day" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow(Ai::ContentModerationLabeler).to receive(:new).and_return(
          instance_double(Ai::ContentModerationLabeler,
                          evaluate: { label: "okay_and_on_topic", compellingness_score: 0.5 }),
        )
        allow(Ai::ArticleCheck).to receive(:new).and_return(instance_double(Ai::ArticleCheck, spam?: false))
      end

      # The model rejects a repeated title within five minutes, so farms space their copies out.
      def publish_copies(count)
        create_list(:article, count, user: article.user).each { |copy| copy.update_column(:title, article.title) }
      end

      it "flags it as clear spam without asking the labeler, even for a high-badge author" do
        article.user.update_column(:badge_achievements_count, 10)
        publish_copies(2)

        expect { expect(handler).to eq(:spam) }
          .to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
        expect(Ai::ContentModerationLabeler).not_to have_received(:new)
      end

      it "leaves a second copy alone" do
        publish_copies(1)

        expect(handler).to eq(:not_spam)
      end

      it "ignores copies published more than a day ago" do
        publish_copies(2).each { |copy| copy.update_column(:published_at, 2.days.ago) }

        expect(handler).to eq(:not_spam)
      end
    end

    context "when Gemini blocks the article as PROHIBITED_CONTENT" do
      let(:blocked_response) do
        instance_double(HTTParty::Response,
                        success?: true, code: 200,
                        parsed_response: { "promptFeedback" => { "blockReason" => "PROHIBITED_CONTENT" } })
      end

      before do
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow(Ai::Base).to receive(:post).and_return(blocked_response)
      end

      it "flags the article, labels it harmful, and marks the author as spam" do
        expect(handler).to eq(:spam)
        expect(Reaction.where(reactable: article, category: "vomit", user: mascot_user)).to exist
        expect(article.reload.automod_label).to eq("clear_and_obvious_harmful")
        expect(article.user.reload).to be_spam
      end
    end

    context "when an article without links goes through the escalation check" do
      let(:labeler) do
        instance_double(Ai::ContentModerationLabeler,
                        evaluate: { label: "no_moderation_label", compellingness_score: 0.5 })
      end

      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow(article).to receive(:processed_html).and_return("<p>DM me on Telegram @seller</p>")
        allow(Ai::ArticleCheck).to receive(:new).with(article)
          .and_return(instance_double(Ai::ArticleCheck, spam?: true))
        allow(Ai::ContentModerationLabeler).to receive(:new).and_return(labeler)
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?).and_return(false)
      end

      it "runs the spam check when the escalation check flags it" do
        allow(Ai::SpamEscalationCheck).to receive(:new)
          .and_return(instance_double(Ai::SpamEscalationCheck, escalate?: true))
        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
      end

      it "skips the spam check when the escalation check doesn't flag it" do
        allow(Ai::SpamEscalationCheck).to receive(:new)
          .and_return(instance_double(Ai::SpamEscalationCheck, escalate?: false))
        expect(handler).to eq(:not_spam)
        expect(Ai::ArticleCheck).not_to have_received(:new)
      end

      it "skips the spam check while :spam_escalation is off, even with a TypeSafe key" do
        stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "test-typesafe-key")
        allow(Ai::TypeSafe::Client).to receive(:new)

        expect(handler).to eq(:not_spam)
        expect(Ai::TypeSafe::Client).not_to have_received(:new)
        expect(Ai::ArticleCheck).not_to have_received(:new)
      end

      it "escalates to the spam check when Jev flags off-platform contact" do
        enable_jev_for(:spam_escalation)
        requests = stub_jev(offplatform_contact: 0.9)

        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(requests.first[:state][:content]).to eq(text_to_check)
      end
    end

    context "when escalation and the article spam check both run on Jev without a Gemini key" do
      before do
        stub_const("Ai::Base::DEFAULT_KEY", nil)
        enable_jev_for(:spam_escalation, :article_spam_check)
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(article).to receive(:processed_html).and_return("<p>DM me on Telegram @seller</p>")
        allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?).and_return(false)
      end

      it "flags the article when both checks agree" do
        requests = stub_jev(offplatform_contact: 0.9, malicious: 0.95)

        expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        expect(requests.size).to eq(2)
      end

      it "does not flag the article when the spam check disagrees" do
        requests = stub_jev(offplatform_contact: 0.9, good_faith: 0.9)

        expect(handler).to eq(:not_spam)
        expect(requests.size).to eq(2)
      end
    end

    context "when spam is triggered by linked domain net_score check" do
      let(:spam_domain) { "bad-seo-site.com" }
      let!(:linked_domain) { LinkedDomain.create!(host: spam_domain, net_score: -2000) }

      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(article).to receive(:processed_html).and_return("<a href=\"https://#{spam_domain}/foo\">spam link</a>")
        article_check = instance_double(Ai::ArticleCheck, spam?: false)
        allow(Ai::ArticleCheck).to receive(:new).with(article).and_return(article_check)
        # Mock content moderation labeling
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "no_moderation_label", compellingness_score: 0.5 })
      end

      context "when user score is 0" do
        before { article.user.update!(score: 0) }

        it "triggers spam reaction and labels as clear_and_obvious_spam when domain net_score is <= -2000" do
          linked_domain.update!(net_score: -2000)
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
        end

        it "returns :not_spam when domain net_score is > -2000" do
          linked_domain.update!(net_score: -1999)
          expect(handler).to eq(:not_spam)
        end

        it "triggers spam reaction and labels as clear_and_obvious_spam when html uses single quotes" do
          allow(article).to receive(:processed_html).and_return("<a href='https://#{spam_domain}/foo'>spam link</a>")
          linked_domain.update!(net_score: -2000)
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
        end
      end

      context "when the admin threshold is customized" do
        before do
          allow(Settings::RateLimit).to receive(:linked_domain_spam_score_threshold).and_return(500)
          article.user.update!(score: 0)
        end

        it "flags posts linking to domains at the custom threshold" do
          linked_domain.update!(net_score: -500)
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
        end

        it "does not flag posts linking to domains above the custom threshold" do
          linked_domain.update!(net_score: -499)
          expect(handler).to eq(:not_spam)
        end
      end

      context "when user score is 50" do
        before { article.user.update!(score: 50) }

        it "triggers spam reaction and labels as clear_and_obvious_spam when domain net_score is <= -12000" do
          linked_domain.update!(net_score: -12000)
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
        end

        it "returns :not_spam when domain net_score is > -12000" do
          linked_domain.update!(net_score: -11999)
          expect(handler).to eq(:not_spam)
        end
      end

      context "when user score is greater than 50" do
        before { article.user.update!(score: 51) }

        it "skips the check and returns :not_spam even if domain net_score is very low" do
          linked_domain.update!(net_score: -100000)
          expect(handler).to eq(:not_spam)
        end
      end

      context "when user score is 20" do
        before { article.user.update!(score: 20) }

        it "triggers spam reaction and labels as clear_and_obvious_spam when domain net_score is <= -6000" do
          linked_domain.update!(net_score: -6000)
          expect { handler }.to change { Reaction.where(reactable: article, category: "vomit").count }.by(1)
          expect(article.reload.automod_label).to eq("clear_and_obvious_spam")
        end

        it "returns :not_spam when domain net_score is > -6000" do
          linked_domain.update!(net_score: -5999)
          expect(handler).to eq(:not_spam)
        end
      end

      context "with invalid URLs in HTML" do
        before do
          article.user.update!(score: 0)
          allow(article).to receive(:processed_html).and_return("<a href=\"http://[\">bad link</a>")
        end

        it "gracefully handles URI parse errors and returns :not_spam" do
          expect(handler).to eq(:not_spam)
        end
      end

      context "for a first-time offender" do
        before do
          article.user.update!(score: 0)
          linked_domain.update!(net_score: -2000)
        end

        it_behaves_like "first-time spam offender"
      end

      context "for a multiple offender" do
        before do
          article.user.update!(score: 0)
          linked_domain.update!(net_score: -2000)
        end

        it_behaves_like "multiple spam offender"
      end
    end

    context "when content moderation labeler identifies spam" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "clear_and_obvious_spam", compellingness_score: 0.5 })
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

      # Two earlier flags plus the mascot's vomit on the current article make three, which is enough
      # to mark the author. Each "does not count" example breaks exactly one of the earlier flags.
      context "with a low-trust author whose earlier posts were already auto-flagged" do
        let(:author) { article.user }
        let(:earlier_articles) { create_list(:article, 2, user: author) }
        let(:earlier_flags) { Reaction.where(user: mascot_user, reactable: earlier_articles) }
        let(:auto_spam_notes) { Note.where(noteable: author, reason: "automatic_spam") }
        let(:other_user) { create(:user) }

        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: author, include_user_profile: false).and_return(false)
          earlier_articles.each do |earlier|
            earlier.update_column(:automod_label, "clear_and_obvious_spam")
            create(:reaction, user: mascot_user, reactable: earlier, category: "vomit")
          end
        end

        it "marks the author as spam without waiting for moderator confirmation" do
          handler
          expect(author.reload).to be_spam
          expect(author).not_to be_suspended
        end

        it "leaves the author alone when flagged posts are under 75% of their recent posts" do
          create_list(:article, 2, user: author)
          handler
          expect(author.reload).not_to be_spam
        end

        it "leaves a note from the mascot explaining why the author was marked as spam" do
          expect { handler }.to change(auto_spam_notes, :count).by(1)

          note = auto_spam_notes.last
          expect(note.author_id).to eq(mascot_user.id)
          expect(note.content).to eq(
            I18n.t("services.spam.article_handler.marked_spam_repeat_auto_flags", count: 3),
          )
        end

        it "does not leave an automatic_suspend note" do
          handler
          expect(Note.where(noteable: author, reason: "automatic_suspend")).to be_empty
        end

        it "does not add another note when the author is already marked as spam" do
          author.add_role(:spam)
          expect { handler }.not_to change(auto_spam_notes, :count)
          expect(author.reload).to be_spam
        end

        it "leaves a single note when another flagged post is handled afterwards" do
          handler
          later_article = create(:article, user: author)
          described_class.handle_article!(article: later_article)

          expect(later_article.reload.automod_label).to eq("clear_and_obvious_spam")
          expect(auto_spam_notes.count).to eq(1)
        end

        it "suspends instead when the author already has too many confirmed flags" do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?)
            .with(user: author, include_user_profile: false).and_return(true)
          handler
          expect(author.reload).to be_suspended
          expect(author).not_to be_spam
          expect(auto_spam_notes).to be_empty
        end

        it "marks authors with 3 badges" do
          author.update_column(:badge_achievements_count, 3)
          handler
          expect(author.reload).to be_spam
        end

        it "leaves authors with 4 or more badges alone" do
          author.update_column(:badge_achievements_count, 4)
          handler
          expect(author.reload).not_to be_spam
          expect(auto_spam_notes).to be_empty
        end

        it "counts auto-flags that moderators have confirmed" do
          earlier_flags.update_all(status: "confirmed")
          handler
          expect(author.reload).to be_spam
        end

        it "counts posts labeled harmful or inciting" do
          earlier_articles.first.update_column(:automod_label, "clear_and_obvious_harmful")
          earlier_articles.second.update_column(:automod_label, "clear_and_obvious_inciting")
          handler
          expect(author.reload).to be_spam
        end

        it "ignores auto-flags that moderators have invalidated" do
          earlier_flags.update_all(status: "invalid")
          handler
          expect(author.reload).not_to be_spam
          expect(auto_spam_notes).to be_empty
        end

        it "does not mark the author with only two auto-flags" do
          earlier_flags.first.destroy
          handler
          expect(author.reload).not_to be_spam
          expect(auto_spam_notes).to be_empty
        end

        it "does not count posts published more than a month ago" do
          earlier_articles.first.update_column(:published_at, 2.months.ago)
          handler
          expect(author.reload).not_to be_spam
        end

        it "does not count posts that are no longer published" do
          earlier_articles.first.update_column(:published, false)
          handler
          expect(author.reload).not_to be_spam
        end

        it "counts posts the spam check flagged without a clear-violation label" do
          earlier_articles.first.update_column(:automod_label, "likely_spam")
          handler
          expect(author.reload).to be_spam
        end

        it "does not count flagged posts the labeler rated on topic" do
          earlier_articles.first.update_column(:automod_label, "okay_and_on_topic")
          handler
          expect(author.reload).not_to be_spam
        end

        it "leaves authors alone when any recent post is labeled high quality" do
          create(:article, user: author).update_column(:automod_label, "very_good_and_on_topic")
          handler
          expect(author.reload).not_to be_spam
          expect(auto_spam_notes).to be_empty
        end

        it "does not count vomits from users other than the mascot" do
          earlier_flags.first.update_column(:user_id, other_user.id)
          handler
          expect(author.reload).not_to be_spam
        end

        it "does not count auto-flags on other authors' posts" do
          earlier_articles.first.update_column(:user_id, other_user.id)
          handler
          expect(author.reload).not_to be_spam
        end
      end

      context "when the mascot's reaction isn't created" do
        before do
          allow(Reaction).to receive(:user_has_been_given_too_many_spammy_article_reactions?).and_return(false)
          allow(Rails.logger).to receive(:warn)
        end

        it "logs a warning when the reaction fails validation" do
          allow(article).to receive(:published).and_return(false)
          handler
          expect(Rails.logger).to have_received(:warn).with(/Spam reaction not created for Article #{article.id}/)
        end

        it "stays quiet when the mascot has already reacted" do
          create(:reaction, user: mascot_user, reactable: article, category: "vomit")
          handler
          expect(Rails.logger).not_to have_received(:warn).with(/Spam reaction not created/)
        end
      end
    end

    context "when content moderation labeler identifies clear and obvious harmful content" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(Ai::ArticleCheck).to receive_message_chain(:new, :spam?).and_return(false)
        stub_const("Ai::Base::DEFAULT_KEY", "present")
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "clear_and_obvious_harmful", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "likely_harmful", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "clear_and_obvious_inciting", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "likely_inciting", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "likely_spam", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "very_good_and_on_topic", compellingness_score: 0.5 })
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
        allow_any_instance_of(Ai::ContentModerationLabeler).to receive(:evaluate).and_return({ label: "great_and_on_topic", compellingness_score: 0.5 })
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

    context "when Gemini blocks the comment as PROHIBITED_CONTENT" do
      let(:blocked_response) do
        instance_double(HTTParty::Response,
                        success?: true, code: 200,
                        parsed_response: { "promptFeedback" => { "blockReason" => "PROHIBITED_CONTENT" } })
      end

      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(comment).to receive(:processed_html).and_return("<a href=\"spam.com\">spam</a>")
        allow(Ai::Base).to receive(:post).and_return(blocked_response)
      end

      it "flags the comment and marks the author as spam" do
        expect(handler).to eq(:spam)
        expect(Reaction.where(reactable: comment, category: "vomit", user: mascot_user)).to exist
        expect(comment.user.reload).to be_spam
      end

      it "leaves the comment alone when only the surrounding context was blocked" do
        answer = { "candidates" => [{ "content" => { "parts" => [{ "text" => "NO" }] } }] }
        allowed_response = instance_double(HTTParty::Response, success?: true, code: 200, parsed_response: answer)
        allow(Ai::Base).to receive(:post).and_return(blocked_response, allowed_response)
        expect(handler).to eq(:not_spam)
        expect(comment.user.reload).not_to be_spam
      end
    end

    context "when a comment without links is flagged by the escalation check" do
      before do
        allow(Settings::RateLimit).to receive(:trigger_spam_for?).and_return(false)
        allow(comment).to receive(:processed_html).and_return("<p>WhatsApp +1 555 0100 for verified accounts</p>")
        allow(Ai::SpamEscalationCheck).to receive(:new)
          .and_return(instance_double(Ai::SpamEscalationCheck, escalate?: true))
        allow(Ai::CommentCheck).to receive(:new).with(comment)
          .and_return(instance_double(Ai::CommentCheck, spam?: true))
      end

      it_behaves_like "comment first-time spam offender"
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

  describe ".handle_profile_update!" do
    subject(:handler) { described_class.handle_profile_update!(user: user) }

    let!(:user) { create(:user) }
    let(:mascot_user) { create(:user) }

    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(mascot_user.id)
      stub_const("Ai::Base::DEFAULT_KEY", "present")
    end

    context "when user is already spam or suspended" do
      before do
        user.add_role(:spam)
      end

      it "skips without reactions" do
        expect(handler).to eq(:skipped)
        expect { handler }.not_to(change { Reaction.count })
      end
    end

    context "when user has more than 3 published articles" do
      before do
        create_list(:article, 4, user: user)
      end

      it "skips and does not label" do
        expect(Ai::ProfileModerationLabeler).not_to receive(:new)
        expect(handler).to eq(:skipped)
      end
    end

    context "when user has more than 3 published comments" do
      before do
        create_list(:comment, 4, user: user)
      end

      it "skips without reactions" do
        expect(handler).to eq(:skipped)
        expect { handler }.not_to(change { Reaction.count })
      end
    end

    context "when label is clear_and_obvious_spam" do
      before do
        allow(Ai::ProfileModerationLabeler).to receive_message_chain(:new, :label).and_return("clear_and_obvious_spam")
      end

      it "adds spam role and reaction" do
        expect { handler }.to change { Reaction.where(reactable: user, category: "vomit").count }.by(1)
        expect(user.reload).to be_spam
      end
    end

    context "when label is clear_and_obvious_harmful" do
      before do
        allow(Ai::ProfileModerationLabeler).to receive_message_chain(:new, :label).and_return("clear_and_obvious_harmful")
      end

      it "suspends and reacts with a note" do
        expect { handler }.to change { Reaction.where(reactable: user, category: "vomit").count }.by(1)
        expect(user.reload).to be_suspended
        expect(Note.where(noteable: user, reason: "automatic_suspend").count).to eq(1)
      end
    end

    context "when label is not a clear violation" do
      before do
        allow(Ai::ProfileModerationLabeler).to receive_message_chain(:new, :label).and_return("no_moderation_label")
      end

      it "returns :not_spam without reactions" do
        expect(handler).to eq(:not_spam)
        expect { handler }.not_to(change { Reaction.count })
      end
    end

    context "when no AI provider is available for profile moderation" do
      before { stub_const("Ai::Base::DEFAULT_KEY", nil) }

      it "skips without labeling" do
        allow(Ai::ProfileModerationLabeler).to receive(:new)

        expect(handler).to eq(:skipped)
        expect(Ai::ProfileModerationLabeler).not_to have_received(:new)
      end
    end

    context "when profile moderation runs on Jev without a Gemini key" do
      before do
        stub_const("Ai::Base::DEFAULT_KEY", nil)
        enable_jev_for(:profile_moderation)
        allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
      end

      it "labels through TypeSafe and acts on a clear violation" do
        stub_jev(keyword_stuffed_identity: 0.95)

        expect { handler }.to change { Reaction.where(reactable: user, category: "vomit").count }.by(1)
        expect(user.reload).to be_spam
      end

      it "does not act on an uncertain signal" do
        stub_jev(keyword_stuffed_identity: 0.7)

        expect(handler).to eq(:not_spam)
        expect(user.reload).not_to be_spam
      end
    end
  end
end
