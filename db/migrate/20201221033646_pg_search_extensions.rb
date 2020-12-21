class PgSearchExtensions < ActiveRecord::Migration[6.0]
  def up
    enable_extension("unaccent")
    enable_extension("pg_trgm")
  end

  def down
    disable_extension("unaccent")
    disable_extension("pg_trgm")
  end
end
