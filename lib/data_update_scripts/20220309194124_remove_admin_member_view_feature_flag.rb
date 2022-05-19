module DataUpdateScripts
  class RemoveAdminMemberViewFeatureFlag
    def run
      FeatureFlag.disable(:admin_member_view)
      FeatureFlag.remove(:admin_member_view)
    end
  end
end
