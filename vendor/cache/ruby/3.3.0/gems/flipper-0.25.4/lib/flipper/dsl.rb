require 'forwardable'

module Flipper
  class DSL
    extend Forwardable

    # Private
    attr_reader :adapter

    # Private: What is being used to instrument all the things.
    attr_reader :instrumenter

    def_delegators :@adapter, :memoize=, :memoizing?

    # Public: Returns a new instance of the DSL.
    #
    # adapter - The adapter that this DSL instance should use.
    # options - The Hash of options.
    #           :instrumenter - What should be used to instrument all the things.
    #           :memoize - Should adapter be wrapped by memoize adapter or not.
    def initialize(adapter, options = {})
      @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
      memoize = options.fetch(:memoize, true)
      adapter = Adapters::Memoizable.new(adapter) if memoize
      @adapter = adapter
      @memoized_features = {}
    end

    # Public: Check if a feature is enabled.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the enabled check.
    #
    # Returns true if feature is enabled, false if not.
    def enabled?(name, *args)
      feature(name).enabled?(*args)
    end

    # Public: Enable a feature.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the feature instance enable call.
    #
    # Returns the result of the feature instance enable call.
    def enable(name, *args)
      feature(name).enable(*args)
    end

    # Public: Enable a feature for an actor.
    #
    # name - The String or Symbol name of the feature.
    # actor - a Flipper::Types::Actor instance or an object that responds
    #         to flipper_id.
    #
    # Returns result of Feature#enable.
    def enable_actor(name, actor)
      feature(name).enable_actor(actor)
    end

    # Public: Enable a feature for a group.
    #
    # name - The String or Symbol name of the feature.
    # group - a Flipper::Types::Group instance or a String or Symbol name of a
    #         registered group.
    #
    # Returns result of Feature#enable.
    def enable_group(name, group)
      feature(name).enable_group(group)
    end

    # Public: Enable a feature a percentage of time.
    #
    # name - The String or Symbol name of the feature.
    # percentage - a Flipper::Types::PercentageOfTime instance or an object
    #              that responds to to_i.
    #
    # Returns result of Feature#enable.
    def enable_percentage_of_time(name, percentage)
      feature(name).enable_percentage_of_time(percentage)
    end

    # Public: Enable a feature for a percentage of actors.
    #
    # name - The String or Symbol name of the feature.
    # percentage - a Flipper::Types::PercentageOfActors instance or an object
    #              that responds to to_i.
    #
    # Returns result of Feature#enable.
    def enable_percentage_of_actors(name, percentage)
      feature(name).enable_percentage_of_actors(percentage)
    end

    # Public: Disable a feature.
    #
    # name - The String or Symbol name of the feature.
    # args - The args passed through to the feature instance enable call.
    #
    # Returns the result of the feature instance disable call.
    def disable(name, *args)
      feature(name).disable(*args)
    end

    # Public: Disable a feature for an actor.
    #
    # name - The String or Symbol name of the feature.
    # actor - a Flipper::Types::Actor instance or an object that responds
    #         to flipper_id.
    #
    # Returns result of disable.
    def disable_actor(name, actor)
      feature(name).disable_actor(actor)
    end

    # Public: Disable a feature for a group.
    #
    # name - The String or Symbol name of the feature.
    # group - a Flipper::Types::Group instance or a String or Symbol name of a
    #         registered group.
    #
    # Returns result of disable.
    def disable_group(name, group)
      feature(name).disable_group(group)
    end

    # Public: Disable a feature a percentage of time.
    #
    # name - The String or Symbol name of the feature.
    # percentage - a Flipper::Types::PercentageOfTime instance or an object
    #              that responds to to_i.
    #
    # Returns result of disable.
    def disable_percentage_of_time(name)
      feature(name).disable_percentage_of_time
    end

    # Public: Disable a feature for a percentage of actors.
    #
    # name - The String or Symbol name of the feature.
    # percentage - a Flipper::Types::PercentageOfActors instance or an object
    #              that responds to to_i.
    #
    # Returns result of disable.
    def disable_percentage_of_actors(name)
      feature(name).disable_percentage_of_actors
    end

    # Public: Add a feature.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns result of add.
    def add(name)
      feature(name).add
    end

    # Public: Has a feature been added in the adapter.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns true if added else false.
    def exist?(name)
      feature(name).exist?
    end

    # Public: Remove a feature.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns result of remove.
    def remove(name)
      feature(name).remove
    end

    # Public: Access a feature instance by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Feature.
    def feature(name)
      if !name.is_a?(String) && !name.is_a?(Symbol)
        raise ArgumentError, "#{name} must be a String or Symbol"
      end

      @memoized_features[name.to_sym] ||= Feature.new(name, @adapter, instrumenter: instrumenter)
    end

    # Public: Preload the features with the given names.
    #
    # names - An Array of String or Symbol names of the features.
    #
    # Returns an Array of Flipper::Feature.
    def preload(names)
      features = names.map { |name| feature(name) }
      @adapter.get_multi(features)
      features
    end

    # Public: Preload all the adapters features.
    #
    # Returns an Array of Flipper::Feature.
    def preload_all
      keys = @adapter.get_all.keys
      keys.map { |key| feature(key) }
    end

    # Public: Shortcut access to a feature instance by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Feature.
    alias_method :[], :feature

    # Public: Shortcut for getting a boolean type instance.
    #
    # value - The true or false value for the boolean.
    #
    # Returns a Flipper::Types::Boolean instance.
    def boolean(value = true)
      Types::Boolean.new(value)
    end

    # Public: Even shorter shortcut for getting a boolean type instance.
    #
    # value - The true or false value for the boolean.
    #
    # Returns a Flipper::Types::Boolean instance.
    alias_method :bool, :boolean

    # Public: Access a flipper group by name.
    #
    # name - The String or Symbol name of the feature.
    #
    # Returns an instance of Flipper::Group.
    def group(name)
      Flipper.group(name)
    end

    # Public: Wraps an object as a flipper actor.
    #
    # thing - The object that you would like to wrap.
    #
    # Returns an instance of Flipper::Types::Actor.
    # Raises ArgumentError if thing does not respond to `flipper_id`.
    def actor(thing)
      Types::Actor.new(thing)
    end

    # Public: Shortcut for getting a percentage of time instance.
    #
    # number - The percentage of time that should be enabled.
    #
    # Returns Flipper::Types::PercentageOfTime.
    def time(number)
      Types::PercentageOfTime.new(number)
    end
    alias_method :percentage_of_time, :time

    # Public: Shortcut for getting a percentage of actors instance.
    #
    # number - The percentage of actors that should be enabled.
    #
    # Returns Flipper::Types::PercentageOfActors.
    def actors(number)
      Types::PercentageOfActors.new(number)
    end
    alias_method :percentage_of_actors, :actors

    # Public: Returns a Set of the known features for this adapter.
    #
    # Returns Set of Flipper::Feature instances.
    def features
      adapter.features.map { |name| feature(name) }.to_set
    end

    def import(flipper)
      adapter.import(flipper.adapter)
    end

    # Cloud DSL method that does nothing for open source version.
    def sync
    end

    # Cloud DSL method that does nothing for open source version.
    def sync_secret
    end
  end
end
