module DataUpdateScripts
  # Registers the (disabled) flag gating user-authored sandboxed HTML embed pages.
  class AddUserEmbedPagesFeatureFlag
    def run
      FeatureFlag.add(:user_embed_pages)
    end
  end
end
