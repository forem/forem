require "rails_helper"

RSpec.describe Spam::DomainDetector, type: :service do
  include ActiveJob::TestHelper
  let(:user) { create(:user, email: "test@example.com") }
  let(:detector) { described_class.new(user) }

  describe "#check_and_block_domain!" do
    context "when domain should be skipped" do
      let(:user) { create(:user, email: "test@gmail.com") }

      it "returns false and does not block domain" do
        expect(detector.check_and_block_domain!).to be false
        expect(BlockedEmailDomain.where(domain: "gmail.com")).to be_empty
      end
    end

    context "when spam pattern is detected" do
      let!(:spam_user1) { create(:user, email: "user1@example.com") }
      let!(:spam_user2) { create(:user, email: "user2@example.com") }
      let!(:spam_user3) { create(:user, email: "user3@example.com") }

      before do
        # Make the spam users have spam/suspended roles and register them recently
        [spam_user1, spam_user2, spam_user3].each do |spam_user|
          spam_user.add_role(:spam)
          spam_user.update!(registered_at: 1.week.ago, created_at: 1.week.ago)
        end
        
        # Make sure the current user is also registered recently
        user.update!(registered_at: 1.week.ago, created_at: 1.week.ago)
      end

      it "enqueues background job to block domain and suspend users" do
        expect { detector.check_and_block_domain! }.to change { Spam::BlockDomainAndSuspendUsersWorker.jobs.size }.by(1)
        
        # Check that the job was enqueued with correct arguments
        last_job = Spam::BlockDomainAndSuspendUsersWorker.jobs.last
        expect(last_job["args"]).to eq(["example.com"])
      end

      it "enqueues job with correct domain" do
        expect { detector.check_and_block_domain! }.to change { Spam::BlockDomainAndSuspendUsersWorker.jobs.size }.by(1)
        
        # Check that the job was enqueued with correct arguments
        last_job = Spam::BlockDomainAndSuspendUsersWorker.jobs.last
        expect(last_job["args"]).to eq(["example.com"])
      end
    end

    context "when there are legitimate users with the same email" do
      let!(:spam_user1) { create(:user, email: "user1@example.com") }
      let!(:spam_user2) { create(:user, email: "user2@example.com") }
      let!(:spam_user3) { create(:user, email: "user3@example.com") }
      let!(:legitimate_user) { create(:user, email: "legitimate@example.com") }

      before do
        # Make the spam users have spam/suspended roles
        [spam_user1, spam_user2, spam_user3].each do |spam_user|
          spam_user.add_role(:spam)
          spam_user.update!(registered_at: 1.week.ago, created_at: 1.week.ago)
        end
        
        # Make the legitimate user older
        legitimate_user.update!(registered_at: 1.month.ago, created_at: 1.month.ago)
      end

      it "does not block the domain when legitimate users exist" do
        expect(detector.check_and_block_domain!).to be false
        expect(BlockedEmailDomain.where(domain: "example.com")).to be_empty
      end
    end

    context "when there are not enough spam users" do
      let!(:spam_user1) { create(:user, email: "user1@example.com") }
      let!(:spam_user2) { create(:user, email: "user2@example.com") }

      before do
        [spam_user1, spam_user2].each do |spam_user|
          spam_user.add_role(:spam)
          spam_user.update!(registered_at: 1.week.ago, created_at: 1.week.ago)
        end
      end

      it "does not block the domain when there are only 2 spam users" do
        expect(detector.check_and_block_domain!).to be false
        expect(BlockedEmailDomain.where(domain: "example.com")).to be_empty
      end
    end

    context "when spam users are older than 2 weeks" do
      let!(:spam_user1) { create(:user, email: "user1@example.com") }
      let!(:spam_user2) { create(:user, email: "user2@example.com") }
      let!(:spam_user3) { create(:user, email: "user3@example.com") }

      before do
        [spam_user1, spam_user2, spam_user3].each do |spam_user|
          spam_user.add_role(:spam)
          spam_user.update!(registered_at: 1.month.ago, created_at: 1.month.ago)
        end
      end

      it "does not block the domain when spam users are too old" do
        expect(detector.check_and_block_domain!).to be false
        expect(BlockedEmailDomain.where(domain: "example.com")).to be_empty
      end
    end
  end

  describe "#should_skip_domain?" do
    it "skips popular shared domains" do
      popular_domains = %w[gmail.com yahoo.com hotmail.com outlook.com]
      
      popular_domains.each do |domain|
        user = create(:user, email: "test@#{domain}")
        detector = described_class.new(user)
        expect(detector.send(:should_skip_domain?)).to be true
      end
    end

    it "does not skip custom domains" do
      user = create(:user, email: "test@customdomain.com")
      detector = described_class.new(user)
      expect(detector.send(:should_skip_domain?)).to be false
    end
  end

  describe "#extract_domain" do
    it "extracts domain from email" do
      user = create(:user, email: "test@example.com")
      detector = described_class.new(user)
      expect(detector.send(:extract_domain, "test@example.com")).to eq("example.com")
    end

    it "handles uppercase emails" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      detector = described_class.new(user)
      expect(detector.send(:extract_domain, "TEST@EXAMPLE.COM")).to eq("example.com")
    end

    it "returns nil for blank emails" do
      user = create(:user, email: nil)
      detector = described_class.new(user)
      expect(detector.send(:extract_domain, "")).to be_nil
      expect(detector.send(:extract_domain, nil)).to be_nil
    end
  end
end
