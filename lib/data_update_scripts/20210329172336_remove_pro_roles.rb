module DataUpdateScripts
  class RemoveProRoles
    def run
      pro_role = Role.find_by(name: "pro")

      return unless pro_role

      pro_role.users.find_each { |u| u.remove_role(:pro) }
      pro_role.destroy
    end
  end
end
