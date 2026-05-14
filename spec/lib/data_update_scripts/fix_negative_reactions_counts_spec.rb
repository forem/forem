require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/fix_negative_reaction_counters.rb",
)

RSpec.describe DataUpdateScripts::FixNegativeReactionCounters do
  # Helper to bypass check constraints for testing purposes
  def set_counter_value(record, value)
    record.class.where(id: record.id).update_all(public_reactions_count: value)
    record.reload
  end

  it "fixes negative public_reactions_count on articles" do
    article = create(:article)
    create(:reaction, reactable: article, category: "like")
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    set_counter_value(article, -5)
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0) NOT VALID")

   described_class.new.run

    article.reload
    expect(article.public_reactions_count).to be >= 0
    expect(article.public_reactions_count).to eq(article.reactions.public_category.count)
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0)")
  end

  it "fixes negative public_reactions_count on comments" do
    comment = create(:comment)
    create(:reaction, reactable: comment, category: "like")
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute("ALTER TABLE comments DROP CONSTRAINT IF EXISTS check_comments_public_reactions_count_non_negative")
    set_counter_value(comment, -3)
    ActiveRecord::Base.connection.execute("ALTER TABLE comments ADD CONSTRAINT check_comments_public_reactions_count_non_negative CHECK (public_reactions_count >= 0) NOT VALID")

    described_class.new.run

    comment.reload
    expect(comment.public_reactions_count).to be >= 0
    expect(comment.public_reactions_count).to eq(comment.reactions.public_category.count)
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE comments DROP CONSTRAINT IF EXISTS check_comments_public_reactions_count_non_negative")
    ActiveRecord::Base.connection.execute("ALTER TABLE comments ADD CONSTRAINT check_comments_public_reactions_count_non_negative CHECK (public_reactions_count >= 0)")
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
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    set_counter_value(article, -1)
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0) NOT VALID")

    described_class.new.run

    article.reload
    expect(article.public_reactions_count).to eq(0)
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0)")
  end

  it "handles comments with zero reactions correctly" do
    comment = create(:comment)
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute("ALTER TABLE comments DROP CONSTRAINT IF EXISTS check_comments_public_reactions_count_non_negative")
    set_counter_value(comment, -2)
    ActiveRecord::Base.connection.execute("ALTER TABLE comments ADD CONSTRAINT check_comments_public_reactions_count_non_negative CHECK (public_reactions_count >= 0) NOT VALID")

    described_class.new.run

    comment.reload
    expect(comment.public_reactions_count).to eq(0)
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE comments DROP CONSTRAINT IF EXISTS check_comments_public_reactions_count_non_negative")
    ActiveRecord::Base.connection.execute("ALTER TABLE comments ADD CONSTRAINT check_comments_public_reactions_count_non_negative CHECK (public_reactions_count >= 0)")
  end

  it "processes multiple affected records in batches" do
    articles = create_list(:article, 5)
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    articles.each do |article|
      set_counter_value(article, -1)
    end
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0) NOT VALID")

    described_class.new.run

    articles.each do |article|
      article.reload
      expect(article.public_reactions_count).to be >= 0
    end
  ensure
    ActiveRecord::Base.connection.execute("ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative")
    ActiveRecord::Base.connection.execute("ALTER TABLE articles ADD CONSTRAINT check_articles_public_reactions_count_non_negative CHECK (public_reactions_count >= 0)")
  end

  it "fixes negative previous_public_reactions_count on articles" do
    article = create(:article)
    # Temporarily disable constraint
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_previous_public_reactions_count_non_negative"
    )
    article.class.where(id: article.id).update_all(previous_public_reactions_count: -10)
    article.reload
    expect(article.previous_public_reactions_count).to eq(-10)

    described_class.new.run

    article.reload
    expect(article.previous_public_reactions_count).to eq(0)
  ensure
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_previous_public_reactions_count_non_negative"
    )
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE articles ADD CONSTRAINT check_articles_previous_public_reactions_count_non_negative " \
      "CHECK (previous_public_reactions_count >= 0)"
    )
  end
end
