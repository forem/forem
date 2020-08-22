module DataUpdateScripts
  class NullifyOrphanedCollectionsByOrganization
    def run
      # Delete all User less Credits belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM credits
          WHERE user_id IS NULL
          AND organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
