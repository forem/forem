require "rails_helper"

RSpec.describe Emails::SendUserDigestWorker, type: :worker do
  let(:worker) { subject }
  let(:user) do
    u = create(:user, :without_profile, profile_image: nil)
    u.notification_setting.update_column(:email_digest_periodic, true)
    u
  end
  let(:author) { create(:user, :without_profile, profile_image: nil) }
  let(:tag)    { create(:tag) }
  let(:default_subforem) { build_stubbed(:subforem, domain: "default.test") }
  let(:mailer)           { double }
  let(:message_delivery) { double }
  let(:stubbed_author)   { build_stubbed(:user, :without_profile, profile_image: nil) }
  let(:stubbed_article) do
    build_stubbed(:article, user: stubbed_author, with_tags: false, with_main_image: false,
                            ai_summary: "Existing summary", ai_summary_generated_at: Time.current)
  end

  def stub_collector_articles(articles = [stubbed_article], feed_config_id: nil)
    collector = instance_double(EmailDigestArticleCollector, articles_to_send: articles, feed_config_id: feed_config_id)
    allow(EmailDigestArticleCollector).to receive(:new).with(user, force_send: boolean).and_return(collector)
  end

  before do
    # Set up default subforem for testing
    RequestStore.store[:default_subforem_id] = default_subforem.id
    allow(Subforem).to receive(:cached_default_id).and_return(default_subforem.id)

    allow(DigestMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:digest_email).and_return(message_delivery)
    allow(message_delivery).to receive(:deliver_now)
  end

  after do
    # Clean up RequestStore after each test
    RequestStore.store[:default_subforem_id] = nil
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  # rubocop:disable RSpec/NestedGroups
  describe "perform" do
    # force_send exists to bypass the digest consent check for manual and retry
    # sends. It must not become a way to email a moderated account.
    context "with a moderated user" do
      before { stub_collector_articles }

      it "does not send to suspended or spam users even when forced, but sends to a user in good standing",
         :aggregate_failures do
        user.add_role(:spam)
        worker.perform(user.id)
        expect(message_delivery).not_to have_received(:deliver_now)

        user.remove_role(:spam)
        user.add_role(:suspended)
        worker.perform(user.id)
        worker.perform(user.id, true)
        expect(message_delivery).not_to have_received(:deliver_now)

        user.remove_role(:suspended)
        worker.perform(user.id)
        expect(message_delivery).to have_received(:deliver_now).once
      end
    end

    context "when there's articles to be sent" do
      before { stub_collector_articles }

      it "send digest email when there are at least 3 hot articles and wraps analytics in synchronous_commit_off",
         :aggregate_failures do
        allow(EmailDigestArticleCollector).to receive(:new).and_call_original
        allow(ApplicationRecord).to receive(:with_synchronous_commit_off).and_call_original
        user.follow(author)
        user.follow(tag)
        create_list(:article, 3, user_id: author.id, public_reactions_count: 20, score: 20,
                                 tag_list: [tag.name], with_main_image: false)

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with).with(hash_including(user: user, articles: kind_of(Array),
                                                                         billboards: kind_of(Array)))
        expect(mailer).to have_received(:digest_email)
        expect(message_delivery).to have_received(:deliver_now)
        expect(ApplicationRecord).to have_received(:with_synchronous_commit_off)
      end

      it "does not send email when user does not have email_digest_periodic or is not registered",
         :aggregate_failures do
        user.notification_setting.update_column(:email_digest_periodic, false)
        worker.perform(user.id)
        expect(DigestMailer).not_to have_received(:with)

        user.notification_setting.update_column(:email_digest_periodic, true)
        user.update_column(:registered, false)
        worker.perform(user.id)
        expect(DigestMailer).not_to have_received(:with)
      end

      it "includes billboards and creates billboard events when billboards are present", :aggregate_failures do
        bb_1 = create(:billboard, placement_area: "digest_first",  published: true, approved: true, organization: nil)
        bb_2 = create(:billboard, placement_area: "digest_second", published: true, approved: true, organization: nil)

        worker.perform(user.id)

        expect(DigestMailer).to have_received(:with) do |args|
          expect(args[:billboards]).to contain_exactly(bb_1, bb_2)
        end
        expect(BillboardEvent.where(billboard_id: bb_1.id, category: "impression").size).to be(1)
        expect(BillboardEvent.where(billboard_id: bb_2.id, category: "impression").size).to be(1)
      end

      it "still delivers email even if billboard event creation raises" do
        create(:billboard, placement_area: "digest_first", published: true, approved: true, organization: nil)

        allow(BillboardEvent).to receive(:create).and_raise(StandardError.new("DB error"))
        allow(Rails.error).to receive(:report)

        worker.perform(user.id)

        # Email was already delivered before billboard tracking was attempted
        expect(message_delivery).to have_received(:deliver_now)
        expect(Rails.error).to have_received(:report).with(
          instance_of(StandardError),
          context: { user_id: user.id, article_ids: array_including(kind_of(Integer)) },
        )
      end

      it "rescues Net::SMTPSyntaxError and logs a warning without notifying Honeybadger" do
        smtp_error = Net::SMTPSyntaxError.new("501 Recipient syntax error")
        allow(message_delivery).to receive(:deliver_now).and_raise(smtp_error)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.error).to receive(:report)

        worker.perform(user.id)

        expect(Rails.logger).to have_received(:warn).with(%r{SMTP syntax/fatal error})
        expect(Rails.error).not_to have_received(:report)
      end

      context "when there's a preferred paired billboard" do
        let!(:bb_1) do
          create(
            :billboard,
            placement_area: "digest_first",
            published: true,
            approved: true,
            organization: nil,
          )
        end
        let!(:paired_bb) do
          create(
            :billboard,
            placement_area: "digest_second",
            published: true,
            approved: true,
            prefer_paired_with_billboard_id: bb_1.id,
            organization: nil,
          )
        end
        let!(:other_bb) do
          create(
            :billboard,
            placement_area: "digest_second",
            published: true,
            approved: true,
            organization: nil,
          )
        end

        it "selects the paired billboard for the second slot and creates events only for the selected billboards",
           :aggregate_failures do
          worker.perform(user.id)

          expect(DigestMailer).to have_received(:with) do |args|
            expect(args[:billboards]).to eq([bb_1, paired_bb])
          end
          expect(BillboardEvent.where(billboard_id: bb_1.id,      category: "impression").count).to eq(1)
          expect(BillboardEvent.where(billboard_id: paired_bb.id, category: "impression").count).to eq(1)
          # and it should *not* fire for the other_bb
          expect(BillboardEvent.where(billboard_id: other_bb.id).count).to eq(0)
        end
      end

      context "with AI summary experiment" do
        let(:smart_summary_service) { instance_double(Ai::EmailDigestSummary) }

        before do
          allow(FeatureFlag).to receive(:enabled?).with(:digest_smart_summary).and_return(true)
          allow(Ai::EmailDigestSummary).to receive(:new).and_return(smart_summary_service)
          allow(smart_summary_service).to receive(:generate).and_return("Smart AI Summary")
        end

        it "generates smart summary only when user has recent presence", :aggregate_failures do
          user.update_column(:last_presence_at, nil)
          worker.perform(user.id)
          expect(DigestMailer).to have_received(:with).with(hash_including(smart_summary: nil)).once

          user.update_column(:last_presence_at, 4.days.ago)
          worker.perform(user.id)
          expect(DigestMailer).to have_received(:with).with(hash_including(smart_summary: nil)).twice

          user.update_column(:last_presence_at, 1.day.ago)
          worker.perform(user.id)
          expect(DigestMailer).to have_received(:with).with(hash_including(smart_summary: "Smart AI Summary"))
        end
      end

      context "with force_send: true" do
        it "sends email even if user has email_digest_periodic disabled, unless user is not registered",
           :aggregate_failures do
          user.notification_setting.update_column(:email_digest_periodic, false)

          worker.perform(user.id, true)

          expect(DigestMailer).to have_received(:with).with(hash_including(user: user))
          expect(mailer).to have_received(:digest_email)
          expect(message_delivery).to have_received(:deliver_now)

          user.update_column(:registered, false)
          worker.perform(user.id, true)

          expect(DigestMailer).to have_received(:with).once
        end
      end

      context "with missing per-article AI summaries" do
        let(:article) do
          create(:article, user_id: author.id, public_reactions_count: 30, score: 30,
                           ai_summary: nil, ai_summary_generated_at: nil, with_tags: false, with_main_image: false)
        end
        let(:ai_generator) { instance_double(Ai::ArticleSummaryGenerator) }

        before do
          stub_collector_articles([article, stubbed_article])
          stub_const("Ai::Base::DEFAULT_KEY", "dummy_key")
          allow(Ai::ArticleSummaryGenerator).to receive(:new).and_return(ai_generator)
          allow(ai_generator).to receive(:call) do
            article.update_column(:ai_summary, "Generated inline summary")
          end
        end

        it "invokes the generator and updates the article in the email payload" do
          worker.perform(user.id)
          expect(Ai::ArticleSummaryGenerator).to have_received(:new)
          expect(ai_generator).to have_received(:call)

          expect(DigestMailer).to have_received(:with) do |args|
            delivered_article = args[:articles].detect { |a| a.id == article.id }
            expect(delivered_article.ai_summary).to eq("Generated inline summary")
          end
        end

        it "skips generation if Ai::Base::DEFAULT_KEY is missing" do
          stub_const("Ai::Base::DEFAULT_KEY", nil)
          worker.perform(user.id)
          expect(Ai::ArticleSummaryGenerator).not_to have_received(:new)
          expect(message_delivery).to have_received(:deliver_now)
        end

        it "rescues errors during generation and still delivers digest" do
          allow(ai_generator).to receive(:call).and_raise(StandardError.new("AI error"))
          allow(Rails.logger).to receive(:warn)
          allow(Rails.error).to receive(:report)

          worker.perform(user.id)

          expect(Rails.logger).to have_received(:warn)
            .with(/Failed to generate summary for article #{article.id} in digest: AI error/)
          expect(message_delivery).to have_received(:deliver_now)
        end

        it "uses a cache lock to prevent multiple attempts" do
          allow(Rails.cache).to receive(:write).and_call_original
          allow(Rails.cache).to receive(:write)
            .with("article_summary_attempt:#{article.id}", true, hash_including(unless_exist: true))
            .and_return(false)

          worker.perform(user.id)
          expect(Ai::ArticleSummaryGenerator).not_to have_received(:new)
          expect(message_delivery).to have_received(:deliver_now)
        end
      end

      context "with feed_config_id present" do
        let(:feed_config) { create(:feed_config) }

        it "creates FeedEvent impressions and refreshes counters through committed feedback" do
          articles = create_list(:article, 3, user_id: author.id, public_reactions_count: 20,
                                              score: 20, with_tags: false, with_main_image: false)
          stub_collector_articles(articles, feed_config_id: feed_config.id)
          allow(FeedEvents::BulkUpsert).to receive(:call).and_call_original
          allow(FeedEvents::FeedbackWorker).to receive(:perform_async) do |ids|
            FeedEvents::FeedbackWorker.new.perform(ids)
          end
          allow(FeedEvent).to receive(:update_single_feed_config_counters).and_call_original

          expect { worker.perform(user.id) }.to change(FeedEvent, :count).by(3)

          expect(FeedEvents::BulkUpsert).to have_received(:call).with(
            array_including(
              hash_including(
                article_id: kind_of(Integer),
                feed_config_id: feed_config.id,
                user_id: user.id,
                context_type: "email",
                category: "impression",
                article_position: kind_of(Integer),
              ),
            ),
          )
          expect(FeedEvent).to have_received(:update_single_feed_config_counters).with(feed_config.id)

          events = FeedEvent.where(feed_config_id: feed_config.id, category: "impression")
          expect(events.count).to eq(3)
          expect(events.pluck(:article_id, :article_position)).to match_array(
            articles.map.with_index(1) { |article, position| [article.id, position] },
          )
        end
      end

      context "when feed_config_id is nil" do
        it "does not create FeedEvent impressions" do
          expect { worker.perform(user.id) }.not_to change(FeedEvent, :count)
        end
      end
    end
  end
  # rubocop:enable RSpec/NestedGroups
end
