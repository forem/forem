# spec/models/email_spec.rb
require "rails_helper"

RSpec.describe Email, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:audience_segment).optional }
  end

  describe "Callbacks" do
    it "registers #deliver_to_users as an after_commit callback" do
      # Verify the callback is registered in the chain
      # Note: checking private internal Rails structure is brittle but confirms configuration
      callback_names = Email._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:deliver_to_users)
    end
  end

  describe "#deliver_to_users" do
    let!(:user_with_notifications) { create(:user, :with_newsletters) }
    let!(:user_without_notifications) { create(:user, :without_newsletters) }

    before do
      allow(Emails::EnqueueCustomBatchSendWorker).to receive(:perform_async).and_return(true)
    end

    context "when type_of equals 'onboarding_drip'" do
      let(:email) { create(:email, type_of: "onboarding_drip") }

      it "does not enqueue any jobs to EnqueueCustomBatchSendWorker" do
        expect(Emails::EnqueueCustomBatchSendWorker).not_to receive(:perform_async)
        # Manually trigger since after_commit doesn't run in transactional tests
        email.deliver_to_users
      end
    end

    context "when status is not 'active'" do
      let(:email) { create(:email, status: "draft") }

      it "does not enqueue any jobs to EnqueueCustomBatchSendWorker" do
        expect(Emails::EnqueueCustomBatchSendWorker).not_to receive(:perform_async)
        email.deliver_to_users
      end
    end

    context "when status is changed from 'draft' to 'active'" do
      let(:email) { create(:email, status: "draft") }

      context "and max user ID is over 5000" do
        it "enqueues 24 jobs to EnqueueCustomBatchSendWorker" do
          allow(User).to receive(:maximum).with(:id).and_return(6000)

          email.update(status: "active")
          email.deliver_to_users

          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).exactly(24).times

          # Example assertions for boundaries
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 1, 250)
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 251, 500)
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).with(email.id, 5751,
                                                                                             6000)
        end

        it "only enqueues once even if re-saved" do
          allow(User).to receive(:maximum).with(:id).and_return(6000)

          email.update(status: "active")
          email.deliver_to_users
          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).exactly(24).times

          # Clear expectations
          RSpec::Mocks.space.proxy_for(Emails::EnqueueCustomBatchSendWorker).reset
          allow(Emails::EnqueueCustomBatchSendWorker).to receive(:perform_async)

          email.reload.save
          email.deliver_to_users
          expect(Emails::EnqueueCustomBatchSendWorker).not_to have_received(:perform_async)
        end
      end

      context "and max user ID is 5000 or less" do
        it "enqueues a single job to EnqueueCustomBatchSendWorker" do
          allow(User).to receive(:maximum).with(:id).and_return(5000)

          email.update(status: "active")
          email.deliver_to_users

          expect(Emails::EnqueueCustomBatchSendWorker).to have_received(:perform_async).once.with(email.id)
        end
      end
    end

    it "updates the email status to 'delivered'" do
      email = create(:email, status: "draft") # Start as draft
      email.update(status: "active") # Make it active/dirty
      email.deliver_to_users
      expect(email.reload.status).to eq("delivered")
    end
  end

  # The `#deliver_to_test_emails` method is unchanged
  # because it still calls `Emails::BatchCustomSendWorker`.
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
          contain_exactly(user_1.id, user_2.id),
          "[TEST] #{email.subject}",
          email.body,
          email.type_of,
          email.id,
          email.default_from_name_based_on_type,
        )
        email.deliver_to_test_emails(addresses_string)
      end
    end

    context "when no addresses are passed in but test_email_addresses is set" do
      let!(:user_1) { create(:user, email: "tester@example.com") }

      it "falls back to using test_email_addresses and enqueues a job" do
        email.test_email_addresses = "tester@example.com"
        # NOTE: match_array isn't strictly necessary for a single-element array,
        # but using it here for consistency is fine.
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(
          contain_exactly(user_1.id),
          "[TEST] #{email.subject}",
          email.body,
          email.type_of,
          email.id,
          email.default_from_name_based_on_type,
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
