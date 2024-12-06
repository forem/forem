# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Format an object that has an id as a hash with keys for class and id. This formatter is useful
    # as a default formatter for objects pulled from a data store. By default it will use :id as the
    # id attribute.
    class IdFormatter
      # @param [Symbol, String] id_attribute The attribute to use as the id.
      def initialize(id_attribute = :id)
        @id_attribute = id_attribute
      end

      def call(obj)
        if obj.respond_to?(@id_attribute)
          id = obj.send(@id_attribute)
          {"class" => obj.class.name, "id" => id}
        else
          obj.to_s
        end
      end
    end
  end
end
