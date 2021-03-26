module DataUpdateScripts
  class UpdateArticlesForTsvectorTrigger
    def run
      # In the AddTsvectorUpdateTriggerToArticlesTsv migration we create a PostgreSQL trigger
      # to keep the `tsv` column updated, we need to invoke it for existing columns,
      # thus we resave the title to itself
      Article.update_all("title = title")
    end
  end
end
