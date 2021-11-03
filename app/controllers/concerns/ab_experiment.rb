# This module wraps the FieldTest to provide a bit of insulation
# between the FieldTest implementation and the application logic.
#
# @note I really wanted this to be a stand-alone model, but in cases
#       where we don't have a user, the `field_test` method requires
#       extensive controller context (by way of FieldTest's
#       field_test_participants controller method).
module AbExperiment
  extend ActiveSupport::Concern

  # Find the appropriate feed strategy we're testing for the given user.
  #
  # @param user [User] find the feed strategy for the given user.
  # @param env [Hash] container for possible ENV override of strategy.
  # @param default_value [String] fallback value in case we have an
  #        error.  This name maps to the key named variant "original" in the
  #        ":feed_strategy" experiment as defined in config/field_test.yml
  #
  # @return [ActiveSupport::StringInquirer] an inquirable string.
  #
  # @note You can force a named strategy by setting an ENV variable.
  #       This forced strategy might be super useful for anyone performing
  #       QA testing on AB Testing scenarios.
  def feed_strategy_for(user:, env: ApplicationConfig, default_value: "original")
    (env["AB_EXPERIMENT_VARIANT_FEED_STRATEGY"] || field_test(:feed_strategy, participant: user)).inquiry
  rescue FieldTest::ExperimentNotFound
    # Because we should have a fall back plan in case the field test
    # has an odd configuration.
    default_value.inquiry
  end
end
