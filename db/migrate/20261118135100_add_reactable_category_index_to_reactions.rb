class AddReactableCategoryIndexToReactions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_reactions_on_reactable_id_type_and_category".freeze
  INDEX_DEFINITION_SUFFIX = "USING btree (reactable_id, reactable_type, category)".freeze
  # Scoped to the resolved `reactions` table OID so a same-named index elsewhere is never touched.
  LOOKUP_SQL = <<~SQL.squish.freeze
    SELECT format('%I.%I', n.nspname, c.relname) AS qualified_name,
           (i.indisvalid AND pg_get_indexdef(i.indexrelid) LIKE ('% ' || $2)) AS usable
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE i.indrelid = to_regclass('reactions') AND c.relname = $1
  SQL

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        existing = find_index(conn)
        next if existing&.fetch("usable") == "t"

        conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{existing['qualified_name']};") if existing
        conn.exec("CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON reactions (reactable_id, reactable_type, category);")
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
    params[:host] = params[:host].sub("-pooler", "") if params[:host].present?
    params[:options] = [params[:options], "-c statement_timeout=0"].compact_blank.join(" ")
    PG::Connection.connect(params)
  rescue PG::Error => e
    raise ActiveRecord::MigrationError, "Could not open a direct zero-timeout session for #{INDEX_NAME}: #{e.message}"
  end
end
