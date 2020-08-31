module DataUpdateScripts
  class NullifyOrphanedCommentsByArticle
    def run
      # Nullify article_id for all Comments linked to a non existing Article
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          UPDATE comments
          SET commentable_id = NULL, commentable_type = NULL
          WHERE commentable_type = 'Article'
          AND commentable_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
