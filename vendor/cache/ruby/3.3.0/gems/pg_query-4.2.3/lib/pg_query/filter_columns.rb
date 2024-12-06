module PgQuery
  class ParserResult
    # Returns a list of columns that the query filters by - this excludes the
    # target list, but includes things like JOIN condition and WHERE clause.
    #
    # Note: This also traverses into sub-selects.
    def filter_columns # rubocop:disable Metrics/CyclomaticComplexity
      load_objects! if @aliases.nil?

      # Get condition items from the parsetree
      statements = @tree.stmts.dup.to_a.map(&:stmt)
      condition_items = []
      filter_columns = []
      loop do
        statement = statements.shift
        if statement
          case statement.node
          when :list
            statements += statement.list.items
          when :raw_stmt
            statements << statement.raw_stmt.stmt
          when :select_stmt
            case statement.select_stmt.op
            when :SETOP_NONE
              if statement.select_stmt.from_clause
                # FROM subselects
                statement.select_stmt.from_clause.each do |item|
                  next unless item['RangeSubselect']
                  statements << item['RangeSubselect']['subquery']
                end

                # JOIN ON conditions
                condition_items += conditions_from_join_clauses(statement.select_stmt.from_clause)
              end

              # WHERE clause
              condition_items << statement.select_stmt.where_clause if statement.select_stmt.where_clause

              # CTEs
              if statement.select_stmt.with_clause
                statement.select_stmt.with_clause.ctes.each do |item|
                  statements << item.common_table_expr.ctequery if item.node == :common_table_expr
                end
              end
            when :SETOP_UNION, :SETOP_EXCEPT, :SETOP_INTERSECT
              statements << PgQuery::Node.new(select_stmt: statement.select_stmt.larg) if statement.select_stmt.larg
              statements << PgQuery::Node.new(select_stmt: statement.select_stmt.rarg) if statement.select_stmt.rarg
            end
          when :update_stmt
            condition_items << statement.update_stmt.where_clause if statement.update_stmt.where_clause
          when :delete_stmt
            condition_items << statement.delete_stmt.where_clause if statement.delete_stmt.where_clause
          when :index_stmt
            condition_items << statement.index_stmt.where_clause if statement.index_stmt.where_clause
          end
        end

        # Process both JOIN and WHERE conditions here
        next_item = condition_items.shift
        if next_item
          case next_item.node
          when :a_expr
            condition_items << next_item.a_expr.lexpr if next_item.a_expr.lexpr
            condition_items << next_item.a_expr.rexpr if next_item.a_expr.rexpr
          when :bool_expr
            condition_items += next_item.bool_expr.args
          when :coalesce_expr
            condition_items += next_item.coalesce_expr.args
          when :row_expr
            condition_items += next_item.row_expr.args
          when :column_ref
            column, table = next_item.column_ref.fields.map { |f| f.string.sval }.reverse
            filter_columns << [@aliases[table] || table, column]
          when :null_test
            condition_items << next_item.null_test.arg
          when :boolean_test
            condition_items << next_item.boolean_test.arg
          when :func_call
            # FIXME: This should actually be extracted as a funccall and be compared with those indices
            condition_items += next_item.func_call.args if next_item.func_call.args
          when :sub_link
            condition_items << next_item.sub_link.testexpr
            statements << next_item.sub_link.subselect
          end
        end

        break if statements.empty? && condition_items.empty?
      end

      filter_columns.uniq
    end

    protected

    def conditions_from_join_clauses(from_clause)
      condition_items = []
      from_clause.each do |item|
        next unless item.node == :join_expr

        joinexpr_items = [item.join_expr]
        loop do
          next_item = joinexpr_items.shift
          break unless next_item
          condition_items << next_item.quals if next_item.quals
          joinexpr_items << next_item.larg.join_expr if next_item.larg.node == :join_expr
          joinexpr_items << next_item.rarg.join_expr if next_item.rarg.node == :join_expr
        end
      end
      condition_items
    end
  end
end
