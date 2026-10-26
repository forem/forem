module DataUpdateScripts
  # Registers the (disabled) flag gating the editor's follower co-author invitations, so it shows
  # up in the feature flag admin ready to be turned on.
  class AddCoAuthorInvitationsFeatureFlag
    def run
      FeatureFlag.add(:co_author_invitations)
    end
  end
end
