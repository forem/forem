module Favorites
  # Returns a page of interleaved favorited articles and comments ordered by
  # favorited_at. An optional user may be passed to limit results to that user's
  # favorites.
  class Fetch
    DEFAULT_PER_PAGE = 20

    def self.call(...)
      new(...).call
    end

    def initialize(user: nil, since: nil, page: 1, per_page: DEFAULT_PER_PAGE)
      @user = user
      @since = since
      @page = page
      @per_page = per_page
    end

    def call
      refs = favorited_refs

      Kaminari.paginate_array(
        hydrate(refs),
        total_count: refs.total_count,
        limit: refs.limit_value,
        offset: refs.offset_value,
      )
    end

    private

    attr_reader :user, :since, :page, :per_page

    def favorited_refs
      favorited(Article).union_all(favorited(Comment))
        .order(favorited_at: :desc)
        .page(page)
        .per(per_page)
    end

    def favorited(model)
      scope = if user
                model.where(favorited_by_user_id: user.id)
              else
                model.where.not(favorited_by_user_id: nil)
              end
      scope = scope.where("favorited_at >= ?", since) if since.present?

      scope.select(
        ActiveRecord::Base.sanitize_sql_array(["? AS favoritable_type", model.name]),
        "id AS favoritable_id",
        "favorited_at",
      )
    end

    def hydrate(refs)
      grouped = refs.group_by(&:favoritable_type)
      articles = Article.where(id: Array(grouped["Article"]).map(&:favoritable_id))
        .includes(:user, :favorited_by_user).index_by(&:id)
      comments = Comment.where(id: Array(grouped["Comment"]).map(&:favoritable_id))
        .includes(:user, :favorited_by_user, :commentable).index_by(&:id)

      refs.filter_map do |ref|
        (ref.favoritable_type == "Article" ? articles : comments)[ref.favoritable_id]
      end
    end
  end
end
