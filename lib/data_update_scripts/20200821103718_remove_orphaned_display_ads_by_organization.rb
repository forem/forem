module DataUpdateScripts
  class RemoveOrphanedDisplayAdsByOrganization
    def run
      # Delete all DisplayAds belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM display_ads
          WHERE organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
