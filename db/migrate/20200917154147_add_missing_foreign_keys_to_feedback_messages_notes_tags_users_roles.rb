class AddMissingForeignKeysToFeedbackMessagesNotesTagsUsersRoles < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :feedback_messages, :users, column: :affected_id, on_delete: :nullify, validate: false
    add_foreign_key :feedback_messages, :users, column: :offender_id, on_delete: :nullify, validate: false
    add_foreign_key :feedback_messages, :users, column: :reporter_id, on_delete: :nullify, validate: false

    add_foreign_key :notes, :users, column: :author_id, on_delete: :nullify, validate: false

    add_foreign_key :tags, :badges, on_delete: :nullify, validate: false
    add_foreign_key :tags, :chat_channels, column: :mod_chat_channel_id, on_delete: :nullify, validate: false

    add_foreign_key :users_roles, :roles, on_delete: :cascade, validate: false
  end
end
