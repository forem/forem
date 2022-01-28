module DataUpdateScripts
  class AddAdminMemberViewFeatureFlag
    def run
      FeatureFlag.add(:admin_member_view)
    end
  end
end
