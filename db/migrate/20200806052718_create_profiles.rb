class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end
    add_foreign_key :profiles, :users, on_delete: :cascade, validate: false
  end
end
