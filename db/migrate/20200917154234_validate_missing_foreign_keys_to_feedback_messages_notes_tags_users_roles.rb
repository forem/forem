class ValidateMissingForeignKeysToFeedbackMessagesNotesTagsUsersRoles < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :feedback_messages, :users, column: :affected_id
    validate_foreign_key :feedback_messages, :users, column: :offender_id
    validate_foreign_key :feedback_messages, :users, column: :reporter_id

    validate_foreign_key :notes, :users, column: :author_id

    validate_foreign_key :tags, :badges
    validate_foreign_key :tags, :chat_channels, column: :mod_chat_channel_id

    validate_foreign_key :users_roles, :roles
  end
end
