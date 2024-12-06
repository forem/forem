class CreateRapnsFeedback < ActiveRecord::Migration[5.0]
  def self.up
    create_table :rapns_feedback do |t|
      t.string    :device_token,          null: false, limit: 64
      t.timestamp :failed_at,             null: false
      t.timestamps
    end

    add_index :rapns_feedback, :device_token
  end

  def self.down
    if index_name_exists?(:rapns_feedback, :index_rapns_feedback_on_device_token)
      remove_index :rapns_feedback, name: :index_rapns_feedback_on_device_token
    end

    drop_table :rapns_feedback
  end
end
