##
# This module is providing a "crease in the code" for refactoring.
# The initial purpose is to help move away sending `has_role?`
# messages to User records.  Prior to this refactor, there were calls
# to `user.has_role?(:tech_admin)` and `user.tech_admin?`; this
# created leaks in abstraction (see
# Authorizer::RoleBasedQueries#admin? for an example).
#
# By moving towards a single entry point and communicating that
# deprecation, the hope is to make the next conversation about roles
# easier.
module Authorizer
  # @api private
  #
  # @note This method introduces some indirection, the idea being that
  #       the `Authorizer::RoleBasedQueries` is a refactor to convey
  #       deprecations and provide guidance on sending things through
  #       a common method pattern (e.g. favor `user.tech_admin?` over
  #       `user.has_role?(:tech_admin)`).
  #
  # @param user [User] the user of whom we're curious about their
  #        attributes and how the imply permissions.
  #
  def self.for(user:)
    RoleBasedQueries.new(user: user)
  end

  # @api private
  #
  # This class is responsible for assisting in moving us away from
  # `user.some_property_for_permissions?`.
  #
  # @see https://github.com/forem/forem/issues/15624
  class RoleBasedQueries
    ANY_ADMIN_ROLES = %i[admin super_admin].freeze

    def initialize(user:)
      @user = user
    end
    attr_reader :user

    def admin?
      has_role?(:admin)
    end

    def administrative_access_to?(resource:, role_name: :single_resource_admin)
      # The implementation details of rolify are such that we can't
      # quite combine these functions.
      return true if has_any_role?(*ANY_ADMIN_ROLES)

      if resource
        has_role?(role_name, resource)
      else
        has_role?(role_name)
      end
    end

    def any_admin?
      has_any_role?(*ANY_ADMIN_ROLES)
    end

    def auditable?
      trusted? || tag_moderator? || any_admin?
    end

    def banished?
      user.username.starts_with?("spam_")
    end

    def comment_suspended?
      has_role?(:comment_suspended)
    end

    def creator?
      has_role?(:creator)
    end

    def accesses_mod_response_templates?
      has_trusted_role? || any_admin? || super_moderator? || tag_moderator?
    end

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

    def super_moderator?
      has_role?(:super_moderator)
    end

    def podcast_admin_for?(podcast)
      has_role?(:podcast_admin, podcast)
    end

    def single_resource_admin_for?(resource)
      has_role?(:single_resource_admin, resource)
    end

    # @note This is of "narrower" permissions than
    #       `#user_subscription_tag_available?`, as it doesn't include
    #       administrators.
    #
    # @todo Remove this?
    def restricted_liquid_tag_for?(liquid_tag)
      has_role?(:restricted_liquid_tag, liquid_tag)
    end

    def super_admin?
      has_role?(:super_admin)
    end

    def support_admin?
      has_role?(:support_admin)
    end

    def suspended?
      has_role?(:suspended)
    end

    def tag_moderator?(tag: nil)
      # Note a fan of "peeking" into the roles table, which in a way
      # circumvents the rolify gem.  But this was the past implementation.
      return user.roles.exists?(name: "tag_moderator") unless tag

      has_role?(:tag_moderator, tag)
    end

    def tech_admin?
      has_any_role?(:tech_admin, :super_admin)
    end

    def trusted?
      return @trusted if defined? @trusted

      @trusted = Rails.cache.fetch("user-#{user.id}/has_trusted_role", expires_in: 200.hours) do
        has_role?(:trusted)
      end
    end

    def user_subscription_tag_available?
      administrative_access_to?(role_name: :restricted_liquid_tag, resource: LiquidTags::UserSubscriptionTag)
    end

    def vomited_on?
      Reaction.exists?(reactable: user, category: "vomit", status: "confirmed")
    end

    def warned?
      has_role?(:warned)
    end

    def workshop_eligible?
      has_any_role?(:workshop_pass)
    end

    private

    def has_role?(*args)
      user.__send__(:has_role?, *args)
    end

    def has_any_role?(*args)
      user.__send__(:has_any_role?, *args)
    end
  end
end
