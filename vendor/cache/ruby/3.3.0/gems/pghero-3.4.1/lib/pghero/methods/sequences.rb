module PgHero
  module Methods
    module Sequences
      def sequences
        # get columns with default values
        # use pg_get_expr to get correct default value
        # it's what information_schema.columns uses
        # also, exclude temporary tables to prevent error
        # when accessing across sessions
        sequences = select_all <<~SQL
          SELECT
            n.nspname AS table_schema,
            c.relname AS table,
            attname AS column,
            format_type(a.atttypid, a.atttypmod) AS column_type,
            pg_get_expr(d.adbin, d.adrelid) AS default_value
          FROM
            pg_catalog.pg_attribute a
          INNER JOIN
            pg_catalog.pg_class c ON c.oid = a.attrelid
          INNER JOIN
            pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          INNER JOIN
            pg_catalog.pg_attrdef d ON (a.attrelid, a.attnum) = (d.adrelid,  d.adnum)
          WHERE
            NOT a.attisdropped
            AND a.attnum > 0
            AND pg_get_expr(d.adbin, d.adrelid) LIKE 'nextval%'
            AND n.nspname NOT LIKE 'pg\\_temp\\_%'
        SQL

        # parse out sequence
        sequences.each do |column|
          column[:max_value] = column[:column_type] == 'integer' ? 2147483647 : 9223372036854775807

          column[:schema], column[:sequence] = parse_default_value(column[:default_value])
          column.delete(:default_value) if column[:sequence]
        end

        add_sequence_attributes(sequences)

        sequences.select { |s| s[:readable] }.each_slice(1024) do |slice|
          sql = slice.map { |s| "SELECT last_value FROM #{quote_ident(s[:schema])}.#{quote_ident(s[:sequence])}" }.join(" UNION ALL ")

          select_all(sql).zip(slice) do |row, seq|
            seq[:last_value] = row[:last_value]
          end
        end

        # use to_s for unparsable sequences
        sequences.sort_by { |s| s[:sequence].to_s }
      end

      def sequence_danger(threshold: 0.9, sequences: nil)
        sequences ||= self.sequences
        sequences.select { |s| s[:last_value] && s[:last_value] / s[:max_value].to_f > threshold }.sort_by { |s| s[:max_value] - s[:last_value] }
      end

      private

      # can parse
      # nextval('id_seq'::regclass)
      # nextval(('id_seq'::text)::regclass)
      def parse_default_value(default_value)
        m = /^nextval\('(.+)'\:\:regclass\)$/.match(default_value)
        m = /^nextval\(\('(.+)'\:\:text\)\:\:regclass\)$/.match(default_value) unless m
        if m
          unquote_ident(m[1])
        else
          []
        end
      end

      def unquote_ident(value)
        schema, seq = value.split(".")
        unless seq
          seq = schema
          schema = nil
        end
        [unquote(schema), unquote(seq)]
      end

      # adds readable attribute to all sequences
      # also adds schema if missing
      def add_sequence_attributes(sequences)
        # fetch data
        sequence_attributes = select_all <<~SQL
          SELECT
            n.nspname AS schema,
            c.relname AS sequence,
            has_sequence_privilege(c.oid, 'SELECT') AS readable
          FROM
            pg_class c
          INNER JOIN
            pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          WHERE
            c.relkind = 'S'
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
        SQL

        # first populate missing schemas
        missing_schema = sequences.select { |s| s[:schema].nil? && s[:sequence] }
        if missing_schema.any?
          sequence_schemas = sequence_attributes.group_by { |s| s[:sequence] }

          missing_schema.each do |sequence|
            schemas = sequence_schemas[sequence[:sequence]] || []

            if schemas.size == 1
              sequence[:schema] = schemas[0][:schema]
            end
            # otherwise, do nothing, will be marked as unreadable
            # TODO better message for multiple schemas
          end
        end

        # then populate attributes
        readable = sequence_attributes.to_h { |s| [[s[:schema], s[:sequence]], s[:readable]] }
        sequences.each do |sequence|
          sequence[:readable] = readable[[sequence[:schema], sequence[:sequence]]] || false
        end
      end
    end
  end
end
