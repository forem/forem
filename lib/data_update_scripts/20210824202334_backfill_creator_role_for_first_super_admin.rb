module DataUpdateScripts
  class BackfillCreatorRoleForFirstSuperAdmin
    def run
      User.with_role(:super_admin).first&.add_role(:creator)
    end
  end
end
