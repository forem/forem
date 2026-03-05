class ValidateNonNegativeReactionCountConstraints < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Phase 3 of safe constraint deployment:
  # This migration validates check constraints added in Phase 1 migration.
  # It should only run AFTER the FixNegativeReactionCounters data script
  # has corrected any existing negative values.
  #
  # Validation is non-blocking when using disable_ddl_transaction!
  # but will FAIL if any violating rows still exist.

  def up
    # Safety check: Verify no negative values exist before validation
    validate_no_negative_values!

    # Validate constraints - makes them "trusted" by the query planner
    validate_check_constraint :articles, name: "check_articles_public_reactions_count_non_negative"
    validate_check_constraint :articles, name: "check_articles_previous_public_reactions_count_non_negative"
    validate_check_constraint :comments, name: "check_comments_public_reactions_count_non_negative"
  end

  def down
    # Nothing to do - constraints remain valid
    # If you need to invalidate, drop and re-add with validate: false
  end

  private

  def validate_no_negative_values!
    negative_articles = Article.where("public_reactions_count < 0 OR previous_public_reactions_count < 0").count
    negative_comments = Comment.where("public_reactions_count < 0").count

    return if negative_articles.zero? && negative_comments.zero?

    raise StandardError, <<~ERROR
      Cannot validate constraints: negative reaction counts still exist!

      Found #{negative_articles} articles and #{negative_comments} comments with negative counts.

      Please run the FixNegativeReactionCounters data script first:
        rails runner "DataUpdateScripts::FixNegativeReactionCounters.new.run"

      Then retry this migration.
    ERROR
  end
end
