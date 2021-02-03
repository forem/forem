module DataUpdateScripts
  class AddSingleResourceAdminRoleToUsersWithTechAdmin
    def run
      users_with_tech_admin_role = Role.find_by(name: "tech_admin").users
      users_with_tech_admin_role.find_each do |user|
        user.add_role(:single_resource_admin, DataUpdateScript)
      end
    end
  end
end
