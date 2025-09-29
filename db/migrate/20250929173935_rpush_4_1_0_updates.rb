class Rpush410Updates < ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
  def self.up
    add_column :rpush_notifications, :dry_run, :boolean, null: false, default: false
  end

  def self.down
    remove_column :rpush_notifications, :dry_run
  end
end
