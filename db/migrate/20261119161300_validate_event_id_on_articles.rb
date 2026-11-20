class ValidateEventIdOnArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  CONSTRAINT_LOOKUP_SQL = <<~SQL.squish.freeze
    SELECT format('%I.%I', n.nspname, t.relname) AS qualified_table,
           quote_ident(c.conname) AS quoted_constraint,
           c.convalidated
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
    WHERE c.conrelid = to_regclass('articles')
      AND c.confrelid = to_regclass('events')
      AND c.contype = 'f'
      AND array_length(c.conkey, 1) = 1
      AND a.attname = 'event_id'
  SQL

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        constraint = conn.exec(CONSTRAINT_LOOKUP_SQL).first
        unless constraint
          raise ActiveRecord::MigrationError,
                "Foreign key from articles.event_id to events not found"
        end
        next if constraint["convalidated"] == "t"

        conn.exec(
          "ALTER TABLE #{constraint['qualified_table']} " \
          "VALIDATE CONSTRAINT #{constraint['quoted_constraint']};",
        )
      end
    end
  end

  def down
    # Validating a foreign key constraint is irreversible in PostgreSQL.
  end

  private

  def with_zero_timeout_connection
    conn = open_zero_timeout_connection
    yield conn
  ensure
    conn&.close
  end

  # The timeout is a startup option of this dedicated session, so VALIDATE CONSTRAINT never hits
  # a pooled statement_timeout while scanning articles (SET is unreliable under PgBouncer pooling).
  def open_zero_timeout_connection
    params = connection.raw_connection.conninfo_hash.compact
    if params[:host].present?
      direct_host = params[:host].sub("-pooler", "")
      if direct_host != params[:host]
        params[:host] = direct_host
        params.delete(:hostaddr)
      end
    end
    params[:options] = [params[:options], "-c statement_timeout=0"].compact_blank.join(" ")
    PG::Connection.connect(params)
  rescue PG::Error => e
    raise ActiveRecord::MigrationError,
          "Could not open a direct zero-timeout session to validate articles.event_id foreign key: #{e.message}"
  end
end
