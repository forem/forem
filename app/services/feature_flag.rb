# This module provides mechanisms for toggling on and off features.
#
# @note A wrapper around the Flipper gem
module FeatureFlag
  class Actor < SimpleDelegator
    class << self
      alias [] new
    end

    def flipper_id
      respond_to?(:id) ? id : self
    end
  end

  class << self
    delegate :add, :disable, :enable, :enabled?, :exist?, :remove, to: Flipper

    def enabled_for_user?(flag_name, user)
      enabled?(flag_name, FeatureFlag::Actor[user])
    end

    def enabled_for_user_id?(flag_name, user_id)
      enabled?(flag_name, FeatureFlag::Actor[user_id])
    end

    # @!method FeatureFlag.enabled?(feature_flag_name, *args)
    #
    #   Answers if the :feature_flag_name has been _explicitly_ **enabled**.
    #
    #   @param feature_flag_name [Symbol]
    #   @param args [Array] passed to Flipper.enabled?
    #
    #   @return [TrueClass] the feature is enabled
    #   @return [FalseClass] the feature is not enabled.
    #
    #   @see FeatureFlag.accessible?
    #
    #   @see https://rubydoc.info/gems/yard/file/docs/Tags.md#method for details on the @!method
    #        macro used to compose this documentation.

    # Unless the given :feature_flag_name is _explicitly_ **disabled**,
    # this method returns true.
    #
    # @param feature_flag_name [Symbol]
    # @param args [Array] passed to FeatureFlag.enabled?
    #
    # @return [TrueClass] go ahead and use this feature
    # @return [FalseClass] don't use this feature
    #
    # @note This is an optimistic test, namely if the given
    #       :feature_flag_name does not exist (e.g., has never been
    #       enabled, disabled, or has been removed), the feature is
    #       accessible.
    #
    # @see FeatureFlag.enabled?
    #
    # @see https://github.com/forem/forem/pull/8149
    #      for further discussion.
    def accessible?(feature_flag_name, *args)
      return true if feature_flag_name.blank?
      return true unless exist?(feature_flag_name)

      enabled?(feature_flag_name, *args)
    end

    # Retrieve a list of all currently defined flags and their status. This is
    # primarily intended for development and wraps +Flipper.features+.
    #
    # @return [Hash<Symbol, Symbol>] the defined flags with their status (+:on+ or +:off+).
    def all
      Flipper.features.to_h { |feature| [feature.name.to_sym, feature.state] }
    end
  end
end
