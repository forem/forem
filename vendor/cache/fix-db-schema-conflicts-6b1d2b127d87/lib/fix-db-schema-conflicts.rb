require 'fix_db_schema_conflicts/schema_dumper.rb'

module FixDBSchemaConflicts
  require 'fix_db_schema_conflicts/railtie' if defined?(Rails)
end
