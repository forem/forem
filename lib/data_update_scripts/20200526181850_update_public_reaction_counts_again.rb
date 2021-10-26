module DataUpdateScripts
  class UpdatePublicReactionCountsAgain
    def run
      # October 2021 - this causes interactions during seeding/setup that cause the
      # public reactions count to drop to zero (when there are reactions present).
      # marking a noop to avoid this.

      nil
    end
  end
end
