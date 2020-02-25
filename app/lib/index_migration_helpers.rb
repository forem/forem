module IndexMigrationHelpers
  def add_index_if_missing(table_name, column_name, options = {})
    columns = Array(column_name)
    if options.key?(:name) && indexes(table_name).none? { |idx| idx.name == options[:name] }
      add_index(table_name, column_name, options)
    elsif indexes(table_name).none? { |idx| idx.columns.map(&:to_sym) == columns }
      add_index(table_name, column_name, options)
    end
  end

  def remove_index_if_exists(table_name, options = {})
    columns = Array(options[:column])
    if options.key?(:name) && indexes(table_name).any? { |idx| idx.name == options[:name] }
      remove_index(table_name, options)
    elsif indexes(table_name).any? { |idx| idx.columns.map(&:to_sym) == columns }
      remove_index(table_name, options)
    end
  end
end
