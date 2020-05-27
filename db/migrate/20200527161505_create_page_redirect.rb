class CreatePageRedirect < ActiveRecord::Migration[5.2]
  def change
    create_table :page_redirects do |t|
      t.string :old_slug, null: false
      t.string :new_slug, null: false
      t.boolean :overridden, null: false, default: false
      t.integer :version, null: false, default: 1
    end
  end
end
