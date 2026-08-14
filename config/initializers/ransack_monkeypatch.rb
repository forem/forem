# frozen_string_literal: true

# Ransack 3.x calls Arel::Table#table_name, which was removed in Rails 7.1.
# This monkeypatch restores the method as an alias to Arel::Table#name.
module Arel
  class Table
    alias table_name name
  end
end
