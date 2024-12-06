require 'delegate'
require 'flipper/ui/decorators/gate'
require 'flipper/ui/util'

module Flipper
  module UI
    module Decorators
      class Feature < SimpleDelegator
        include Comparable

        # Public: The feature being decorated.
        alias_method :feature, :__getobj__

        # Internal: Used to preload description if descriptions_source is
        # configured for Flipper::UI.
        attr_accessor :description

        # Public: Returns name titleized.
        def pretty_name
          @pretty_name ||= Util.titleize(name)
        end

        def color_class
          case feature.state
          when :on
            'bg-success'
          when :off
            'bg-danger'
          when :conditional
            'bg-warning'
          end
        end

        def gates_in_words
          return "Fully Enabled" if feature.boolean_value

          statuses = []

          if feature.actors_value.count > 0
            statuses << %Q(<span data-toggle="tooltip" data-placement="bottom" title="#{Util.to_sentence(feature.actors_value.to_a)}">) + Util.pluralize(feature.actors_value.count, 'actor', 'actors') + "</span>"
          end

          if feature.groups_value.count > 0
            statuses << %Q(<span data-toggle="tooltip" data-placement="bottom" title="#{Util.to_sentence(feature.groups_value.to_a)}">) + Util.pluralize(feature.groups_value.count, 'group', 'groups') + "</span>"
          end

          if feature.percentage_of_actors_value > 0
            statuses << "#{feature.percentage_of_actors_value}% of actors"
          end

          if feature.percentage_of_time_value > 0
            statuses << "#{feature.percentage_of_time_value}% of time"
          end

          Util.to_sentence(statuses)
        end

        def gate_state_title
          case feature.state
          when :on
            "Fully enabled"
          when :conditional
            "Conditionally enabled"
          else
            "Disabled"
          end
        end

        def pretty_enabled_gate_names
          enabled_gates.map { |gate| Util.titleize(gate.key) }.sort.join(', ')
        end

        StateSortMap = {
          on: 1,
          conditional: 2,
          off: 3,
        }.freeze

        def <=>(other)
          if state == other.state
            key <=> other.key
          else
            StateSortMap[state] <=> StateSortMap[other.state]
          end
        end
      end
    end
  end
end
