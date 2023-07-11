module Admin
  module UsersHelper
    def role_options(logged_in_user)
      options = { "Statuses" => Constants::Role::BASE_ROLES }
      if logged_in_user.super_admin?
        special_roles = Constants::Role::SPECIAL_ROLES
        if FeatureFlag.enabled?(:moderator_role)
          special_roles = special_roles.dup << "Super Moderator"
        end
        options["Roles"] = special_roles
      end
      options
    end

    def format_last_activity_timestamp(timestamp)
      return if timestamp.blank?

      if timestamp.today?
        I18n.t("helpers.admin.user_helper.today", date: I18n.l(timestamp, format: :members))
      elsif timestamp.yesterday?
        I18n.t("helpers.admin.user_helper.yesterday", date: I18n.l(timestamp, format: :members))
      else
        I18n.l(timestamp, format: :members_with_year)
      end
    end

    def cascading_high_level_roles(user)
      if user.super_admin?
        I18n.t("views.admin.users.roles.Super Admin")
      elsif user.admin?
        I18n.t("views.admin.users.roles.Admin")
      elsif user.single_resource_admin_for?(:any)
        I18n.t("views.admin.users.roles.Resource Admin")
      end
    end

    def format_role_tooltip(user)
      if user.super_admin?
        I18n.t("views.admin.users.roles.Super Admin")
      elsif user.admin?
        I18n.t("views.admin.users.roles.Admin")
      elsif user.single_resource_admin_for?(:any)
        role = "Resource Admin: #{user.roles.pluck(:resource_type).compact.join(', ')}"
        I18n.t("views.admin.users.roles.#{role}", default: role)
      end
    end

    def user_status(user)
      if user.suspended?
        I18n.t("views.admin.users.statuses.Suspended")
      elsif user.warned?
        I18n.t("views.admin.users.statuses.Warned")
      elsif user.comment_suspended?
        I18n.t("views.admin.users.statuses.Comment Suspended")
      elsif user.trusted?
        I18n.t("views.admin.users.statuses.Trusted")
      else
        I18n.t("views.admin.users.statuses.Good Standing")
      end
    end

    # We de-scoped filtering by "Good standing" due to the complexity of it not mapping directly to a specific role
    def filterable_statuses
      Constants::Role::BASE_ROLES.reject { |status| status == "Good standing" }
    end

    # Provides the remaining count when a limit for a resource is imposed on the UI.
    #
    #  @param [Integer] The total count
    #  @param [Integer] A limit that we show
    # @return [Integer] The overflow that is calculated
    def overflow_count(count, imposed_limit: 0)
      return if count <= imposed_limit

      count - imposed_limit
    end

    # Returns a string for the organization tooltip outlining the first three organizations
    # as comma seperated values and then appending the remaining organizations (if any)
    # as a count.
    #
    #  @param {Array} [array] The array of organization names
    #  @param [Integer] The total count of organizations
    #  @param [Integer] The limit of organizations that we show
    # @return [String]
    def organization_tooltip(organization_names, count, imposed_limit: 0)
      str = organization_names.first(imposed_limit).join(I18n.t("helpers.admin.user_helper.org_join")).to_s

      return str unless count > imposed_limit

      I18n.t("helpers.admin.user_helper.org_overflow", count: overflow_count(count, imposed_limit: imposed_limit),
                                                       orgs: str)
    end

    # Returns a string hex code representing the indicator color for the given status (also known as BASE_ROLE)
    def status_to_indicator_color(status)
      case status
      when "Suspended"
        "#DC2626"
      when "Warned"
        "#F59E0B"
      when "Comment Suspended"
        "#DC2626"
      when "Trusted"
        "#059669"
      else
        "#A3A3A3"
      end
    end
  end
end
