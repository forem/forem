class CreateScheduledAutomations < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_automations do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :frequency, null: false
      t.jsonb :frequency_config, default: {}
      t.string :action, null: false
      t.jsonb :action_config, default: {}
      t.text :additional_instructions
      t.datetime :last_run_at
      t.datetime :next_run_at, index: true
      t.string :state, default: "active", null: false
      t.string :service_name, null: false
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :scheduled_automations, [:user_id, :enabled]
    add_index :scheduled_automations, [:state, :next_run_at]
  end
end
