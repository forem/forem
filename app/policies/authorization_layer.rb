module AuthorizationLayer
  # @deprecated
  #
  # @api private
  #
  # This class is responsible for assisting in moving us away from
  # `user.some_property_for_permissions?`.  I'm introducing it as
  # deprecated to indicate that we want to use this class as a pivot
  # point for our work.
  #
  # @see https://github.com/forem/forem/issues/15624
  class DeprecatedImpliedQueries
    ANY_ADMIN_ROLES = %i[admin super_admin].freeze

    ##
    # @param user [User] the user of whom we're curious about their
    #        attributes and how the imply permissions.
    def initialize(user:)
      @user = user
    end
    attr_reader :user

    # When you need to know if we trust the user, but don't want to
    # have stale information that the `trusted?` method might give
    # you.
    #
    # @note You may ask why not use the trusted? method on this class?
    #       Well, in looking at the code there were explicit calls to
    #       `user.has_role?(:trusted)` which circumvented the caching
    #       logic.  I'm uncertain which of those is appropriate, so
    #       I'm adding this method here.
    #
    # @see #trusted?
    #
    # @todo Review whether we can use trusted? or if we even need to cache things.
    def has_trusted_role?
      has_role?(:trusted)
    end

    def super_admin?
      has_role?(:super_admin)
    end

    def suspended?
      has_role?(:suspended)
    end

    def warned?
      has_role?(:warned)
    end

    def warned
      ActiveSupport::Deprecation.warn("User#warned is deprecated, favor User#warned?")
      warned?
    end

    def admin?
      has_role?(:super_admin)
    end

    def creator?
      has_role?(:creator)
    end

    def any_admin?
      @any_admin ||= user.roles.where(name: ANY_ADMIN_ROLES).any?
    end

    def tech_admin?
      has_role?(:tech_admin) || has_role?(:super_admin)
    end

    def vomitted_on?
      Reaction.exists?(reactable_id: id, reactable_type: "User", category: "vomit", status: "confirmed")
    end

    def trusted?
      return @trusted if defined? @trusted

      @trusted = Rails.cache.fetch("user-#{user.id}/has_trusted_role", expires_in: 200.hours) do
        has_role?(:trusted)
      end
    end

    def trusted
      ActiveSupport::Deprecation.warn("User#trusted is deprecated, favor User#trusted?")
      trusted?
    end

    def comment_suspended?
      has_role?(:comment_suspended)
    end

    def workshop_eligible?
      has_any_role?(:workshop_pass)
    end

    def banished?
      username.starts_with?("spam_")
    end

    def auditable?
      trusted || tag_moderator? || any_admin?
    end

    def tag_moderator?
      user.roles.where(name: "tag_moderator").any?
    end

    private

    def has_role?(*args)
      user.__send__(:__has_role_without_warning?, *args)
    end

    def has_any_role?(*args)
      user.__send__(:__has_any_role_without_warning?, *args)
    end
  end
end
