class AddPartialIndexForNegativeReactionCounts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Add partial indexes to optimize queries for negative reaction counts.
  # These indexes support the FixNegativeReactionCounters data script.
  #
  # Partial indexes only include rows where the condition is true,
  # making them very small and efficient for cleanup queries.
  #
  # These indexes can be safely removed after the cleanup is complete
  # since the CHECK constraints will prevent future negative values.

  def up
    add_index :articles,
              :id,
              where: "public_reactions_count < 0",
              name: "index_articles_negative_public_reactions_count",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :articles,
              :id,
              where: "previous_public_reactions_count < 0",
              name: "index_articles_negative_prev_public_reactions_count",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :comments,
              :id,
              where: "public_reactions_count < 0",
              name: "index_comments_negative_public_reactions_count",
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :articles,
                 name: "index_articles_negative_public_reactions_count",
                 if_exists: true

    remove_index :articles,
                 name: "index_articles_negative_prev_public_reactions_count",
                 if_exists: true

    remove_index :comments,
                 name: "index_comments_negative_public_reactions_count",
                 if_exists: true
  end
end
