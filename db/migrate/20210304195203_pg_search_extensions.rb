class PgSearchExtensions < ActiveRecord::Migration[6.0]
  def up
    enable_extension("unaccent") # For ignoring accent marks https://github.com/Casecommons/pg_search#ignoring-accent-marks
    enable_extension("pg_trgm") # For trigram searches https://github.com/Casecommons/pg_search#trigram-trigram-search
  end

  def down
    disable_extension("unaccent")
    disable_extension("pg_trgm")
  end
end
