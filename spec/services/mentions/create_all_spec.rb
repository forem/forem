require "rails_helper"

RSpec.describe Mentions::CreateAll, type: :service do
  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let(:article)     { create(:article, user_id: user.id) }
  let(:comment)     { create(:comment, user_id: user2.id, commentable: article) }
  let(:comment2)    do
    create(
      :comment,
      body_markdown: "Hello @#{user.username}, you are cool.",
      user_id: user2.id,
      commentable: article,
    )
  end

  it "creates mention if there is a user mentioned and if the user doenst own the comment" do
    comment.body_markdown = "Hello @#{user.username}, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(1)
  end

  it "deletes mention if deleted from comment" do
    comment.body_markdown = "Hello @#{user.username}, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(1)
    comment.body_markdown = "Hello, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(0)
  end

  it "creates one mention even if multiple mentions of same user" do
    comment.body_markdown = "Hello @#{user.username} @#{user.username} @#{user.username}, you rock."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(1)
  end

  it "creates multiple mentions for multiple users" do
    user2 = create(:user)
    comment.body_markdown = "Hello @#{user.username} @#{user2.username}, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(2)
  end

  it "deletes one of multiple mentions if one of multiple is deleted" do
    user2 = create(:user)
    comment.body_markdown = "Hello @#{user.username} @#{user2.username}, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(2)
    comment.body_markdown = "Hello @#{user2.username}, you are cool."
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(1)
  end

  it "creates mention on creation of comment (in addition to update)" do
    described_class.call(comment2)
    expect(Mention.all.size).to eq(1)
  end

  it "can only be created with valid mentionable" do
    comment2.update_column(:body_markdown, "")
    described_class.call(comment2)
    expect(Mention.all.size).to eq(0)
  end

  it "cant mention self" do
    comment.body_markdown = "Me, Myself and I @#{user2.username}"
    comment.save
    described_class.call(comment)
    expect(Mention.all.size).to eq(0)
  end
end
