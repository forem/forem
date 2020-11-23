module DataUpdateScripts
  class RemoveOrphanedListingsByOrganization
    def run
      # Delete all Listings belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM classified_listings
          WHERE organization_id IS NOT NULL
          AND organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
