class Rpush420Updates < ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
  def self.up
    add_column :rpush_notifications, :sound_is_json, :boolean, null: true, default: false
  end

  def self.down
    remove_column :rpush_notifications, :sound_is_json
  end
end

