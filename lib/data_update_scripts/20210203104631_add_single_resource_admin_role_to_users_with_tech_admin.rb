module DataUpdateScripts
  class AddSingleResourceAdminRoleToUsersWithTechAdmin
    def run
      # This script causes errors when it runs on Forems that do not have any
      # users with a tech_admin role.
      # 20210209185037_add_single_resource_role_to_tech_admins is the script
      # that should override this one as a replacement.

      # users_with_tech_admin_role = Role.find_by(name: "tech_admin").users

      # users_with_tech_admin_role.find_each do |user|
      #   user.add_role(:single_resource_admin, DataUpdateScript)
      # end
    end
  end
end
