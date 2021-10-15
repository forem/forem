class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Purgeable

  # see <https://www.postgresql.org/docs/11/catalog-pg-class.html> for details
  # on the `pg_class` table
  QUERY_ESTIMATED_COUNT = <<~SQL.squish.freeze
    SELECT (
      (reltuples / GREATEST(relpages, 1)) *
      (pg_relation_size(?) / (GREATEST(current_setting('block_size')::integer, 1)))
    )::bigint AS count
    FROM pg_class
    WHERE relname = ? AND relkind = 'r';
  SQL

  # Computes an estimated count of the number of rows using stats collected by VACUUM
  # inspired by <https://www.citusdata.com/blog/2016/10/12/count-performance/#dup_counts_estimated_full>
  # and <https://stackoverflow.com/a/48391562/4186181>
  def self.estimated_count
    query = sanitize_sql_array([QUERY_ESTIMATED_COUNT, table_name, table_name])
    result = connection.execute(query)

    count = result.first["count"]
    result.clear # PG::Result is manually managed in memory, we need to release its resources
    count
  end

  # Decorate object with appropriate decorator
  def decorate
    self.class.decorator_class.new(self)
  end

  def decorated?
    false
  end

  # Decorate collection with appropriate decorator
  def self.decorate
    decorator_class.decorate_collection(all)
  end

  # Infers the decorator class to be used by (e.g. `User` maps to `UserDecorator`).
  # adapted from https://github.com/drapergem/draper/blob/157eb955072a941e6455e0121fca09a989fcbc21/lib/draper/decoratable.rb#L71
  def self.decorator_class(called_on = self)
    prefix = respond_to?(:model_name) ? model_name : name
    decorator_name = "#{prefix}Decorator"
    decorator_name_constant = decorator_name.safe_constantize
    return decorator_name_constant unless decorator_name_constant.nil?

    return superclass.decorator_class(called_on) if superclass.respond_to?(:decorator_class)

    raise UninferrableDecoratorError, "Could not infer a decorator for #{called_on.class.name}."
  end

  def self.statement_timeout
    connection.execute("SELECT setting FROM pg_settings WHERE name = 'statement_timeout'")
      .first["setting"]
      .to_i
      .seconds / 1000
  end

  def self.with_statement_timeout(duration)
    # Using SET LOCAL only works inside a transaction.
    transaction do
      original_timeout = statement_timeout
      milliseconds = (duration.to_f * 1000).to_i
      connection.execute "SET LOCAL statement_timeout = #{milliseconds}"
      yield
    ensure
      # Typically this value is reset after a transaction is completed (whether
      # successfully or unsuccessfully), but a nested transaction will not reset
      # this value after the inner transaction is complete because they are not
      # isolated from the outer transaction the way the outer transaction is
      # from transactions on other connections. Nested transactions are
      # implemented simply as savepoints inside the top-level transaction. For
      # this reason, we need to explicitly reset the statement timeout so that
      # when the block completes the statement timeout is reset to its previous
      # value.
      #
      # See: https://www.postgresql.org/docs/11/sql-savepoint.html
      milliseconds = original_timeout.to_i * 1000
      connection.execute "SET LOCAL statement_timeout = #{milliseconds}"
    end
  end

  def errors_as_sentence
    errors.full_messages.to_sentence
  end
end
