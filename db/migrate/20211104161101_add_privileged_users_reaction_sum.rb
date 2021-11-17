class AddPrivilegedUsersReactionSum < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :privileged_users_reaction_points_sum, :integer, default: 0
  end
end
