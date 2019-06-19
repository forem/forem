class AddSubscriptionStatusToFollows < ActiveRecord::Migration[5.2]
  def change
    add_column :follows, :subscription_status, :string, default: "all_posts", null: false
  end
end
