# frozen_string_literal: true

require 'i18n/tasks/scanners/results/occurrence'

module I18n::Tasks::Scanners::AstMatchers
  class RailsModelMatcher < BaseMatcher
    def convert_to_key_occurrences(send_node, _method_name, location: send_node.loc)
      human_attribute_name_to_key_occurences(send_node: send_node, location: location) ||
        model_name_human_to_key_occurences(send_node: send_node, location: location)
    end

    private

    def human_attribute_name_to_key_occurences(send_node:, location:)
      children = Array(send_node&.children)
      receiver = children[0]
      method_name = children[1]

      return unless method_name == :human_attribute_name && receiver.type == :const

      value = children[2]

      model_name = underscore(receiver.to_a.last)
      attribute = extract_string(value)
      key = "activerecord.attributes.#{model_name}.#{attribute}"
      [
        key,
        I18n::Tasks::Scanners::Results::Occurrence.from_range(
          raw_key: key,
          range: location.expression
        )
      ]
    end

    # User.model_name.human(count: 2)
    # s(:send,
    #   s(:send,
    #     s(:const, nil, :User), :model_name), :human,
    #   s(:hash,
    #     s(:pair,
    #       s(:sym, :count),
    #       s(:int, 2))))
    def model_name_human_to_key_occurences(send_node:, location:)
      children = Array(send_node&.children)
      return unless children[1] == :human

      base_children = Array(children[0]&.children)
      class_node = base_children[0]

      return unless class_node&.type == :const && base_children[1] == :model_name

      model_name = underscore(class_node.to_a.last)
      key = "activerecord.models.#{model_name}"
      [
        key,
        I18n::Tasks::Scanners::Results::Occurrence.from_range(
          raw_key: key,
          range: location.expression
        )
      ]
    end

    def underscore(value)
      value = value.dup.to_s
      value.gsub!(/(.)([A-Z])/, '\1_\2')
      value.downcase!
    end
  end
end
