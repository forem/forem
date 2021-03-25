module DataUpdateScripts
  class AddSingleResourceRoleToTechAdmins
    def run
      users_with_tech_admin_role = Role.find_by(name: "tech_admin")&.users
      return unless users_with_tech_admin_role

      users_with_tech_admin_role.find_each do |user|
        user.add_role(:single_resource_admin, DataUpdateScript)
      end
    end
  end
end
