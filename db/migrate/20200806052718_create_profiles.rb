class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.belongs_to :user, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end
  end
end
