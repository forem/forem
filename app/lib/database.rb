# Database related utility functionsc
class Database
  # Checks if the database is ready and the specified table exists. This can be
  # useful during bin/setup and similar tasks. It also works if the connection
  # hasn't been established yet.
  #
  # @param table [String] the name of the table to check for
  def self.table_available?(table)
    available_tables[table] ||=
      ActiveRecord::Base.connection.table_exists?(table)
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    false
  end

  def self.available_tables
    @available_tables ||= {}
  end
  private_class_method :available_tables
end
