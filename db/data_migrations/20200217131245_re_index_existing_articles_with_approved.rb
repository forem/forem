class ReIndexExistingArticlesWithApproved < ActiveRecord::DataMigration
  def up
    Article.published.find_each { |article| Article.trigger_index(article, false) }
  end
end
