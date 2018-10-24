require "rails_helper"

RSpec.describe RateLimitChecker do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it ".limit_by_situation returns false for invalid case" do
    expect(described_class.new(user).limit_by_situation("random-nothing")).to eq(false)
  end

  it ".limit_by_situation returns true if too many comments at once" do
    create_list(:comment, 10, user_id: user.id, commentable_id: article.id)
    expect(described_class.new(user).limit_by_situation("comment_creation")).to eq(true)
  end

  it ".limit_by_situation returns false if allowed comment" do
    create_list(:comment, 2, user_id: user.id, commentable_id: article.id)
    expect(described_class.new(user).limit_by_situation("comment_creation")).to eq(false)
  end

  it ". limit_by_situation returns true if too many published articles at once" do
    create_list(:article, 10, user_id: user.id, published: true)
    expect(described_class.new(user).limit_by_situation("published_article_creation")).to eq(true)
  end

  it ".limit_by_situation returns false if published articles comment" do
    create_list(:article, 2, user_id: user.id, published: true)
    expect(described_class.new(user).limit_by_situation("published_article_creation")).to eq(false)
  end

  it ".limit_by_email_recipient_address returns true if too many published articles at once" do
    10.times do
      EmailMessage.create(to: user.email, sent_at: Time.current)
    end
    expect(described_class.new.limit_by_email_recipient_address(user.email)).to eq(true)
  end

  it ".limit_by_email_recipient_address returns false if published articles comment" do
    2.times do
      EmailMessage.create(to: user.email, sent_at: Time.current)
    end
    expect(described_class.new.limit_by_email_recipient_address(user.email)).to eq(false)
  end
end
