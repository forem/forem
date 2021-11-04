# This object wraps the FieldTest logic to provide a bit of insulation
# between the FieldTest implementation and the application logic.
#
# This is a SimpleDelegator because the field_test method requires
# controller context when the participating user is nil.
#
# Use the AbExperiment.get method to interact with this class.
class AbExperiment < SimpleDelegator
  # Don't allow someone to circumvent the .get class method.  I want
  # to follow the Law of Demeter and require that we us the @api
  # public
  private_class_method :new

  # @api public
  #
  # A convenience method to reduce the
  #
  # @param experiment [Symbol] the named method we'll call for an
  #        experiment.  It should be a method name defined on this
  #        object.
  # @param controller [ApplicationController] the request context of
  #        the experiment.
  # @note We need the controller object due to the implementation of
  #       the `field_test` method.  The `field_test` method is defined
  #       in the FieldTest::Helpers module.  If we have a user, the
  #       field_test method works great with just the
  #       FieldTest::Helpers methods.  However, if we don't have a
  #       user, then the field_test method calls
  #       `field_test_participant` which is defined in the
  #       `FieldTest::Controller` (which calls the `request` and
  #       `cookies`).
  # @param user [User] who are we running the experiment with
  # @param config [Hash] container for possible ENV override of strategy.
  # @param default_value [Object] the caller is making decisions based
  #        on a configured set of values.  They know which one they
  #        likely want.  Let them give us a hint.
  #
  # @return [Object] the experimenter should know what it wants
  #
  # @see config/field_test.yml file for configured experiments.
  #
  # @note You can force a named strategy by setting an ENV variable.
  #       This forced strategy might be super useful for anyone performing
  #       QA testing on AB Testing scenarios.
  #
  # @todo If we make heavy use of this class, consider guarding for
  #       valid experiment methods.
  def self.get(experiment:, controller:, user:, default_value:, config: ApplicationConfig)
    new(controller: controller)
      .public_send(experiment, user: user, default_value: default_value, config: config)
  end

  # @api private
  # @param controller [ApplicationController] the current controller
  #        that's handling the current request.
  def initialize(controller:)
    super(controller)
  end

  # @api private
  def feed_strategy(user:, config:, default_value:)
    (config["AB_EXPERIMENT_FEED_STRATEGY"] || field_test(:feed_strategy, participant: user)).inquiry
  rescue FieldTest::ExperimentNotFound
    # Because we should have a fall back plan in case the field test
    # has an odd configuration.
    default_value.inquiry
  end
end
