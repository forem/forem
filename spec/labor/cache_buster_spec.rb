require 'rails_helper'

RSpec.describe CacheBuster do
  let(:user) {create(:user)}
  let(:article) {create(:article,user_id:user.id)}
  let(:comment) {create(:comment, user_id: user.id,commentable_id: article.id)}
  it 'should bust comment' do
    CacheBuster.new.bust_comment(comment)
  end
  it 'should bust article' do
    CacheBuster.new.bust_article(article)
  end
  it 'should bust featured article' do
    article.featured = true
    article.save
    CacheBuster.new.bust_article(article)
  end
end
