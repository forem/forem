require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/fix_negative_reaction_counters.rb",
)

RSpec.describe DataUpdateScripts::FixNegativeReactionCounters do
  it "fixes negative public_reactions_count on articles" do
    article = create(:article)
    # Force negative value bypassing validation (simulating the bug state)
    article.update_column(:public_reactions_count, -5)
    
    described_class.new.run
    
    article.reload
    expect(article.public_reactions_count).to be >= 0
    expect(article.public_reactions_count).to eq(article.reactions.public_category.count)
  end

  it "fixes negative public_reactions_count on comments" do
    comment = create(:comment)
    # Force negative value bypassing validation (simulating the bug state)
    comment.update_column(:public_reactions_count, -3)
    
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
    # Force negative value
    article.update_column(:public_reactions_count, -1)
    
    described_class.new.run
    
    article.reload
    expect(article.public_reactions_count).to eq(0)
  end

  it "handles comments with zero reactions correctly" do
    comment = create(:comment)
    # Force negative value
    comment.update_column(:public_reactions_count, -2)
    
    described_class.new.run
    
    comment.reload
    expect(comment.public_reactions_count).to eq(0)
  end

  it "processes multiple affected records in batches" do
    # Create several articles with negative counts
    articles = create_list(:article, 5)
    articles.each_with_index do |article, index|
      article.update_column(:public_reactions_count, -(index + 1))
    end
    
    described_class.new.run
    
    articles.each do |article|
      article.reload
      expect(article.public_reactions_count).to be >= 0
    end
  end
end
