require "rails_helper"

RSpec.describe Mention do
  describe ".create_all" do
    let(:comment) { create(:comment, commentable: create(:podcast_episode)) }

    it "enqueues a job to default queue" do
      expect do
        described_class.create_all(comment)
      end.to change(Mentions::CreateAllWorker.jobs, :size).by(1)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:mentionable_type) }

    context "when validating uniqueness of user_id" do
      let(:user) { create(:user) }
      let(:mention) { create(:mention, user: user) }

      it "is scoped to mentionable_id and mentionable_type" do
        duplicate_mention = build(:mention, user: user, mentionable: mention.mentionable)

        expect(duplicate_mention).not_to be_valid
      end

      it "allows the same user_id for different mentionable_id and mentionable_type" do
        other_mention = build(:mention, user: user)

        expect(other_mention).to be_valid
      end
    end

    context "when mentionable is invalid" do
      let(:comment) { build(:comment, commentable: nil) }

      it "is invalid" do
        mention = build(:mention, mentionable: comment)

        expect(mention).not_to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:mentionable) }
  end

  describe "callbacks" do
    let(:mention) { build(:mention) }

    it "enqueues SendEmailNotificationWorker after create" do
      allow(Mentions::SendEmailNotificationWorker).to receive(:perform_async)

      mention.save

      expect(Mentions::SendEmailNotificationWorker).to have_received(:perform_async).with(mention.id)
    end
  end
end
