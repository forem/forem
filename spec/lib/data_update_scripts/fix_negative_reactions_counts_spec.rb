require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/fix_negative_reaction_counters.rb",
)

RSpec.describe DataUpdateScripts::FixNegativeReactionCounters do
  def stub_negative_articles_scope(articles)
    relation = instance_double(ActiveRecord::Relation)
    allow(relation).to receive(:find_in_batches).with(batch_size: 100).and_yield(articles)
    allow(relation).to receive(:count).and_return(articles.size)
    allow(Article).to receive(:where).with("public_reactions_count < 0").and_return(relation)
  end

  def stub_negative_comments_scope(comments)
    relation = instance_double(ActiveRecord::Relation)
    allow(relation).to receive(:find_in_batches).with(batch_size: 100).and_yield(comments)
    allow(relation).to receive(:count).and_return(comments.size)
    allow(Comment).to receive(:where).with("public_reactions_count < 0").and_return(relation)
  end

  it "fixes negative public_reactions_count on articles" do
    article = create(:article)
    create(:reaction, reactable: article, category: "like")
    article.update_column(:public_reactions_count, 0)

    stub_negative_articles_scope([article])

    described_class.new.run

    article.reload
    expect(article.public_reactions_count).to be >= 0
    expect(article.public_reactions_count).to eq(article.reactions.public_category.count)
  end

  it "fixes negative public_reactions_count on comments" do
    comment = create(:comment)
    create(:reaction, reactable: comment, category: "like")
    comment.update_column(:public_reactions_count, 0)

    stub_negative_comments_scope([comment])

    described_class.new.run

    comment.reload
    expect(comment.public_reactions_count).to be >= 0
    expect(comment.public_reactions_count).to eq(comment.reactions.public_category.count)
  end

  it "does not modify articles with correct positive counts" do
    article = create(:article)
    create(:reaction, reactable: article, category: "like")
    article.reload
    original_count = article.public_reactions_count

    described_class.new.run

    article.reload
    expect(article.public_reactions_count).to eq(original_count)
  end

  it "handles articles with zero reactions correctly" do
    article = create(:article)
    article.update_column(:public_reactions_count, 0)

    stub_negative_articles_scope([article])

    described_class.new.run

    article.reload
    expect(article.public_reactions_count).to eq(0)
  end

  it "handles comments with zero reactions correctly" do
    comment = create(:comment)
    comment.update_column(:public_reactions_count, 0)

    stub_negative_comments_scope([comment])

    described_class.new.run

    comment.reload
    expect(comment.public_reactions_count).to eq(0)
  end

  it "processes multiple affected records in batches" do
    articles = create_list(:article, 5)
    articles.each do |article|
      article.update_column(:public_reactions_count, 0)
    end

    stub_negative_articles_scope(articles)

    described_class.new.run

    articles.each do |article|
      article.reload
      expect(article.public_reactions_count).to be >= 0
    end
  end
end
