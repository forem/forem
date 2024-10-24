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
    let(:user_with_notifications) { create(:user, :registered, :with_newsletters) }
    let(:user_without_notifications) { create(:user, :registered, :without_newsletters) }

    context "when there is an audience segment" do
      let(:audience_segment) { create(:audience_segment) }
      let(:email) { create(:email, audience_segment: audience_segment) }

      before do
        allow(audience_segment).to receive_message_chain(:users, :registered, :joins, :where, :where_not).and_return([user_with_notifications])
      end

      it "sends the emails to the users in the audience segment with email newsletters enabled" do
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with([user_with_notifications.id])
        email.send(:deliver_to_users)
      end
    end

    context "when there is no audience segment" do
      let(:email) { create(:email, audience_segment: nil) }

      before do
        allow(User).to receive_message_chain(:registered, :joins, :where, :where_not).and_return([user_with_notifications])
      end

      it "sends the emails to all registered users with email newsletters enabled" do
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with([user_with_notifications.id])
        email.send(:deliver_to_users)
      end
    end

    context "when no users have email newsletters enabled" do
      let(:email) { create(:email) }

      before do
        allow(User).to receive_message_chain(:registered, :joins, :where, :where_not).and_return([])
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
        users_batch_1 = create_list(:user, batch_size, :registered, :with_newsletters)
        users_batch_2 = create_list(:user, batch_size, :registered, :with_newsletters)

        allow(User).to receive_message_chain(:registered, :joins, :where, :where_not).and_return(users_batch_1 + users_batch_2)

        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(users_batch_1.map(&:id))
        expect(Emails::BatchCustomSendWorker).to receive(:perform_async).with(users_batch_2.map(&:id))

        email.send(:deliver_to_users)
      end
    end
  end
end
