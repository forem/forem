class AddEventIdIndexToArticles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_articles_on_event_id_published_hotness_published_at".freeze
  INDEX_DEFINITION_SUFFIX = "USING btree (event_id, published, hotness_score DESC, published_at DESC) " \
                            "WHERE (event_id IS NOT NULL)".freeze
  LOOKUP_SQL = <<~SQL.squish.freeze
    SELECT format('%I.%I', n.nspname, c.relname) AS qualified_name,
           (i.indisvalid AND right(pg_get_indexdef(i.indexrelid), length($2) + 1) = (' ' || $2)) AS usable
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE i.indrelid = to_regclass('articles') AND c.relname = $1
  SQL

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        existing = find_index(conn)
        next if existing&.fetch("usable") == "t"

        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{existing['qualified_name']};") if existing
        conn.exec(
          "CREATE INDEX CONCURRENTLY #{INDEX_NAME} " \
          "ON articles (event_id, published, hotness_score DESC, published_at DESC) " \
          "WHERE (event_id IS NOT NULL);",
        )
      end
    end
  end

  def down
    safety_assured do
      with_zero_timeout_connection do |conn|
        existing = find_index(conn)
        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{existing['qualified_name']};") if existing
      end
    end
  end

  private

  def find_index(conn)
    conn.exec_params(LOOKUP_SQL, [INDEX_NAME, INDEX_DEFINITION_SUFFIX]).first
  end

  def with_zero_timeout_connection
    conn = open_zero_timeout_connection
    yield conn
  ensure
    conn&.close
  end

  # The timeout is a startup option of this dedicated session, so the DDL always runs with it and
  # it can never leak into a pooled backend (SET is unreliable under PgBouncer transaction pooling).
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
    raise ActiveRecord::MigrationError, "Could not open a direct zero-timeout session for #{INDEX_NAME}: #{e.message}"
  end
end
