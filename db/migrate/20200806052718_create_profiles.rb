class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.belongs_to :user, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :data, default: {}

      t.timestamps
    end
  end
end
