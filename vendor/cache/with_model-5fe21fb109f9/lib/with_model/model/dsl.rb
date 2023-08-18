# frozen_string_literal: true

module WithModel
  class Model
    class DSL
      # @param model [WithModel::Model] The Model to mutate via this DSL.
      def initialize(model)
        @model = model
      end

      # Provide a schema definition for the table, passed to ActiveRecord's `create_table`.
      # The table name will be auto-generated.
      #
      # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table
      def table(options = {}, &block)
        @model.table_options = options
        @model.table_block = block
      end

      # Provide a class body for the ActiveRecord model.
      def model(&block)
        @model.model_block = block
      end
    end
  end
end
