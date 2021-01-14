require 'delegate'

module FixDBSchemaConflicts
  module SchemaDumper
    class ConnectionWithSorting < SimpleDelegator
      def extensions
        __getobj__.extensions.sort
      end

      def columns(table)
        __getobj__.columns(table).sort_by(&:name)
      end

      def indexes(table)
        __getobj__.indexes(table).sort_by(&:name)
      end

      def foreign_keys(table)
        __getobj__.indexes(table).sort_by(&:name)
      end
    end

    def extensions(*args)
      with_sorting do
        super(*args)
      end
    end

    def table(*args)
      with_sorting do
        super(*args)
      end
    end

    def with_sorting
      old, @connection = @connection, ConnectionWithSorting.new(@connection)
      result = yield
      @connection = old
      result
    end
  end
end

ActiveRecord::SchemaDumper.send(:prepend, FixDBSchemaConflicts::SchemaDumper)
