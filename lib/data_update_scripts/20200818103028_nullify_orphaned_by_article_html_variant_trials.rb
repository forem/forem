module DataUpdateScripts
  class NullifyOrphanedByArticleHtmlVariantTrials
    def run
      # Nullify article_id for all HtmlVariantTrials linked to a non existing article
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          UPDATE html_variant_trials
          SET article_id = NULL
          WHERE article_id IS NOT NULL AND article_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
