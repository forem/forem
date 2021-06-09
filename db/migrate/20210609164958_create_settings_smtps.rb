class CreateSettingsSmtps < ActiveRecord::Migration[6.1]
  def self.up
    create_table :settings_smtps do |t|
      t.string :var, null: false
      t.text :value, null: true

      t.timestamps
    end

    add_index :settings_smtps, :var, unique: true
  end

  def self.down
    drop_table :settings_smtps
  end
end
