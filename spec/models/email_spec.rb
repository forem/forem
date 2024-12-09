require "rails_helper"

RSpec.describe Email, type: :model do
  describe "Associations" do
    it { should belong_to(:audience_segment).optional }
  end

  describe "Callbacks" do
    it "calls #deliver_to_users after create" do
      email = build(:email)
      expect(email).to receive(:deliver_to_users)
      email.save
    end
  end

  describe "#deliver_to_users" do
    let!(:user_with_notifications) { create(:user, :with_newsletters) }
    let!(:user_without_notifications) { create(:user, :without_newsletters) }

    before do
      allow(Emails::BatchCustomSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when type_of equals 'onboarding_drip'" do
      let(:email) { create(:email, type_of: "onboarding_drip") }

      it "does not enqueue any jobs" do
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.send(:deliver_to_users)
      end
    end

    context "when status is not 'active'" do
      let(:email) { create(:email, status: "draft") }

      it "does not enqueue any jobs" do
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
      end
    end

    context "when status is changed from 'draft' to 'active'" do
      let(:email) { create(:email, status: "draft") }

      it "enqueues jobs" do
        email.update(status: "active")
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_with_notifications.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
      end

      it "Only enqueues once even if re-saved" do
        email.update(status: "active")
        email.reload.save
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_with_notifications.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        ).once
      end
    end

    context "when there is an audience segment" do
      let(:audience_segment) { create(:audience_segment) }
      let(:email) { create(:email, audience_segment: audience_segment) }

      before do
        # Allow audience_segment.users to return users that belong to the segment
        allow(audience_segment).to receive(:users).and_return(User.where(id: user_with_notifications.id))
        # Alternatively, you could also populate the database with relevant users
      end

      it "sends the emails to the users in the audience segment with email newsletters enabled" do
        email.send(:deliver_to_users)
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_with_notifications.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
      end
    end

    context "when there is no audience segment" do
      let(:email) { create(:email, audience_segment: nil) }

      before do
        # Mock User.registered scope to return only users with newsletters enabled
        allow(User).to receive(:registered).and_return(User.where(id: user_with_notifications.id))
      end

      it "sends the emails to all registered users with email newsletters enabled" do
        email.send(:deliver_to_users)
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          [user_with_notifications.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
      end
    end

    context "when no users have email newsletters enabled" do
      let(:email) { create(:email) }

      before do
        # Mock User.registered scope to return no users
        allow(User).to receive(:registered).and_return(User.none)
      end

      it "does not enqueue any jobs" do
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.send(:deliver_to_users)
      end
    end

    context "batch processing" do
      let(:email) { create(:email, audience_segment: nil) }

      it "processes users in batches" do
        batch_size = Email::BATCH_SIZE
        users_batch_1 = create_list(:user, batch_size, :with_newsletters)
        users_batch_2 = create_list(:user, batch_size, :with_newsletters)

        # Mock User.registered scope to return all users in two batches
        allow(User).to receive(:registered).and_return(User.where(id: users_batch_1.pluck(:id) + users_batch_2.pluck(:id)))
        email.send(:deliver_to_users)

        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          users_batch_1.map(&:id),
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        expect(Emails::BatchCustomSendWorker).to have_received(:perform_async).with(
          users_batch_2.map(&:id),
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
      end
    end
  end

  describe "#deliver_to_test_emails" do
    let(:email) { create(:email, subject: "Test Subject", body: "Test Body", type_of: "newsletter") }

    before do
      allow(Emails::BatchCustomSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when a list of addresses is provided" do
      let!(:user_1) { create(:user, email: "test1@example.com") }
      let!(:user_2) { create(:user, email: "test2@example.com") }

      it "enqueues a job with the matching users" do
        addresses_string = "test1@example.com, test2@example.com"
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(
          [user_1.id, user_2.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        email.deliver_to_test_emails(addresses_string)
      end
    end

    context "when no addresses are passed in but test_email_addresses is set" do
      let!(:user_1) { create(:user, email: "tester@example.com") }

      it "falls back to using test_email_addresses and enqueues a job" do
        email.test_email_addresses = "tester@example.com"
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(
          [user_1.id],
          email.subject,
          email.body,
          email.type_of,
          email.id
        )
        email.deliver_to_test_emails(nil)
      end
    end

    context "when the provided addresses do not match any user" do
      it "does not enqueue any jobs" do
        addresses_string = "nonexistent@example.com"
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.deliver_to_test_emails(addresses_string)
      end
    end

    context "when the addresses are blank" do
      it "does not enqueue any jobs" do
        expect(Emails::BatchCustomSendWorker).not_to receive(:perform_async)
        email.deliver_to_test_emails("")
      end
    end
  end
end
