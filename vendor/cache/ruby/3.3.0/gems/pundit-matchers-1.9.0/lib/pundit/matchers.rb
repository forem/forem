require 'rspec/core'

module Pundit
  module Matchers
    require_relative 'matchers/utils/policy_info'
    require_relative 'matchers/utils/all_actions/forbidden_actions_error_formatter'
    require_relative 'matchers/utils/all_actions/forbidden_actions_matcher'
    require_relative 'matchers/utils/all_actions/permitted_actions_error_formatter'
    require_relative 'matchers/utils/all_actions/permitted_actions_matcher'

    class Configuration
      attr_accessor :user_alias

      def initialize
        @user_alias = :user
      end
    end

    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Pundit::Matchers::Configuration.new
      end
    end

    RSpec::Matchers.define :forbid_action do |action, *args|
      match do |policy|
        if args.any?
          !policy.public_send("#{action}?", *args)
        else
          !policy.public_send("#{action}?")
        end
      end

      failure_message do |policy|
        "#{policy.class} does not forbid #{action} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end

      failure_message_when_negated do |policy|
        "#{policy.class} does not permit #{action} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end
  end

  RSpec::Matchers.define :forbid_actions do |*actions|
    actions.flatten!
    match do |policy|
      return false if actions.count < 1
      @allowed_actions = actions.select do |action|
        policy.public_send("#{action}?")
      end
      @allowed_actions.empty?
    end

    attr_reader :allowed_actions

    zero_actions_failure_message = 'At least one action must be ' \
      'specified when using the forbid_actions matcher.'

    failure_message do |policy|
      if actions.count.zero?
        zero_actions_failure_message
      else
        "#{policy.class} expected to forbid #{actions}, but allowed " \
          "#{allowed_actions} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end

    failure_message_when_negated do |policy|
      if actions.count.zero?
        zero_actions_failure_message
      else
        "#{policy.class} expected to permit #{actions}, but forbade " \
          "#{allowed_actions} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end
  end

  RSpec::Matchers.define :forbid_edit_and_update_actions do
    match do |policy|
      !policy.edit? && !policy.update?
    end

    failure_message do |policy|
      "#{policy.class} does not forbid the edit or update action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end

    failure_message_when_negated do |policy|
      "#{policy.class} does not permit the edit or update action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end
  end

  RSpec::Matchers.define :forbid_mass_assignment_of do |attributes|
    # Map single object argument to an array, if necessary
    attributes = attributes.is_a?(Array) ? attributes : [attributes]

    match do |policy|
      return false if attributes.count < 1

      @allowed_attributes = attributes.select do |attribute|
        if defined? @action
          policy.send("permitted_attributes_for_#{@action}").include? attribute
        else
          policy.permitted_attributes.include? attribute
        end
      end

      @allowed_attributes.empty?
    end

    attr_reader :allowed_attributes

    chain :for_action do |action|
      @action = action
    end

    zero_attributes_failure_message = 'At least one attribute must be ' \
      'specified when using the forbid_mass_assignment_of matcher.'

    failure_message do |policy|
      if attributes.count.zero?
        zero_attributes_failure_message
      elsif defined? @action
        "#{policy.class} expected to forbid the mass assignment of the " \
          "attributes #{attributes} when authorising the #{@action} action, " \
          'but allowed the mass assignment of the attributes ' \
          "#{allowed_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      else
        "#{policy.class} expected to forbid the mass assignment of the " \
          "attributes #{attributes}, but allowed the mass assignment of " \
          "the attributes #{allowed_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end

    failure_message_when_negated do |policy|
      if attributes.count.zero?
        zero_attributes_failure_message
      elsif defined? @action
        "#{policy.class} expected to permit the mass assignment of the " \
          "attributes #{attributes} when authorising the #{@action} action, " \
          'but permitted the mass assignment of the attributes ' \
          "#{allowed_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      else
        "#{policy.class} expected to permit the mass assignment of the " \
          "attributes #{attributes}, but permitted the mass assignment of " \
          "the attributes #{allowed_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end
  end

  RSpec::Matchers.define :forbid_new_and_create_actions do
    match do |policy|
      !policy.new? && !policy.create?
    end

    failure_message do |policy|
      "#{policy.class} does not forbid the new or create action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end

    failure_message_when_negated do |policy|
      "#{policy.class} does not permit the new or create action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end
  end

  RSpec::Matchers.define :permit_action do |action, *args|
    match do |policy|
      if args.any?
        policy.public_send("#{action}?", *args)
      else
        policy.public_send("#{action}?")
      end
    end

    failure_message do |policy|
      "#{policy.class} does not permit #{action} for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end

    failure_message_when_negated do |policy|
      "#{policy.class} does not forbid #{action} for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end
  end

  RSpec::Matchers.define :permit_actions do |*actions|
    actions.flatten!
    match do |policy|
      return false if actions.count < 1
      @forbidden_actions = actions.reject do |action|
        policy.public_send("#{action}?")
      end
      @forbidden_actions.empty?
    end

    match_when_negated do |policy|
      ::Kernel.warn 'Using expect { }.not_to permit_actions could produce \
        confusing results. Please use `.to forbid_actions` instead. To \
        clarify, `.not_to permit_actions` will look at all of the actions and \
        checks if ANY actions fail, not if all actions fail. Therefore, you \
        could result in something like this: \

        it { is_expected.to permit_actions([:new, :create, :edit]) } \
        it { is_expected.not_to permit_actions([:edit, :destroy]) } \

        In this case, edit would be true and destroy would be false, but both \
        tests would pass.'

      return true if actions.count < 1
      @forbidden_actions = actions.reject do |action|
        policy.public_send("#{action}?")
      end
      !@forbidden_actions.empty?
    end

    attr_reader :forbidden_actions

    zero_actions_failure_message = 'At least one action must be specified ' \
      'when using the permit_actions matcher.'

    failure_message do |policy|
      if actions.count.zero?
        zero_actions_failure_message
      else
        "#{policy.class} expected to permit #{actions}, but forbade " \
          "#{forbidden_actions} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end

    failure_message_when_negated do |policy|
      if actions.count.zero?
        zero_actions_failure_message
      else
        "#{policy.class} expected to forbid #{actions}, but allowed " \
          "#{forbidden_actions} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end
  end

  RSpec::Matchers.define :permit_edit_and_update_actions do
    match do |policy|
      policy.edit? && policy.update?
    end

    failure_message do |policy|
      "#{policy.class} does not permit the edit or update action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end

    failure_message_when_negated do |policy|
      "#{policy.class} does not forbid the edit or update action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end
  end

  RSpec::Matchers.define :permit_mass_assignment_of do |attributes|
    # Map single object argument to an array, if necessary
    attributes = attributes.is_a?(Array) ? attributes : [attributes]

    match do |policy|
      return false if attributes.count < 1

      @forbidden_attributes = attributes.select do |attribute|
        if defined? @action
          !policy.send("permitted_attributes_for_#{@action}").include? attribute
        else
          !policy.permitted_attributes.include? attribute
        end
      end

      @forbidden_attributes.empty?
    end

    attr_reader :forbidden_attributes

    chain :for_action do |action|
      @action = action
    end

    zero_attributes_failure_message = 'At least one attribute must be ' \
      'specified when using the permit_mass_assignment_of matcher.'

    failure_message do |policy|
      if attributes.count.zero?
        zero_attributes_failure_message
      elsif defined? @action
        "#{policy.class} expected to permit the mass assignment of the " \
          "attributes #{attributes} when authorising the #{@action} action, " \
          'but forbade the mass assignment of the attributes ' \
          "#{forbidden_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      else
        "#{policy.class} expected to permit the mass assignment of the " \
          "attributes #{attributes}, but forbade the mass assignment of the " \
          "attributes #{forbidden_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end

    failure_message_when_negated do |policy|
      if attributes.count.zero?
        zero_attributes_failure_message
      elsif defined? @action
        "#{policy.class} expected to forbid the mass assignment of the " \
          "attributes #{attributes} when authorising the #{@action} action, " \
          'but forbade the mass assignment of the attributes ' \
          "#{forbidden_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      else
        "#{policy.class} expected to forbid the mass assignment of the " \
          "attributes #{attributes}, but forbade the mass assignment of the " \
          "attributes #{forbidden_attributes} for " +
          policy.public_send(Pundit::Matchers.configuration.user_alias)
                .inspect + '.'
      end
    end
  end

  RSpec::Matchers.define :permit_new_and_create_actions do
    match do |policy|
      policy.new? && policy.create?
    end

    failure_message do |policy|
      "#{policy.class} does not permit the new or create action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end

    failure_message_when_negated do |policy|
      "#{policy.class} does not forbid the new or create action for " +
        policy.public_send(Pundit::Matchers.configuration.user_alias)
              .inspect + '.'
    end
  end

  RSpec::Matchers.define :permit_all_actions do
    match do |policy|
      @matcher = Pundit::Matchers::Utils::AllActions::PermittedActionsMatcher.new(policy)
      @matcher.match?
    end

    failure_message do
      formatter = Pundit::Matchers::Utils::AllActions::PermittedActionsErrorFormatter.new(@matcher)
      formatter.message
    end
  end

  RSpec::Matchers.define :forbid_all_actions do
    match do |policy|
      @matcher = Pundit::Matchers::Utils::AllActions::ForbiddenActionsMatcher.new(policy)
      @matcher.match?
    end

    failure_message do
      formatter = Pundit::Matchers::Utils::AllActions::ForbiddenActionsErrorFormatter.new(@matcher)
      formatter.message
    end
  end
end

if defined?(Pundit)
  RSpec.configure do |config|
    config.include Pundit::Matchers
  end
end
