# See:
# https://github.com/Casecommons/pg_search#trigram-trigram-search
# https://github.com/Casecommons/pg_search#ignoring-accent-marks
PgSearch.multisearch_options = {
  # using: %i[tsearch trigram],
  using: {
    tsearch: {
      any_word: true, # combine search terms with 'or', not 'and'
      prefix: true    # search for partial words
    }
  },
  ignoring: :accents
}
