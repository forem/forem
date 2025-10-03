class Rpush411Updates < ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
  def self.up
    add_column :rpush_apps, :feedback_enabled, :boolean, default: true
  end

  def self.down
    remove_column :rpush_apps, :feedback_enabled
  end
end
