require "rails_helper"

RSpec.describe MentionDecorator, type: :decorator do
  let(:user) { create(:user) }

  describe "#formatted_mentionable_type" do
    let(:article) { create(:article) }
    let(:comment) { create(:comment, user_id: user.id, commentable: article) }

    it "returns the correct mentionable type for mentions on articles" do
      mention = create(:mention, mentionable: article, user: user).decorate
      expect(mention.decorate.formatted_mentionable_type).to eq("post")
    end

    it "returns the correct mentionable type for mentions on comments" do
      mention = create(:mention, mentionable: comment, user: user).decorate
      expect(mention.decorate.formatted_mentionable_type).to eq("comment")
    end
  end

  describe "#mentioned_by_blocked_user?" do
    let(:blocked_user) { create(:user) }
    let(:mention) { create(:mention, mentionable: user, user: blocked_user) }

    it "returns true if mentioned user has blocked the mentioner" do
      create(:user_block, blocker: user, blocked: blocked_user, config: "default")

      expect(mention.decorate.mentioned_by_blocked_user?).to be(true)
    end

    it "returns false if mentioned user has not blocked the mentioner" do
      expect(mention.decorate.mentioned_by_blocked_user?).to be(false)
    end
  end
end
