module DataUpdateScripts
  class BackfillForemOwnerRole
    def run
      User.with_role(:super_admin).first&.add_role(:forem_owner)
    end
  end
end
