class AddMissingForeignKeysToPollModels < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :poll_options, :polls, column: :poll_id, on_delete: :cascade, validate: false

    add_foreign_key :poll_skips, :polls, column: :poll_id, on_delete: :cascade, validate: false
    add_foreign_key :poll_skips, :users, column: :user_id, on_delete: :cascade, validate: false

    add_foreign_key :poll_votes, :polls, column: :poll_id, on_delete: :cascade, validate: false
    add_foreign_key :poll_votes, :poll_options, column: :poll_option_id, on_delete: :cascade, validate: false
    add_foreign_key :poll_votes, :users, column: :user_id, on_delete: :cascade, validate: false

    add_foreign_key :polls, :articles, column: :article_id, on_delete: :cascade, validate: false
  end
end
