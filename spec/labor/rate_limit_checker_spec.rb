require "rails_helper"

RSpec.describe RateLimitChecker do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  describe "#limit_by_action" do
    it "returns false for invalid action" do
      expect(described_class.new(user).limit_by_action("random-nothing")).to eq(false)
    end

    it "returns true if too many comments at once" do
      create_list(:comment, 10, user_id: user.id, commentable_id: article.id)
      expect(described_class.new(user).limit_by_action("comment_creation")).to eq(true)
    end

    it "triggers ping admin when too many comments" do
      allow(RateLimitCheckerJob).to receive(:perform_later)
      create_list(:comment, 10, user_id: user.id, commentable_id: article.id)
      described_class.new(user).limit_by_action("comment_creation")
      expect(RateLimitCheckerJob).to have_received(:perform_later).with(user.id, "comment_creation")
    end

    it "returns false if allowed comment" do
      create_list(:comment, 2, user_id: user.id, commentable_id: article.id)
      expect(described_class.new(user).limit_by_action("comment_creation")).to eq(false)
    end

    it "returns true if too many published articles at once" do
      create_list(:article, 10, user_id: user.id, published: true)
      expect(described_class.new(user).limit_by_action("published_article_creation")).to eq(true)
    end

    it "returns false if published articles comment" do
      create_list(:article, 2, user_id: user.id, published: true)
      expect(described_class.new(user).limit_by_action("published_article_creation")).to eq(false)
    end
  end

  describe "#limit_by_email_recipient_address" do
    it "returns true if too many published articles at once" do
      10.times { EmailMessage.create(to: user.email, sent_at: Time.current) }
      expect(described_class.new.limit_by_email_recipient_address(user.email)).to eq(true)
    end

    it "returns false if published articles comment" do
      2.times { EmailMessage.create(to: user.email, sent_at: Time.current) }
      expect(described_class.new.limit_by_email_recipient_address(user.email)).to eq(false)
    end
  end
end
