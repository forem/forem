class AddLimitedRoleToRoles < ActiveRecord::Migration[7.0]
  def up
    Role.create!(name: "limited") unless Role.exists?(name: "limited")
  end

  def down
    role = Role.find_by(name: "limited")
    role&.destroy
  end
end
