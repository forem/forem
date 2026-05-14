require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/fix_negative_reaction_counters.rb",
)

RSpec.describe DataUpdateScripts::FixNegativeReactionCounters do
  # Use let blocks instead of constants to avoid leaky declarations
  let(:articles_constraint) { "check_articles_public_reactions_count_non_negative" }
  let(:comments_constraint) { "check_comments_public_reactions_count_non_negative" }
  let(:articles_prev_constraint) { "check_articles_previous_public_reactions_count_non_negative" }

  # Helper methods for constraint management
  def drop_constraint(table, name)
    query = "ALTER TABLE #{table} DROP CONSTRAINT IF EXISTS #{name}"
    ActiveRecord::Base.connection.execute(query)
  end

  def add_constraint_not_valid(table, name, check_expr)
    query = "ALTER TABLE #{table} ADD CONSTRAINT #{name} CHECK (#{check_expr}) NOT VALID"
    ActiveRecord::Base.connection.execute(query)
  end

  def add_constraint(table, name, check_expr)
    query = "ALTER TABLE #{table} ADD CONSTRAINT #{name} CHECK (#{check_expr})"
    ActiveRecord::Base.connection.execute(query)
  end

  def set_counter_value(record, value)
    record.class.where(id: record.id).update_all(public_reactions_count: value)
    record.reload
  end

  def with_disabled_articles_constraint
    drop_constraint(:articles, articles_constraint)
    yield
  ensure
    drop_constraint(:articles, articles_constraint)
    add_constraint(:articles, articles_constraint, "public_reactions_count >= 0")
  end

  def with_disabled_comments_constraint
    drop_constraint(:comments, comments_constraint)
    yield
  ensure
    drop_constraint(:comments, comments_constraint)
    add_constraint(:comments, comments_constraint, "public_reactions_count >= 0")
  end

  def with_disabled_prev_constraint
    drop_constraint(:articles, articles_prev_constraint)
    yield
  ensure
    drop_constraint(:articles, articles_prev_constraint)
    add_constraint(:articles, articles_prev_constraint, "previous_public_reactions_count >= 0")
  end

  it "fixes negative public_reactions_count on articles" do
    with_disabled_articles_constraint do
      article = create(:article)
      create(:reaction, reactable: article, category: "like")
      set_counter_value(article, -5)
      add_constraint_not_valid(:articles, articles_constraint, "public_reactions_count >= 0")

      described_class.new.run

      article.reload
      expect(article.public_reactions_count).to be >= 0
      expect(article.public_reactions_count).to eq(article.reactions.public_category.count)
    end
  end

  it "fixes negative public_reactions_count on comments" do
    with_disabled_comments_constraint do
      comment = create(:comment)
      create(:reaction, reactable: comment, category: "like")
      set_counter_value(comment, -3)
      add_constraint_not_valid(:comments, comments_constraint, "public_reactions_count >= 0")

      described_class.new.run

      comment.reload
      expect(comment.public_reactions_count).to be >= 0
      expect(comment.public_reactions_count).to eq(comment.reactions.public_category.count)
    end
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
    with_disabled_articles_constraint do
      article = create(:article)
      set_counter_value(article, -1)
      add_constraint_not_valid(:articles, articles_constraint, "public_reactions_count >= 0")

      described_class.new.run

      article.reload
      expect(article.public_reactions_count).to eq(0)
    end
  end

  it "handles comments with zero reactions correctly" do
    with_disabled_comments_constraint do
      comment = create(:comment)
      set_counter_value(comment, -2)
      add_constraint_not_valid(:comments, comments_constraint, "public_reactions_count >= 0")

      described_class.new.run

      comment.reload
      expect(comment.public_reactions_count).to eq(0)
    end
  end

  it "processes multiple affected records in batches" do
    with_disabled_articles_constraint do
      articles = create_list(:article, 5)
      articles.each { |article| set_counter_value(article, -1) }
      add_constraint_not_valid(:articles, articles_constraint, "public_reactions_count >= 0")

      described_class.new.run

      articles.each do |article|
        article.reload
        expect(article.public_reactions_count).to be >= 0
      end
    end
  end

  it "fixes negative previous_public_reactions_count on articles" do
    with_disabled_prev_constraint do
      article = create(:article)
      article.class.where(id: article.id).update_all(previous_public_reactions_count: -10)
      article.reload
      expect(article.previous_public_reactions_count).to eq(-10)

      described_class.new.run

      article.reload
      expect(article.previous_public_reactions_count).to eq(0)
    end
  end

  it "handles mixed negative values correctly in same batch" do
    with_disabled_articles_constraint do
      articles = create_list(:article, 3)

      # Create different reaction states
      create_list(:reaction, 2, reactable: articles[0], category: "like")
      create(:reaction, reactable: articles[1], category: "like")
      # articles[2] has no reactions

      # Set different negative values
      set_counter_value(articles[0], -100)
      set_counter_value(articles[1], -1)
      set_counter_value(articles[2], -50)
      add_constraint_not_valid(:articles, articles_constraint, "public_reactions_count >= 0")

      described_class.new.run

      # Verify each article has correct count matching actual reactions
      articles.each do |article|
        article.reload
        expect(article.public_reactions_count).to eq(article.reactions.public_category.count)
        expect(article.public_reactions_count).to be >= 0
      end

      # Verify specific expected values
      expect(articles[0].reload.public_reactions_count).to eq(2)
      expect(articles[1].reload.public_reactions_count).to eq(1)
      expect(articles[2].reload.public_reactions_count).to eq(0)
    end
  end

  describe "database constraint enforcement", :aggregate_failures do
    # These tests verify CHECK constraints work at the database level.
    # We use a separate connection to avoid transaction issues when
    # the constraint violation aborts the current transaction.

    def execute_in_separate_connection(sql)
      # Use a separate connection pool checkout to isolate transaction state
      connection_config = ActiveRecord::Base.connection_db_config
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn.execute(sql)
      end
    end

    it "prevents inserting negative values via raw SQL after constraint is validated" do
      article = create(:article)

      error_raised = false
      begin
        # Use raw connection to test constraint outside RSpec transaction
        ActiveRecord::Base.connection.execute("SAVEPOINT constraint_test")
        ActiveRecord::Base.connection.execute(
          "UPDATE articles SET public_reactions_count = -1 WHERE id = #{article.id}",
        )
      rescue ActiveRecord::StatementInvalid => e
        error_raised = true
        expect(e.message).to match(/check_articles_public_reactions_count_non_negative/)
      ensure
        ActiveRecord::Base.connection.execute("ROLLBACK TO SAVEPOINT constraint_test")
      end

      expect(error_raised).to be(true), "Expected constraint violation error"
    end

    it "prevents negative previous_public_reactions_count via raw SQL" do
      article = create(:article)

      error_raised = false
      begin
        ActiveRecord::Base.connection.execute("SAVEPOINT constraint_test")
        ActiveRecord::Base.connection.execute(
          "UPDATE articles SET previous_public_reactions_count = -1 WHERE id = #{article.id}",
        )
      rescue ActiveRecord::StatementInvalid => e
        error_raised = true
        expect(e.message).to match(/check_articles_previous_public_reactions/)
      ensure
        ActiveRecord::Base.connection.execute("ROLLBACK TO SAVEPOINT constraint_test")
      end

      expect(error_raised).to be(true), "Expected constraint violation error"
    end

    it "prevents negative public_reactions_count on comments via raw SQL" do
      comment = create(:comment)

      error_raised = false
      begin
        ActiveRecord::Base.connection.execute("SAVEPOINT constraint_test")
        ActiveRecord::Base.connection.execute(
          "UPDATE comments SET public_reactions_count = -1 WHERE id = #{comment.id}",
        )
      rescue ActiveRecord::StatementInvalid => e
        error_raised = true
        expect(e.message).to match(/check_comments_public_reactions_count_non_negative/)
      ensure
        ActiveRecord::Base.connection.execute("ROLLBACK TO SAVEPOINT constraint_test")
      end

      expect(error_raised).to be(true), "Expected constraint violation error"
    end
  end
end
