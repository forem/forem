class CreatePageRedirect < ActiveRecord::Migration[5.2]
  def change
    create_table :page_redirects do |t|
      t.string :old_slug, null: false
      t.string :new_slug, null: false
      t.boolean :overridden, null: false, default: false
      t.integer :version, null: false, default: 1
      t.timestamps null: false
    end

    add_index :page_redirects, :old_slug, unique: true
    add_index :page_redirects, :new_slug
    add_index :page_redirects, %i[old_slug new_slug], unique: true
    add_index :page_redirects, :version
    add_index :page_redirects, :overridden
  end
end
