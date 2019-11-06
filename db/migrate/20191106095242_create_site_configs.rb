class CreateSiteConfigs < ActiveRecord::Migration[5.2]
  def self.up
    create_table :site_configs do |t|
      t.string  :var,        null: false
      t.text    :value,      null: true
      t.timestamps
    end

    add_index :site_configs, %i(var), unique: true
  end

  def self.down
    drop_table :site_configs
  end
end
