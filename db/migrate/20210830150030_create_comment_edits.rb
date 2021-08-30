class CreateCommentEdits < ActiveRecord::Migration[6.1]
  def change
    create_table :comment_edits do |t|
      t.bigint :comment_id
      t.jsonb :modifications
      t.bigint :editor_id

      t.timestamps
    end
  end
end
