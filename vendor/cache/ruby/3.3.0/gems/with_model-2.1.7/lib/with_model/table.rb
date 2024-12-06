# frozen_string_literal: true

require 'active_record'

module WithModel
  # In general, direct use of this class should be avoided. Instead use
  # either the {WithModel high-level API} or {WithModel::Model::DSL low-level API}.
  class Table
    # @param [Symbol] name The name of the table to create.
    # @param options Passed to ActiveRecord `create_table`.
    # @param block Passed to ActiveRecord `create_table`.
    # @see https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table
    def initialize(name, options = {}, &block)
      @name = name.freeze
      @options = options.freeze
      @block = block
    end

    # Creates the table with the initialized options. Drops the table if
    # it already exists.
    def create
      connection.drop_table(@name) if exists?
      connection.create_table(@name, **@options, &@block)
    end

    def destroy
      connection.drop_table(@name)
    end

    private

    def exists?
      if connection.respond_to?(:data_source_exists?)
        connection.data_source_exists?(@name)
      else
        connection.table_exists?(@name)
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
