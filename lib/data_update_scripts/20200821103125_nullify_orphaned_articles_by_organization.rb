module DataUpdateScripts
  class NullifyOrphanedArticlesByOrganization
    def run
      # Nullify organization_id for all Articles linked to a non existing Organization
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          UPDATE articles
          SET organization_id = NULL
          WHERE organization_id IS NOT NULL
          AND organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
