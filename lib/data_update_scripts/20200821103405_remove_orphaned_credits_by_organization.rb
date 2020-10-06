module DataUpdateScripts
  class RemoveOrphanedCreditsByOrganization
    def run
      # Apparently we have a bunch of Credits that don't belong to either user or org
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM credits
          WHERE user_id IS NULL
          AND organization_id IS NULL
        SQL
      )

      # Delete all User less Credits belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM credits
          WHERE user_id IS NULL
          AND organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
