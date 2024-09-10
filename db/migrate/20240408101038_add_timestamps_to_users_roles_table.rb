class AddTimestampsToUsersRolesTable < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :users_roles, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
