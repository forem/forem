# This module provides mechanisms for toggling on and off features.
#
# @note A wrapper around the Flipper gem
module FeatureFlag
  class << self
    delegate :add, :disable, :enable, :enabled?, :exist?, :remove, to: Flipper

    # Unless the given :feature_flag_name is _explicitly_ disabled,
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
    # @see https://github.com/forem/forem/pull/8149
    #      for further discussion.
    def accessible?(feature_flag_name, *args)
      return true if feature_flag_name.blank?
      return true unless exist?(feature_flag_name)

      enabled?(feature_flag_name, *args)
    end
  end
end
