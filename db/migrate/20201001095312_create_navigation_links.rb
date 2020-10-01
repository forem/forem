class CreateNavigationLinks < ActiveRecord::Migration[6.0]
  def change
    create_table :navigation_links do |t|
      t.string :name
      t.string :url
      t.string :icon
      t.boolean :requires_auth

      t.timestamps
    end
  end
end
