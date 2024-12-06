module StrongMigrations
  module SafeMethods
    def safe_by_default_method?(method)
      StrongMigrations.safe_by_default && [:add_index, :add_belongs_to, :add_reference, :remove_index, :add_foreign_key, :add_check_constraint, :change_column_null].include?(method)
    end

    # TODO check if invalid index with expected name exists and remove if needed
    def safe_add_index(*args, **options)
      disable_transaction
      @migration.add_index(*args, **options.merge(algorithm: :concurrently))
    end

    def safe_remove_index(*args, **options)
      disable_transaction
      @migration.remove_index(*args, **options.merge(algorithm: :concurrently))
    end

    def safe_add_reference(table, reference, *args, **options)
      @migration.reversible do |dir|
        dir.up do
          disable_transaction
          foreign_key = options.delete(:foreign_key)
          @migration.add_reference(table, reference, *args, **options)
          if foreign_key
            # same as Active Record
            name =
              if foreign_key.is_a?(Hash) && foreign_key[:to_table]
                foreign_key[:to_table]
              else
                (ActiveRecord::Base.pluralize_table_names ? reference.to_s.pluralize : reference).to_sym
              end

            foreign_key_opts = foreign_key.is_a?(Hash) ? foreign_key.except(:to_table) : {}
            if reference
              @migration.add_foreign_key(table, name, column: "#{reference}_id", **foreign_key_opts)
            else
              @migration.add_foreign_key(table, name, **foreign_key_opts)
            end
          end
        end
        dir.down do
          @migration.remove_reference(table, reference)
        end
      end
    end

    def safe_add_foreign_key(from_table, to_table, *args, **options)
      @migration.reversible do |dir|
        dir.up do
          @migration.add_foreign_key(from_table, to_table, *args, **options.merge(validate: false))
          disable_transaction
          validate_options = options.slice(:column, :name)
          if ActiveRecord::VERSION::MAJOR >= 6
            @migration.validate_foreign_key(from_table, to_table, **validate_options)
          else
            @migration.validate_foreign_key(from_table, validate_options.any? ? validate_options : to_table)
          end
        end
        dir.down do
          remove_options = options.slice(:column, :name)
          if ActiveRecord::VERSION::MAJOR >= 6
            @migration.remove_foreign_key(from_table, to_table, **remove_options)
          else
            @migration.remove_foreign_key(from_table, remove_options.any? ? remove_options : to_table)
          end
        end
      end
    end

    def safe_add_check_constraint(table, expression, *args, add_options, validate_options)
      @migration.reversible do |dir|
        dir.up do
          @migration.add_check_constraint(table, expression, *args, **add_options)
          disable_transaction
          @migration.validate_check_constraint(table, **validate_options)
        end
        dir.down do
          @migration.remove_check_constraint(table, expression, **add_options.except(:validate))
        end
      end
    end

    def safe_change_column_null(add_code, validate_code, change_args, remove_code, default)
      @migration.reversible do |dir|
        dir.up do
          unless default.nil?
            raise Error, "default value not supported yet with safe_by_default"
          end

          @migration.safety_assured do
            @migration.execute(add_code)
            disable_transaction
            @migration.execute(validate_code)
          end
          if change_args
            @migration.change_column_null(*change_args)
            @migration.safety_assured do
              @migration.execute(remove_code)
            end
          end
        end
        dir.down do
          if change_args
            down_args = change_args.dup
            down_args[2] = true
            @migration.change_column_null(*down_args)
          else
            @migration.safety_assured do
              @migration.execute(remove_code)
            end
          end
        end
      end
    end

    # hard to commit at right time when reverting
    # so just commit at start
    def disable_transaction
      if in_transaction? && !transaction_disabled
        @migration.connection.commit_db_transaction
        self.transaction_disabled = true
      end
    end

    def in_transaction?
      @migration.connection.open_transactions > 0
    end
  end
end
