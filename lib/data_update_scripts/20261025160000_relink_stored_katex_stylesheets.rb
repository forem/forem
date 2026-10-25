module DataUpdateScripts
  # KatexTag persists a fingerprinted `<link href=".../assets/katex-<digest>.css">` into processed_html.
  # When the katex gem's vendored stylesheet changes, the old digest stops being served, so unedited
  # records would render math without KaTeX CSS/fonts. Point every stored link at the current digest.
  class RelinkStoredKatexStylesheets
    MODELS = [Article, Comment, Page, Billboard, Event].freeze
    STALE_LINK = %r{/assets/katex-[0-9a-f]{64}\.css}

    def run
      current = URI.parse(ActionController::Base.helpers.asset_path("katex.css")).path
      pattern = STALE_LINK.source

      # Batch by primary key and filter inside each batch: a table-wide regex filter can't use an
      # index, so every batch would seq scan the whole table and hit statement_timeout.
      MODELS.each do |model|
        model.in_batches(of: 1_000) do |batch|
          batch.where("processed_html ~ ?", pattern)
            .update_all(["processed_html = regexp_replace(processed_html, ?, ?, 'g')", pattern, current])
        end
      end
    end
  end
end
