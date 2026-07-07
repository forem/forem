class AddModerationInstructionsToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :moderation_instructions, :text
  end
end
