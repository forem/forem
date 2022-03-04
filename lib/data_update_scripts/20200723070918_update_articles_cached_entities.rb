module DataUpdateScripts
  class UpdateArticlesCachedEntities
    def run
      Article.where.not(cached_user: nil).or(Article.where.not(cached_organization: nil)).find_each do |article|
        if article.cached_organization.present?
          old_cached_org = article.cached_organization
          article.update(cached_organization: Articles::CachedEntity.from_object(old_cached_org))
        end

        if article.cached_user.present?
          old_cached_user = article.cached_user
          article.update(cached_user: Articles::CachedEntity.from_object(old_cached_user))
        end
      end
    end
  end
end
