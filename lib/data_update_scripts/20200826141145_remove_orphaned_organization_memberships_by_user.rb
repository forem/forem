module DataUpdateScripts
  class RemoveOrphanedOrganizationMembershipsByUser
    def run
      # Delete all OrganizationMemberships belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM organization_memberships
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
