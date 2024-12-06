# dependencies
require "active_support"

# modules
require "hypershield/migration"
require "hypershield/version"

# integrations
require "hypershield/engine" if defined?(Rails)

module Hypershield
  class << self
    attr_accessor :enabled, :log_sql, :schemas
  end
  self.enabled = true
  self.log_sql = false
  self.schemas = {
    hypershield: {
      hide: %w(encrypted password token secret),
      show: []
    }
  }

  class << self
    def drop_view(view)
      schemas.each do |schema, _|
        execute("DROP VIEW IF EXISTS #{quote_ident(schema)}.#{quote_ident(view)}")
      end
    end

    def refresh(dry_run: false)
      if adapter_name =~ /sqlite/i
        raise "Adapter not supported: #{adapter_name}"
      end

      quiet_logging do
        statements = []

        schemas.each do |schema, config|
          hide = config[:hide].to_a
          show = config[:show].to_a

          hypershield_tables = tables(schema)

          tables.sort_by { |k, _| k }.each do |table, columns|
            next if table == "pg_stat_statements"

            columns.reject! do |column|
              hide.any? { |m| "#{table}.#{column}".include?(m) } &&
                !show.any? { |m| "#{table}.#{column}".include?(m) }
            end

            # if the hypershield view has the same columns, assume it doesn't need updated
            # this may not necessarily be true if someone manually updates the view
            # we could check the view definition, but this is harder as the database normalizes it
            next if hypershield_tables[table] == columns

            statements << "DROP VIEW IF EXISTS #{quote_ident(schema)}.#{quote_ident(table)} CASCADE"

            if columns.any?
              statements << "CREATE VIEW #{quote_ident(schema)}.#{quote_ident(table)} AS SELECT #{columns.map { |c| quote_ident(c) }.join(", ")} FROM #{quote_ident(table)}"
            end
          end
        end

        if dry_run
          if statements.any?
            puts statements.map { |v| "#{v};" }.join("\n")
          end
        else
          # originally this was performed in a transaction
          # however, this appears to cause issues in certain situations - see #5 and #6
          # this shouldn't be a huge issue now that we only update specific views
          # we already drop views outside of the transaction when migrations are run
          statements.each do |statement|
            execute(statement)
          end
        end
      end
    end

    private

    def quiet_logging
      if ActiveRecord::Base.logger && !log_sql
        previous_level = ActiveRecord::Base.logger.level
        begin
          ActiveRecord::Base.logger.level = Logger::INFO
          yield
        ensure
          ActiveRecord::Base.logger.level = previous_level
        end
      else
        yield
      end
    end

    def connection
      ActiveRecord::Base.connection
    end

    def adapter_name
      connection.adapter_name
    end

    def mysql?
      adapter_name =~ /mysql/i
    end

    def tables(schema = nil)
      if schema
        schema = quote(schema)
      else
        schema =
          if mysql?
            "database()"
          else
            "'public'"
          end
      end

      query = <<-SQL
        SELECT
          table_name,
          column_name,
          ordinal_position,
          data_type
        FROM
          information_schema.columns
        WHERE
          table_schema = #{schema}
      SQL

      select_all(query.squish)
        .map { |c| c.transform_keys(&:downcase) }
        .group_by { |c| c["table_name"] }
        .map { |t, cs| [t, cs.sort_by { |c| c["ordinal_position"].to_i }.map { |c| c["column_name"] }] }
        .to_h
    end

    def select_all(sql)
      connection.select_all(sql).to_a
    end

    def execute(sql)
      connection.execute(sql)
    end

    def quote(literal)
      connection.quote(literal)
    end

    def quote_ident(ident)
      connection.quote_table_name(ident.to_s)
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Migration.prepend(Hypershield::Migration)
end
