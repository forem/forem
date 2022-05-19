module DataUpdateScripts
  class EnableAdminMemberView
    def run
      FeatureFlag.enable(:admin_member_view)
    end
  end
end
