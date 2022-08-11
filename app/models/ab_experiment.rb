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

  # @see ./config/feed-variants/README.md
  ORIGINAL_VARIANT = "original".freeze

  # @note a present assumption is that we will have a feed_strategy oriented experiment.
  CURRENT_FEED_STRATEGY_EXPERIMENT = FieldTest.config["experiments"].select do |key, value|
    key.start_with?("feed_strategy") && !value["winner"]
  end.keys.first

  # Sometimes we might want to repurpose the same AbExperiment logic
  # for different experiments.  This provides the tooling for that
  # exact thing.
  EXPERIMENT_TO_METHOD_NAME_MAP = {
    CURRENT_FEED_STRATEGY_EXPERIMENT => :feed_strategy
  }.freeze

  # This method helps us leverage existing methods for different
  # experiments.
  #
  # @param experiment [Symbol] the name of the experiment
  # @return [Symbol] the method name associated with this experiment.
  #
  # @see EXPERIMENT_TO_METHOD_NAME_MAP
  def self.method_name_for(experiment)
    EXPERIMENT_TO_METHOD_NAME_MAP.fetch(experiment, experiment)
  end

  # A convenience method for retrieving the feed variant
  # @param controller [ApplicationController] the request context of
  #        the experiment.
  # @param user [User] who are we running the experiment with
  #
  # @return [Object] a variant that the experimenter should know what it wants
  #
  # @see .get
  def self.get_feed_variant_for(controller:, user:)
    get(
      controller: controller,
      user: user,
      default_value: ORIGINAL_VARIANT,
      experiment: CURRENT_FEED_STRATEGY_EXPERIMENT,
    )
  end

  def self.variants_for_experiment(experiment)
    configured_experiment = FieldTest.config["experiments"][experiment]
    configured_experiment["variants"] if configured_experiment
  end

  # @api public
  #
  # A convenience method to insulate against the implementation
  # details of the field_test gem.
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
  # @return [Object] a variant that the experimenter should know what it wants
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
    method_name = method_name_for(experiment)
    new(controller: controller)
      .public_send(method_name, user: user, default_value: default_value, experiment: experiment, config: config)
  end

  # Responsible for checking if a given :user has "accomplished" the state :goal for any of the
  # active :experiments.  We only consider events that occur on or after each experiment's given
  # start_date.
  #
  # @param user [User]
  # @param goal [String]
  # @param experiments [Hash<String, Object>]
  #
  # @see AbExperiment::GoalConversionChecker
  # @see FieldTest.config
  def self.register_conversions_for(user:, goal:, experiments: FieldTest.config["experiments"])
    GoalConversionHandler.call(user: user, goal: goal, experiments: experiments)
  end

  # @api private
  # @param controller [ApplicationController] the current controller
  #        that's handling the current request.
  def initialize(controller:)
    super(controller)
  end

  # @api private
  # @note Called via AbExperiment.get
  def feed_strategy(user:, config:, default_value:, experiment: :feed_strategy)
    return default_value.inquiry unless FeatureFlag.accessible?(:ab_experiment_feed_strategy)

    (config["AB_EXPERIMENT_FEED_STRATEGY"] || field_test(experiment, participant: user)).inquiry
  rescue FieldTest::ExperimentNotFound
    # rubocop:disable Layout/LineLength
    Rails.logger.warn do
      "Upstream request #{experiment.inspect} experiment.  There are no registered #{experiment.inspect} experiments.  Using the default value of #{default_value.inspect} for #{experiment.inspect} experiment."
    end
    # rubocop:enable Layout/LineLength

    # Because we should have a fall back plan in case the field test
    # has an odd configuration.
    default_value.inquiry
  end
end
