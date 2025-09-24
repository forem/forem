require "rails_helper"

RSpec.describe "User spam detection", type: :model do
  describe "spam detection callback" do
    let(:user) { create(:user, email: "test@spamdomain.com") }
    let!(:spam_user1) { create(:user, email: "user1@spamdomain.com", created_at: 1.week.ago) }
    let!(:spam_user2) { create(:user, email: "user2@spamdomain.com", created_at: 1.week.ago) }
    let!(:spam_user3) { create(:user, email: "user3@spamdomain.com", created_at: 1.week.ago) }

    before do
      # Set up spam users with spam roles
      [spam_user1, spam_user2, spam_user3].each do |spam_user|
        spam_user.add_role(:spam)
        spam_user.update!(registered_at: 1.week.ago, updated_at: 1.week.ago)
      end
    end

    context "when user gets spam role" do
      it "triggers spam detection" do
        expect_any_instance_of(Spam::DomainDetector).to receive(:check_and_block_domain!)
        
        user.add_role(:spam)
      end
    end

    context "when user gets suspended role" do
      it "triggers spam detection" do
        expect_any_instance_of(Spam::DomainDetector).to receive(:check_and_block_domain!)
        
        user.add_role(:suspended)
      end
    end

    context "when user gets other roles" do
      it "does not trigger spam detection" do
        expect_any_instance_of(Spam::DomainDetector).not_to receive(:check_and_block_domain!)
        
        user.add_role(:trusted)
      end
    end

    context "when domain should be skipped" do
      let(:user) { create(:user, email: "test@gmail.com") }

      it "does not block popular domains" do
        expect { user.add_role(:spam) }.not_to change { BlockedEmailDomain.count }
      end
    end
  end
end
