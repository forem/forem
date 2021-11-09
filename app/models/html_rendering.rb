# The purpose of this module is to provide a common place for
# answering the question:
#
# What HTML tags and attributes are allowed for what contexts?
#
# In performing some analysis, I found that we had at least 5 places
# in our code base that specified AllowedTags and AllowedAttributes.
#
# There should be parity between the name of constants in both
# AllowedTags and AllowedAttributes.  That is to say if one of those
# modules has FEED then the other should have FEED as well.
module HtmlRendering
  # A container module for the allowed tags in various rendering
  # contexts.
  module AllowedTags
    FEED = %w[a b blockquote br center cite code col colgroup dd del div dl dt em em h1 h2
              h3 h4 h5 h6 i iframe img li ol p pre q small span strong sup table tbody td
              tfoot th thead time tr u ul].freeze

    PODCAST_SHOW = %w[
      a b blockquote br center cite code col colgroup dd del div dl dt em
      h1 h2 h3 h4 h5 h6 i img li ol p pre q small span strong sup table
      tbody td tfoot th thead time tr u ul
    ].freeze

    DISPLAY_AD = %w[a abbr add b blockquote br center cite code col colgroup dd del dl dt
                    em figcaption h1 h2 h3 h4 h5 h6 hr img kbd li mark ol p pre q rp rt
                    ruby small source span strong sub sup table tbody td tfoot th thead
                    time tr u ul video].freeze

    RENDERED_MARKDOWN_SCRUBBER = %w[a abbr add b blockquote br center cite code col
                                    colgroup dd del dl dt em figcaption h1 h2 h3 h4 h5
                                    h6 hr img kbd li mark ol p pre q rp rt ruby small
                                    source span strong sub sup table tbody td tfoot th
                                    thead time tr u ul video].freeze

    MARKDOWN_PROCESSOR_DEFAULT = %w[a abbr aside b blockquote br code em h1 h2 h3 h4 h5
                                    h6 hr i img kbd li ol p pre small span strong sub
                                    sup u ul].freeze

    MARKDOWN_PROCESSOR_LIMITED = %w[b br code em i p strong u].freeze

    MARKDOWN_PROCESSOR_INLINE_LIMITED = %w[b code em i strong u].freeze

    MARKDOWN_PROCESSOR_LISTINGS = %w[a abbr aside b blockquote br code em h4 h5 h6 hr i
                                     kbd li ol p pre small span strong sub sup u ul].freeze
  end

  # A container module for the allowed attributes in various rendering
  # contexts.
  module AllowedAttributes
    FEED = %w[alt class colspan data-conversation data-lang em height href id ref rel
              rowspan size span src start strong title value width].freeze

    PODCAST_SHOW = %w[alt class colspan data-conversation data-lang em height href id ref
                      rel rowspan size span src start strong title value width].freeze

    DISPLAY_AD = %w[alt height href src width].freeze

    RENDERED_MARKDOWN_SCRUBBER = %w[alt colspan controls data-conversation data-lang
                                    data-no-instant data-url href id loop name ref rel
                                    rowspan span src start title type value].freeze

    MARKDOWN_PROCESSOR = %w[alt href src].freeze
  end
end
