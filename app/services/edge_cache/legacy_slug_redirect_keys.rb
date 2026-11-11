module EdgeCache
  # Finds surrogate keys attached to cached 301 legacy-slug redirects (`/:old_username`
  # or `/:old_slug`) when a newly created or renamed User, Organization, Page, or
  # Podcast claims a top-level slug previously held by another User or Organization.
  module LegacySlugRedirectKeys
    module_function

    def call(slug, exclude_user_id: nil, exclude_organization_id: nil)
      normalized = slug.to_s.delete_prefix("/").downcase.strip
      return [] if normalized.blank? || normalized.include?("/")

      user_scope = User.where("old_username = ? OR old_old_username = ?", normalized, normalized)
      user_scope = user_scope.where.not(id: exclude_user_id) if exclude_user_id
      keys = user_scope.ids.map { |id| "users/#{id}/profile_identity" }

      org_scope = Organization.where("old_slug = ? OR old_old_slug = ?", normalized, normalized)
      org_scope = org_scope.where.not(id: exclude_organization_id) if exclude_organization_id
      keys.concat(org_scope.ids.map { |id| "organizations/#{id}" })

      keys
    end
  end
end
