module Blazer
  module Adapters
    class MongodbAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          documents = db.command({:$eval => "#{statement.strip}.toArray()", nolock: true}).documents.first["retval"]
          columns = documents.flat_map { |r| r.keys }.uniq
          rows = documents.map { |r| columns.map { |c| r[c] } }
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        db.collection_names
      end

      def preview_statement
        "db.{table}.find().limit(10)"
      end

      def quoting
        :backslash_escape
      end

      protected

      def client
        @client ||= Mongo::Client.new(settings["url"], connect_timeout: 1, socket_timeout: 1, server_selection_timeout: 1)
      end

      def db
        @db ||= client.database
      end
    end
  end
end
