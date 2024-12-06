# frozen_string_literal: true

module RuboCop
  # Find duplicated keys from YAML.
  # @api private
  module YAMLDuplicationChecker
    def self.check(yaml_string, filename, &on_duplicated)
      # Ruby 2.6+
      tree = if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0')
               # Specify filename to display helpful message when it raises
               # an error.
               YAML.parse(yaml_string, filename: filename)
             else
               YAML.parse(yaml_string, filename)
             end
      return unless tree

      traverse(tree, &on_duplicated)
    end

    def self.traverse(tree, &on_duplicated)
      case tree
      when Psych::Nodes::Mapping
        tree.children.each_slice(2).with_object([]) do |(key, value), keys|
          exist = keys.find { |key2| key2.value == key.value }
          yield(exist, key) if exist
          keys << key
          traverse(value, &on_duplicated)
        end
      else
        children = tree.children
        return unless children

        children.each { |c| traverse(c, &on_duplicated) }
      end
    end

    private_class_method :traverse
  end
end
