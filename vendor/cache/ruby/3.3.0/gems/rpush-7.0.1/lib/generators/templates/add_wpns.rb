class AddWpns < ActiveRecord::Migration[5.0]
  module Rapns
    class Notification < ActiveRecord::Base
      self.table_name = 'rapns_notifications'
    end
  end

  def self.up
    add_column :rapns_notifications, :uri, :string, null: true
  end

  def self.down
    AddWpns::Rapns::Notification.where(type: 'Rapns::Wpns::Notification').delete_all
    remove_column :rapns_notifications, :uri
  end
end
