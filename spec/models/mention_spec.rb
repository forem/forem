require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:user)        { create(:user) }
  let(:article)     { create(:article, user_id: user.id) }
  let(:comment)     { create(:comment, user_id: user.id, commentable_id: article.id) }

  before(:each) do
    #Run workers synchronously
    # Delayed::Worker.delay_jobs = false
  end

  it 'creates mention if there is a user mentioned' do
    comment.body_markdown = "Hello @#{user.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(1)
  end

  it 'deletes mention if deleted from comment' do
    comment.body_markdown = "Hello @#{user.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(1)
    comment.body_markdown = "Hello, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(0)
  end

  it 'creates one mention even if multiple mentions of same user' do
    comment.body_markdown = "Hello @#{user.username} @#{user.username} @#{user.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(1)
  end

  it 'creates multiple mentions for multiple users' do
    user_2 = create(:user)
    comment.body_markdown = "Hello @#{user.username} @#{user_2.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(2)
  end

  it 'deletes one of multiple mentions if one of multiple is deleted' do
    user_2 = create(:user)
    comment.body_markdown = "Hello @#{user.username} @#{user_2.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(2)
    comment.body_markdown = "Hello @#{user_2.username}, you are cool."
    comment.save
    Mention.create_all_without_delay(comment)
    expect(Mention.all.size).to eq(1)
  end

  it 'creates mention on creation of comment (in addition to update)' do
    comment_2 = create(:comment, body_markdown: "Hello @#{user.username}, you are cool.", commentable_id: article.id, user_id:user.id)
    Mention.create_all_without_delay(comment_2)
    expect(Mention.all.size).to eq(1)
  end

  it "can only be createdwith valid mentionable" do
    comment_2 = create(:comment, body_markdown: "Hello @#{user.username}, you are cool.", commentable_id: article.id, user_id:user.id)
    comment_2.update_column(:body_markdown, "")
    Mention.create_all_without_delay(comment_2)
    expect(Mention.all.size).to eq(0)
  end

end
