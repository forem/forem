require "rails_helper"

RSpec.describe AgentSessions::CleanupExpiredRawFilesWorker, type: :worker do
  let(:user) { create(:user) }

  def create_session(created_at:, s3_key: "agent_sessions/#{user.id}/#{SecureRandom.uuid}.jsonl")
    create(:agent_session, user: user, s3_key: s3_key, created_at: created_at)
  end

  before do
    allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(true)
    allow(AgentSessions::S3Storage).to receive(:delete)
  end

  describe "#perform" do
    it "deletes S3 objects and nils s3_key for expired sessions" do
      expired = create_session(created_at: 91.days.ago)

      described_class.new.perform

      expect(AgentSessions::S3Storage).to have_received(:delete).with(expired.s3_key)
      expect(expired.reload.s3_key).to be_nil
    end

    it "does not touch sessions within the retention window" do
      recent = create_session(created_at: 89.days.ago)

      described_class.new.perform

      expect(AgentSessions::S3Storage).not_to have_received(:delete)
      expect(recent.reload.s3_key).to be_present
    end

    it "does not touch sessions without s3_key" do
      create(:agent_session, user: user, s3_key: nil, created_at: 91.days.ago)

      described_class.new.perform

      expect(AgentSessions::S3Storage).not_to have_received(:delete)
    end

    it "skips when S3 is not enabled" do
      allow(AgentSessions::S3Storage).to receive(:enabled?).and_return(false)
      create_session(created_at: 91.days.ago)

      described_class.new.perform

      expect(AgentSessions::S3Storage).not_to have_received(:delete)
    end

    it "continues processing if one deletion fails" do
      expired1 = create_session(created_at: 100.days.ago)
      expired2 = create_session(created_at: 95.days.ago)

      allow(AgentSessions::S3Storage).to receive(:delete).with(expired1.s3_key).and_raise(StandardError, "S3 error")
      allow(AgentSessions::S3Storage).to receive(:delete).with(expired2.s3_key)

      described_class.new.perform

      expect(expired1.reload.s3_key).to be_present # failed, kept
      expect(expired2.reload.s3_key).to be_nil # succeeded, cleared
    end
  end
end
