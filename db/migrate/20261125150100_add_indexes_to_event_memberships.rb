class AddIndexesToEventMemberships < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEXES = [
    {
      name: "index_event_memberships_on_parent_and_child",
      unique: true,
      definition_suffix: "USING btree (parent_event_id, child_event_id)",
      create_sql: "CREATE UNIQUE INDEX CONCURRENTLY index_event_memberships_on_parent_and_child " \
                  "ON event_memberships (parent_event_id, child_event_id);"
    },
    {
      name: "index_event_memberships_on_parent_position_id",
      unique: false,
      definition_suffix: 'USING btree (parent_event_id, "position", id)',
      create_sql: 'CREATE INDEX CONCURRENTLY index_event_memberships_on_parent_position_id ' \
                  'ON event_memberships (parent_event_id, "position", id);'
    },
    {
      name: "index_event_memberships_on_child_and_parent",
      unique: false,
      definition_suffix: "USING btree (child_event_id, parent_event_id)",
      create_sql: "CREATE INDEX CONCURRENTLY index_event_memberships_on_child_and_parent " \
                  "ON event_memberships (child_event_id, parent_event_id);"
    },
  ].freeze

  LOOKUP_SQL = <<~SQL.squish.freeze
    SELECT format('%I.%I', n.nspname, c.relname) AS qualified_name,
           (i.indisvalid
            AND i.indisunique = $3::boolean
            AND right(pg_get_indexdef(i.indexrelid), length($2) + 1) = (' ' || $2)) AS usable
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE i.indrelid = to_regclass('event_memberships') AND c.relname = $1
  SQL

  def up
    safety_assured do
      with_zero_timeout_connection do |conn|
        INDEXES.each do |spec|
          existing = find_index(conn, spec)
          next if existing&.fetch("usable") == "t"

          conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{existing['qualified_name']};") if existing
          conn.exec(spec[:create_sql])
        end
      end
    end
  end

  def down
    safety_assured do
      with_zero_timeout_connection do |conn|
        INDEXES.reverse_each do |spec|
          existing = find_index(conn, spec)
          conn.exec("DROP INDEX CONCURRENTLY IF EXISTS #{existing['qualified_name']};") if existing
        end
      end
    end
  end

  private

  def find_index(conn, spec)
    conn.exec_params(LOOKUP_SQL, [spec[:name], spec[:definition_suffix], spec[:unique]]).first
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
    raise ActiveRecord::MigrationError,
          "Could not open a direct zero-timeout session for event_memberships indexes: #{e.message}"
  end
end
