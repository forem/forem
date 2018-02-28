require 'rails_helper'

RSpec.describe RateLimitChecker do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  it "returns false for invalid case" do
    expect(RateLimitChecker.new(user).limit_by_situation("random-nothing")).to eq(false)
  end

  it "returns true if too many comments at once" do
    10.times do
      create(:comment, user_id: user.id, commentable_id: article.id)
    end
    expect(RateLimitChecker.new(user).limit_by_situation("comment_creation")).to eq(true)
  end
  it "returns false if allowed comment" do
    2.times do
      create(:comment, user_id: user.id, commentable_id: article.id)
    end
    expect(RateLimitChecker.new(user).limit_by_situation("comment_creation")).to eq(false)
  end

  it "returns true if too many published articles at once" do
    10.times do
      create(:article, user_id: user.id, published: true)
    end
    expect(RateLimitChecker.new(user).limit_by_situation("published_article_creation")).to eq(true)
  end
  it "returns false if published articles comment" do
    2.times do
      create(:article, user_id: user.id, published: true)
    end
    expect(RateLimitChecker.new(user).limit_by_situation("published_article_creation")).to eq(false)
  end

  it "returns true if too many published articles at once" do
    10.times do
      comment = create(:comment, user_id: user.id, commentable_id: article.id)
      EmailMessage.create(to: user.email, sent_at: Time.now)
    end
    expect(RateLimitChecker.new.limit_by_email_recipient_address(user.email)).to eq(true)
  end
  it "returns false if published articles comment" do
    2.times do
      EmailMessage.create(to: user.email, sent_at: Time.now)
    end
    expect(RateLimitChecker.new.limit_by_email_recipient_address(user.email)).to eq(false)
  end

end