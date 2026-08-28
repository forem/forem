require "rails_helper"

RSpec.describe Users::NotificationSetting do
  let!(:user) { create(:user) }
  let(:notification_setting) { user.notification_setting.reload }

  context "when callbacks are triggered after commit" do
    describe "subscribing to mailchimp newsletter" do
      it "enqueues SubscribeToMailchimpNewsletterWorker when updating email_newsletter to true" do
        sidekiq_assert_enqueued_with(job: Users::SubscribeToMailchimpNewsletterWorker, args: [user.id]) do
          notification_setting.update(email_newsletter: true)
        end
      end

      it "enqueues SubscribeToMailchimpNewsletterWorker when updating email_newsletter to false" do
        notification_setting.update(email_newsletter: true)
        sidekiq_assert_enqueued_jobs(1, only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: false)
        end
      end

      it "does not enqueue if email is not set" do
        user.update(email: "")
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: !notification_setting.email_newsletter)
        end
      end

      it "does not enqueue if Mailchimp is not enabled" do
        allow(Settings::General).to receive(:mailchimp_api_key).and_return(nil)
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: !notification_setting.email_newsletter)
        end
      end

      it "does not enqueue without updating email_newsletter" do
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_badge_notifications: !notification_setting.email_badge_notifications)
        end
      end
    end
  end

  describe "email consent events for the DEV → Core sync" do
    before do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
      Settings::General.customerio_cdp_enabled = true
      FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[user])
    end

    after { FeatureFlag.remove(:dev_core_user_sync) }

    around { |ex| with_trackable_events { ex.run } }

    it "emits user_newsletter_subscribed when email_newsletter flips on" do
      notification_setting.update!(email_newsletter: true)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_subscribed", [user.id], anything, anything)
    end

    it "emits user_newsletter_unsubscribed when email_newsletter flips off" do
      notification_setting.update!(email_newsletter: true)
      notification_setting.update!(email_newsletter: false)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_unsubscribed", [user.id], anything, anything)
    end

    it "does not emit for a setting outside the email consents Core mirrors" do
      notification_setting.update!(reaction_notifications: !notification_setting.reaction_notifications)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end

    # The digest is a separate consent from the newsletter: EmailDigest selects
    # on email_digest_periodic alone, so Core needs its own signal for it.
    it "emits user_digest_subscribed when email_digest_periodic flips on" do
      notification_setting.update!(email_digest_periodic: true)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_digest_subscribed", [user.id], anything, anything)
    end

    it "emits user_digest_unsubscribed when email_digest_periodic flips off" do
      notification_setting.update!(email_digest_periodic: true)
      notification_setting.update!(email_digest_periodic: false)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_digest_unsubscribed", [user.id], anything, anything)
    end

    it "does not emit a digest event when only the newsletter changes" do
      notification_setting.update!(email_newsletter: true)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
        .with(anything, /user_digest/, anything, anything, anything)
    end

    it "emits both events when one save flips newsletter and digest together" do
      notification_setting.update!(email_newsletter: true, email_digest_periodic: true)

      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_subscribed", [user.id], anything, anything)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_digest_subscribed", [user.id], anything, anything)
    end

    # Core matches these two names exactly on the wire. Deriving them from the
    # column name instead (user_email_newsletter_*, user_email_digest_periodic_*)
    # would silently break live consent sync for every existing subscriber.
    it "keeps the two pre-existing event names byte-identical to the column-agnostic originals" do
      notification_setting.update!(email_newsletter: true, email_digest_periodic: true)

      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_subscribed", [user.id], anything, anything)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_digest_subscribed", [user.id], anything, anything)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
        .with(anything, a_string_matching(/\Auser_email_/), anything, anything, anything)
    end

    # The five settings below have Customer.io subscription topics on the Core
    # side but emitted no signal at all, so Core could never learn their state.
    {
      email_comment_notifications: "user_comment_notifications",
      email_follower_notifications: "user_follower_notifications",
      email_mention_notifications: "user_mention_notifications",
      email_unread_notifications: "user_unread_notifications",
      email_badge_notifications: "user_badge_notifications"
    }.each do |column, event_prefix|
      it "emits #{event_prefix}_unsubscribed when #{column} flips off" do
        notification_setting.update!(column => false)

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "#{event_prefix}_unsubscribed", [user.id], anything, anything)
      end

      it "emits #{event_prefix}_subscribed when #{column} flips back on" do
        notification_setting.update!(column => false)
        notification_setting.update!(column => true)

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "#{event_prefix}_subscribed", [user.id], anything, anything)
      end

      it "does not emit #{event_prefix} events when an unrelated consent changes" do
        notification_setting.update!(email_newsletter: true)

        expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
          .with(anything, a_string_starting_with(event_prefix), anything, anything, anything)
      end
    end

    # Role-driven newsletters: DEV grants/removes them with the moderator role
    # and the user can switch them off; Core mirrors them onto its own
    # newsletter keys so Customer.io can send them, but never writes them back.
    {
      email_tag_mod_newsletter: "user_tag_mod_newsletter",
      email_community_mod_newsletter: "user_community_mod_newsletter"
    }.each do |column, event_prefix|
      it "emits #{event_prefix}_subscribed when #{column} flips on (role granted)" do
        notification_setting.update!(column => true)

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "#{event_prefix}_subscribed", [user.id], anything, anything)
      end

      it "emits #{event_prefix}_unsubscribed when #{column} flips off (role removed or user opts out)" do
        notification_setting.update!(column => true)
        notification_setting.update!(column => false)

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "#{event_prefix}_unsubscribed", [user.id], anything, anything)
      end

      it "keeps #{column} out of the admin-API writable set" do
        expect(described_class::CORE_SYNCED_EMAIL_SETTINGS).not_to include(column)
        expect(described_class::ROLE_DRIVEN_NEWSLETTER_SETTINGS).to include(column)
      end
    end

    it "emits one event per flipped consent when a single save changes several" do
      notification_setting.update!(email_newsletter: true, email_comment_notifications: false,
                                   email_badge_notifications: false)

      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_subscribed", [user.id], anything, anything)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_comment_notifications_unsubscribed", [user.id], anything, anything)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_badge_notifications_unsubscribed", [user.id], anything, anything)
    end

    it "does not emit when the sync gates are off" do
      Settings::General.customerio_cdp_enabled = false
      notification_setting.update!(email_newsletter: true)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end
  end
end
