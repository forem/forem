module StrongMigrations
  self.error_messages = {
    add_column_default:
"Adding a column with a %{default_type} default blocks %{rewrite_blocks} while the entire table is rewritten.
Instead, add the column without a default value, then change the default.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def up
    %{add_command}
    %{change_command}
  end

  def down
    %{remove_command}
  end
end

Then backfill the existing rows in the Rails console or a separate migration with disable_ddl_transaction!.

class Backfill%{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def up
    %{code}
  end
end",

    add_column_default_null:
"Adding a column with a null default blocks %{rewrite_blocks} while the entire table is rewritten.
Instead, add the column without a default value.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{command}
  end
end",

    add_column_default_callable:
"Strong Migrations does not support inspecting callable default values.
Please make really sure you're not calling a VOLATILE function,
then wrap it in a safety_assured { ... } block.",

    add_column_json:
"There's no equality operator for the json column type, which can cause errors for
existing SELECT DISTINCT queries in your application. Use jsonb instead.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{command}
  end
end",

    add_column_generated_stored:
"Adding a stored generated column blocks %{rewrite_blocks} while the entire table is rewritten.",

    change_column:
"Changing the type of an existing column blocks %{rewrite_blocks}
while the entire table is rewritten. A safer approach is to:

1. Create a new column
2. Write to both columns
3. Backfill data from the old column to the new column
4. Move reads from the old column to the new column
5. Stop writing to the old column
6. Drop the old column",

    change_column_with_not_null:
"Changing the type is safe, but setting NOT NULL is not.",

    remove_column: "Active Record caches attributes, which causes problems
when removing columns. Be sure to ignore the column%{column_suffix}:

class %{model} < %{base_model}
  %{code}
end

Deploy the code, then wrap this step in a safety_assured { ... } block.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    safety_assured { %{command} }
  end
end",

    rename_column:
"Renaming a column that's in use will cause errors
in your application. A safer approach is to:

1. Create a new column
2. Write to both columns
3. Backfill data from the old column to the new column
4. Move reads from the old column to the new column
5. Stop writing to the old column
6. Drop the old column",

    rename_table:
"Renaming a table that's in use will cause errors
in your application. A safer approach is to:

1. Create a new table. Don't forget to recreate indexes from the old table
2. Write to both tables
3. Backfill data from the old table to the new table
4. Move reads from the old table to the new table
5. Stop writing to the old table
6. Drop the old table",

    add_reference:
"%{headline} Instead, use:

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def change
    %{command}
  end
end",

    add_index:
"Adding an index non-concurrently blocks writes. Instead, use:

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def change
    %{command}
  end
end",

    remove_index:
"Removing an index non-concurrently blocks writes. Instead, use:

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def change
    %{command}
  end
end",

    add_index_columns:
"Adding a non-unique index with more than three columns rarely improves performance.
Instead, start an index with columns that narrow down the results the most.",

    add_index_corruption:
"Adding an index concurrently can cause silent data corruption in Postgres 14.0 to 14.3.
Upgrade Postgres before adding new indexes, or wrap this step in a safety_assured { ... } block
to accept the risk.",

    change_table:
"Strong Migrations does not support inspecting what happens inside a
change_table block, so cannot help you here. Please make really sure that what
you're doing is safe before proceeding, then wrap it in a safety_assured { ... } block.",

    create_table:
"The force option will destroy existing tables.
If this is intended, drop the existing table first.
Otherwise, remove the force option.",

    execute:
"Strong Migrations does not support inspecting what happens inside an
execute call, so cannot help you here. Please make really sure that what
you're doing is safe before proceeding, then wrap it in a safety_assured { ... } block.",

    change_column_default:
"Partial writes are enabled, which can cause incorrect values
to be inserted when changing the default value of a column.
Disable partial writes in config/application.rb:

config.active_record.%{config} = false",

    change_column_null:
"Passing a default value to change_column_null runs a single UPDATE query,
which can cause downtime. Instead, backfill the existing rows in the
Rails console or a separate migration with disable_ddl_transaction!.

class Backfill%{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def up
    %{code}
  end
end",

    change_column_null_postgresql:
"Setting NOT NULL on an existing column blocks reads and writes while every row is checked.
Instead, add a check constraint and validate it in a separate migration.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{add_constraint_code}
  end
end

class Validate%{migration_name} < ActiveRecord::Migration%{migration_suffix}
  %{validate_constraint_code}
end",

    change_column_null_mysql:
"Setting NOT NULL on an existing column is not safe without strict mode enabled.",

    add_foreign_key:
"Adding a foreign key blocks writes on both tables. Instead,
add the foreign key without validating existing rows,
then validate them in a separate migration.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{add_foreign_key_code}
  end
end

class Validate%{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{validate_foreign_key_code}
  end
end",

    validate_foreign_key:
"Validating a foreign key while writes are blocked is dangerous.
Use disable_ddl_transaction! or a separate migration.",

    add_check_constraint:
"Adding a check constraint key blocks reads and writes while every row is checked.
Instead, add the check constraint without validating existing rows,
then validate them in a separate migration.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{add_check_constraint_code}
  end
end

class Validate%{migration_name} < ActiveRecord::Migration%{migration_suffix}
  def change
    %{validate_check_constraint_code}
  end
end",

    add_check_constraint_mysql:
"Adding a check constraint to an existing table is not safe with your database engine.",

    validate_check_constraint:
"Validating a check constraint while writes are blocked is dangerous.
Use disable_ddl_transaction! or a separate migration.",

    add_exclusion_constraint:
"Adding an exclusion constraint blocks reads and writes while every row is checked.",

    add_unique_constraint:
"Adding a unique constraint creates a unique index, which blocks reads and writes.
Instead, create a unique index concurrently, then use it for the constraint.

class %{migration_name} < ActiveRecord::Migration%{migration_suffix}
  disable_ddl_transaction!

  def up
    %{index_command}
    %{constraint_command}
  end

  def down
    %{remove_command}
  end
end"
  }
  self.enabled_checks = (error_messages.keys - [:remove_index]).map { |k| [k, {}] }.to_h
end
