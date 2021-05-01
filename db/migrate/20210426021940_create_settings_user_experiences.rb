class CreateSettingsUserExperiences < ActiveRecord::Migration[6.1]
  def self.up
    create_table :settings_user_experiences do |t|
      t.string :var, null: false
      t.text :value, null: true

      t.timestamps
    end

    add_index :settings_user_experiences, :var, unique: true
  end

  def self.down
    drop_table :settings_user_experiences
  end
end
