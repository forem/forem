# spec/workers/emails/enqueue_custom_batch_send_worker_spec.rb
require "rails_helper"

RSpec.describe Emails::EnqueueCustomBatchSendWorker, type: :worker do
  describe "#perform" do
    let(:email) { create(:email, subject: "Subject", body: "Body", type_of: "newsletter", status: "active") }

    before do
      allow(Emails::BatchCustomSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when email has an audience segment" do
      let!(:audience_segment) { create(:audience_segment) }
      let!(:email) { create(:email, subject: "Segmented", audience_segment: audience_segment) }
      let!(:user_in_segment) { create(:user, :with_newsletters) }
      let!(:user_outside_segment) { create(:user, :with_newsletters) }

      before do
        audience_segment.segmented_users.create!(user: user_in_segment)
        # Stub out the segment to return only user_in_segment
        allow(audience_segment).to receive(:users).and_return(User.where(id: user_in_segment.id))
      end

      it "uses the segment scope and enqueues BatchCustomSendWorker for those users" do
        described_class.new.perform(email.id)
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_in_segment.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async).with(
          [user_outside_segment.id],
          anything,
          anything,
          anything,
          anything
        )
      end
    end

    context "when email does not have an audience segment" do
      let(:email) { create(:email, audience_segment: nil) }
      let!(:user_with_notifications) { create(:user, :with_newsletters) }
      let!(:user_without_notifications) { create(:user, :without_newsletters) }

      it "uses the default scope and enqueues BatchCustomSendWorker only for users with newsletters enabled" do
        described_class.new.perform(email.id)
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_with_notifications.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        # user_without_notifications.id should not be in the arguments
      end
    end

    context "when email has targeted_tags" do
      let!(:tag) { create(:tag, name: "scrud") }
      let!(:email) { create(:email, targeted_tags: "scrud") }

      let!(:user_following_ruby) do
        create(:user, :with_newsletters).tap do |u|
          Follow.create!(
            follower_id: u.id,
            follower_type: "User",
            followable_id: tag.id,
            followable_type: "ActsAsTaggableOn::Tag"
          )
        end
      end

      let!(:user_not_following_ruby) { create(:user, :with_newsletters) }

      it "only includes users following the specified tags" do
        described_class.new.perform(email.id)
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_following_ruby.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        # Ensure user_not_following_ruby is excluded
        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async).with(
          include(user_not_following_ruby.id), anything, anything, anything, anything
        )
      end

      context "with multiple tags" do
        let!(:tag_rails) { create(:tag, name: "scruff") }
        let!(:email) { create(:email, targeted_tags: "scrud,scruff") }

        let!(:user_following_both) do
          create(:user, :with_newsletters).tap do |u|
            [tag, tag_rails].each do |tg|
              Follow.create!(
                follower_id: u.id,
                follower_type: "User",
                followable_id: tg.id,
                followable_type: "ActsAsTaggableOn::Tag"
              )
            end
          end
        end

        let!(:user_following_only_ruby) do
          create(:user, :with_newsletters).tap do |u|
            Follow.create!(
              follower_id: u.id,
              follower_type: "User",
              followable_id: tag.id,
              followable_type: "ActsAsTaggableOn::Tag"
            )
          end
        end

        it "includes users following any of the specified tags" do
          described_class.new.perform(email.id)
          create(:user, :with_newsletters).tap do |u|
            Follow.create!(
              follower_id: u.id,
              follower_type: "User",
              followable_id: tag_rails.id,
              followable_type: "ActsAsTaggableOn::Tag"
            )
          end

          # We expect both user_following_both and user_following_only_ruby to be included
          expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
            match_array([user_following_ruby.id, user_following_both.id, user_following_only_ruby.id]),
            email.subject,
            email.body,
            email.type_of,
            email.id
          )
        end
      end
    end

    context "when there are more users than BATCH_SIZE" do
      before do
        # Suppose it's non-production environment => BATCH_SIZE = 10
        @batch_size = described_class::BATCH_SIZE
        create_list(:user, @batch_size, :with_newsletters)
        create_list(:user, 5, :with_newsletters)
      end

      it "sends multiple batches to BatchCustomSendWorker" do
        described_class.new.perform(email.id)
        # We expect two sets of arguments:
        #  1) first 10 user IDs
        #  2) next 5 user IDs
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).exactly(2).times
      end
    end

    context "when no users match the scope" do
      it "does not enqueue any jobs" do
        described_class.new.perform(email.id)
        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async)
      end
    end

    context "when in non-production environment" do
      it "uses BATCH_SIZE = 10" do
        allow(Rails.env).to receive(:production?).and_return(false)
        expect(described_class::BATCH_SIZE).to eq(10)
      end
    end

    context "when users are suspended or spam" do
      let!(:user_suspended) do
        create(:user, :with_newsletters).tap { |u| u.add_role(:suspended) }
      end
      let!(:user_spam) do
        create(:user, :with_newsletters).tap { |u| u.add_role(:spam) }
      end
      let!(:user_regular) { create(:user, :with_newsletters) }

      it "excludes those users from the scope" do
        described_class.new.perform(email.id)

        # The only user who should be enqueued is user_regular
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_regular.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )

        # Check that suspended or spam users were not passed
        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async).with(
          include(user_suspended.id), anything, anything, anything, anything
        )
        expect(Emails::BatchCustomSendWorker).not_to have_received(:perform_async).with(
          include(user_spam.id), anything, anything, anything, anything
        )
      end
    end
  end
end
