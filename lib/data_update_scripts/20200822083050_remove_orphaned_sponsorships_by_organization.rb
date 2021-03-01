module DataUpdateScripts
  class RemoveOrphanedSponsorshipsByOrganization
    def run
      # Delete all Sponsorships belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM sponsorships
          WHERE organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
