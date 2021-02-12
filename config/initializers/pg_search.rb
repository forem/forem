# See:
# https://github.com/Casecommons/pg_search#trigram-trigram-search
# https://github.com/Casecommons/pg_search#ignoring-accent-marks
PgSearch.multisearch_options = {
  # using: %i[tsearch trigram],
  using: {
    tsearch: {
      any_word: true, # combine search terms with 'or', not 'and'
      prefix: true,   # search for partial words
      highlight: {    # https://github.com/Casecommons/pg_search#highlight
        StartSel: "<mark>",
        StopSel: "</mark>",
        MaxFragments: 2,
        MinWords: 5,
        MaxWords: 10
      }
    },
  },
  # https://github.com/Casecommons/pg_search#ranked_by-choosing-a-ranking-algorithm
  ranked_by: "LENGTH(content)",
  ignoring: :accents
}
