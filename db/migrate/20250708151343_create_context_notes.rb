class CreateContextNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :context_notes do |t|
      t.text :body_markdown, null: false
      t.text :processed_html, null: false
      t.references :article, null: false, foreign_key: true
      t.references :tag, foreign_key: true
      t.timestamps
    end
  end
end
