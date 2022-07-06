module Admin
  module UsersHelper
    def role_options(logged_in_user)
      options = { "Statuses" => Constants::Role::BASE_ROLES }
      if logged_in_user.super_admin?
        special_roles = Constants::Role::SPECIAL_ROLES
        if FeatureFlag.enabled?(:moderator_role)
          special_roles = special_roles.dup << "Moderator"
        end
        options["Roles"] = special_roles
      end
      options
    end

    def format_last_activity_timestamp(timestamp)
      return if timestamp.blank?

      if timestamp.today?
        "Today, #{timestamp.strftime('%d %b')}"
      elsif timestamp.yesterday?
        "Yesterday, #{timestamp.strftime('%d %b')}"
      else
        timestamp.strftime("%d %b, %Y")
      end
    end

    def cascading_high_level_roles(user)
      if user.super_admin?
        "Super Admin"
      elsif user.admin?
        "Admin"
      elsif user.single_resource_admin_for?(:any)
        "Resource Admin"
      end
    end

    def format_role_tooltip(user)
      if user.super_admin?
        "Super Admin"
      elsif user.admin?
        "Admin"
      elsif user.single_resource_admin_for?(:any)
        "Resource Admin: #{user.roles.pluck(:resource_type).compact.join(', ')}"
      end
    end

    def user_status(user)
      if user.suspended?
        "Suspended"
      elsif user.warned?
        "Warned"
      elsif user.comment_suspended?
        "Comment Suspended"
      elsif user.trusted?
        "Trusted"
      else
        "Good Standing"
      end
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
      str = organization_names.first(imposed_limit).join(", ").to_s

      return str unless count > imposed_limit

      overflow = overflow_count(count, imposed_limit: imposed_limit)
      if overflow == 1
        str + " & #{overflow_count(count, imposed_limit: imposed_limit)} other"
      else
        str + " & #{overflow_count(count, imposed_limit: imposed_limit)} others"
      end
    end

    # Returns a boolean that indicates whether a user can be banished
    # A user can be banished when:
    # - the users account was created in the period before the last 100 days ago
    # and there are no comments from the user in the period before the last 100 days.
    # - if the logged in user is a super admin or support admin

    # Some practical scenarios:
    # Today is the 06 July:
    # - if a user was created before the 27 March 2022 (101 days ago)
    # and they had no comments before the 27 March 2022 then they can be banished.
    # - if they have any comments before the 27 March 2022 then they cannot be banished
    # - if they were created before the 27 March 2022 (101 days ago) and they have comments
    # before the 27 March 2022 then they cannot be banished.
    #  @param {Array} [array] the user
    # @return [Boolean]
    def banishable_user?(user)
      (user.comments.where("created_at < ?", 100.days.ago).empty? && user.created_at < 100.days.ago) ||
        current_user.super_admin? || current_user.support_admin?
    end
  end
end
