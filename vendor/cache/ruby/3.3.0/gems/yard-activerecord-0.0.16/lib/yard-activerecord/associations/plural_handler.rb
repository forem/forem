require_relative 'base'

module YARD::Handlers::Ruby::ActiveRecord::Associations
  class PluralHandler < Base
    def class_name
      "ActiveRecord::Relation<#{super(true)}>"
    end

    private
    def return_description
      "A relationship to the associated #{method_name.humanize} that can have further scopes chained on it or converted to an array with #to_a"
    end
  end
end
