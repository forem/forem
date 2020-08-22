module DataUpdateScripts
  class NullifyOrphanedListingsByOrganization
    def run
      # Nullify organization_id for all Listings linked to a non existing Organization
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          UPDATE listings
          SET organization_id = NULL
          WHERE organization_id IS NOT NULL
          AND organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
