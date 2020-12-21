# See:
# https://github.com/Casecommons/pg_search#trigram
# https://github.com/Casecommons/pg_search#ignoring-accent-marks
PgSearch.multisearch_options = {
  using: %i[tsearch trigram],
  ignoring: :accents
}
