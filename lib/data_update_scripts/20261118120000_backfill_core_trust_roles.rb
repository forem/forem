module DataUpdateScripts
  # MLH Core learns a user's trust roles (User::CORE_TRUST_ROLES) only when one
  # changes, so send the current set for everyone who already holds one.
  class BackfillCoreTrustRoles
    def run
      holders = User.joins(:roles).where(roles: { name: User::CORE_TRUST_ROLES }).select(:id)
      User.where(id: holders).find_each(&:track_core_trust_roles!)
    end
  end
end
