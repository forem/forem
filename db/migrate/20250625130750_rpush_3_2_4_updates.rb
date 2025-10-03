class Rpush324Updates < ActiveRecord::Migration[5.0]
  def self.up
    change_column :rpush_apps, :apn_key, :text, null: true
  end

  def self.down
    change_column :rpush_apps, :apn_key, :string, null: true
  end
end
