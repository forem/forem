class CreateSettingsSMTP < ActiveRecord::Migration[6.1]
  def self.up
    create_table :settings_smtp do |t|
      t.string :var, null: false
      t.text :value, null: true

      t.timestamps
    end

    add_index :settings_smtp, :var, unique: true
  end

  def self.down
    drop_table :settings_smtp
  end
end
