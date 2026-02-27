class AddNonNegativeConstraintsToReactionsCounts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Add check constraints to prevent negative reaction counts
    # Database-level enforcement as last line of defense against counter_culture race conditions
    add_check_constraint :articles,
                         "public_reactions_count >= 0",
                         name: "check_articles_public_reactions_count_non_negative",
                         validate: false

    add_check_constraint :comments,
                         "public_reactions_count >= 0",
                         name: "check_comments_public_reactions_count_non_negative",
                         validate: false

    # Validate constraints separately to avoid blocking writes
    validate_check_constraint :articles, name: "check_articles_public_reactions_count_non_negative"
    validate_check_constraint :comments, name: "check_comments_public_reactions_count_non_negative"
  end

  def down
    remove_check_constraint :articles, name: "check_articles_public_reactions_count_non_negative"
    remove_check_constraint :comments, name: "check_comments_public_reactions_count_non_negative"
  end
end
