class AddNonNegativeReactionsConstraints < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # SAFE MIGRATION STRATEGY:
  # Phase 1 (this migration): Add constraints WITHOUT validation - non-blocking
  # Phase 2 (data_update_script): Fix existing negative values via FixNegativeReactionCounters
  # Phase 3 (separate migration): Validate constraints after data is clean
  #
  # This ensures deployment won't fail due to existing negative values.
  # The constraints will still prevent NEW negative values from being inserted.

  def up
    # Add check constraints to prevent negative reaction counts
    # Using validate: false means:
    # - New inserts/updates ARE blocked if they violate the constraint
    # - Existing rows are NOT validated (won't fail migration)
    add_check_constraint :articles,
                         "public_reactions_count >= 0",
                         name: "check_articles_public_reactions_count_non_negative",
                         validate: false

    add_check_constraint :articles,
                         "previous_public_reactions_count >= 0",
                         name: "check_articles_previous_public_reactions_count_non_negative",
                         validate: false

    add_check_constraint :comments,
                         "public_reactions_count >= 0",
                         name: "check_comments_public_reactions_count_non_negative",
                         validate: false

    # NOTE: Do NOT validate here - validation happens in separate migration
    # after FixNegativeReactionCounters data script has run
  end

  def down
    safety_assured do
      execute <<-SQL
        ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_public_reactions_count_non_negative;
        ALTER TABLE articles DROP CONSTRAINT IF EXISTS check_articles_previous_public_reactions_count_non_negative;
        ALTER TABLE comments DROP CONSTRAINT IF EXISTS check_comments_public_reactions_count_non_negative;
      SQL
    end
  end
end
