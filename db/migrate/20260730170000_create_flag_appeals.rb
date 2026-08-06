class CreateFlagAppeals < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    create_table :flag_appeals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :appealable, polymorphic: true, null: false
      t.text :reason, null: false
      t.integer :status, default: 0, null: false
      t.integer :ai_recommendation, default: 1, null: false
      t.text :ai_summary
      t.float :ai_confidence_score
      t.references :resolved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :flag_appeals, :status, algorithm: :concurrently
    add_index :flag_appeals, %i[user_id appealable_type appealable_id],
              unique: true,
              where: "status IN (0, 1)",
              name: "index_flag_appeals_on_pending_user_target",
              algorithm: :concurrently
  end
end
