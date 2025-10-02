class Rpush311Updates < ActiveRecord::Migration[5.0]
  def self.up
    change_table :rpush_notifications do |t|
      t.remove_index name: 'index_rpush_notifications_multi'
      t.index [:delivered, :failed, :processing, :deliver_after, :created_at], name: 'index_rpush_notifications_multi', where: 'NOT delivered AND NOT failed'
    end
  end

  def self.down
    change_table :rpush_notifications do |t|
      t.remove_index name: 'index_rpush_notifications_multi'
      t.index [:delivered, :failed], name: 'index_rpush_notifications_multi', where: 'NOT delivered AND NOT failed'
    end
  end
end
