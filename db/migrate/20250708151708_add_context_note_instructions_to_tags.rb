class AddContextNoteInstructionsToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :context_note_instructions, :text
  end
end
