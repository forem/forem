class CreateSettingsCampaigns < ActiveRecord::Migration[6.0]
  def self.up
    create_table :settings_campaigns do |t|
      t.string :var, null: false
      t.text :value, null: true

      t.timestamps
    end

    add_index :settings_campaigns, :var, unique: true
  end

  def self.down
    drop_table :settings_campaigns
  end
end
