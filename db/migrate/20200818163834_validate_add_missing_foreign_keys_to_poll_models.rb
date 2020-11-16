class ValidateAddMissingForeignKeysToPollModels < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :poll_options, :polls
    validate_foreign_key :poll_skips, :polls
    validate_foreign_key :poll_skips, :users
    validate_foreign_key :poll_votes, :polls
    validate_foreign_key :poll_votes, :poll_options
    validate_foreign_key :poll_votes, :users
    validate_foreign_key :polls, :articles
  end
end
