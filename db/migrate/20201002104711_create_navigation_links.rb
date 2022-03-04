class CreateNavigationLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :navigation_links do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :icon, null: false
      t.boolean :display_when_signed_in, default: false

      t.timestamps
    end
  end
end
