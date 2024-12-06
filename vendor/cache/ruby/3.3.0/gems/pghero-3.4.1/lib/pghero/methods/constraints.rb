module PgHero
  module Methods
    module Constraints
      # referenced fields can be nil
      # as not all constraints are foreign keys
      def invalid_constraints
        select_all <<~SQL
          SELECT
            nsp.nspname AS schema,
            rel.relname AS table,
            con.conname AS name,
            fnsp.nspname AS referenced_schema,
            frel.relname AS referenced_table
          FROM
            pg_catalog.pg_constraint con
          INNER JOIN
            pg_catalog.pg_class rel ON rel.oid = con.conrelid
          LEFT JOIN
            pg_catalog.pg_class frel ON frel.oid = con.confrelid
          LEFT JOIN
            pg_catalog.pg_namespace nsp ON nsp.oid = con.connamespace
          LEFT JOIN
            pg_catalog.pg_namespace fnsp ON fnsp.oid = frel.relnamespace
          WHERE
            con.convalidated = 'f'
        SQL
      end
    end
  end
end
