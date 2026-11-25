module Search
  class Comment
    ATTRIBUTES = [
      "COALESCE(articles.published, false) AS commentable_published",
      "COALESCE(articles.title, '') AS commentable_title",
      "comments.body_markdown",
      "comments.commentable_id",
      "comments.commentable_type",
      "comments.created_at",
      "comments.id AS id",
      "comments.public_reactions_count",
      "comments.score",
      "comments.user_id",
    ].freeze
    private_constant :ATTRIBUTES

    NATIVE_PLUCK_COLUMNS = [
      Arel.sql("comments.id"),
      Arel.sql("comments.public_reactions_count"),
      Arel.sql("comments.body_markdown"),
      Arel.sql("comments.score"),
      Arel.sql("comments.created_at"),
      Arel.sql("COALESCE(articles.title, '')"),
      Arel.sql("comments.user_id"),
    ].freeze
    private_constant :NATIVE_PLUCK_COLUMNS

    USER_ATTRIBUTES = %i[id name profile_image username].freeze
    private_constant :USER_ATTRIBUTES

    DEFAULT_PER_PAGE = 60
    private_constant :DEFAULT_PER_PAGE

    DEFAULT_SORT_BY = "comments.score".freeze
    private_constant :DEFAULT_SORT_BY

    DEFAULT_SORT_DIRECTION = :desc
    private_constant :DEFAULT_SORT_DIRECTION

    MAX_PER_PAGE = 120 # to avoid querying too many items, we set a maximum amount for a page
    private_constant :MAX_PER_PAGE

    def self.search_documents(
      page: 0,
      per_page: DEFAULT_PER_PAGE,
      sort_by: DEFAULT_SORT_BY,
      sort_direction: DEFAULT_SORT_DIRECTION,
      term: nil,
      format: :hash
    )
      sort_by ||= DEFAULT_SORT_BY
      # The UI and serializer rename created_at (the actual DB column name) to
      # published_at
      sort_by = "comments.created_at" if sort_by == "published_at"

      sort_direction ||= DEFAULT_SORT_DIRECTION

      # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
      # to start from page 1
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      relation = ::Comment
        .where(
          deleted: false,
          hidden_by_commentable_user: false,
          commentable_type: "Article",
        )
        .joins("join articles on articles.id = comments.commentable_id")
        .where("articles.published": true)

      has_highlight = term.present?
      relation = relation.search_comments(term).with_pg_search_highlight if has_highlight

      if format == :json && native_json_serializable?
        ordered = relation.reorder("#{sort_by}": sort_direction).page(page).per(per_page)
        json = if has_highlight
                 serialize_models_natively(ordered.includes(:user).select(*ATTRIBUTES))
               else
                 serialize_plucked_natively(ordered)
               end
        return Homepage::ArticleSerializer::EncodedJson.new(json) if json
      end

      results = relation.includes(:user).select(*ATTRIBUTES)
        .reorder("#{sort_by}": sort_direction).page(page).per(per_page)

      serialize(results)
    end

    def self.serialize(results)
      Search::CommentSerializer
        .new(results, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize

    def self.native_json_serializable?
      ForemNative.available? &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC" &&
        ActiveSupport::JSON::Encoding.use_standard_json_time_format &&
        ActiveSupport::JSON::Encoding.time_precision == 3
    end
    private_class_method :native_json_serializable?

    def self.serialize_plucked_natively(relation)
      rows = relation.pluck(*NATIVE_PLUCK_COLUMNS)
      return '{"result":[]}' if rows.empty?

      user_ids = rows.filter_map { |row| row[6] }.uniq
      users_flat, user_idx_by_id = build_users_payload(user_ids)

      comments_flat = []
      rows.each do |row|
        created_at = row[4]
        return nil unless created_at.respond_to?(:tv_sec) && created_at.respond_to?(:tv_nsec) &&
          created_at.respond_to?(:utc?) && created_at.utc?

        comments_flat.push(
          row[0], row[1], row[2], false, nil, row[3],
          created_at.tv_sec, created_at.tv_nsec / 1_000_000,
          row[5], user_idx_by_id.fetch(row[6], -1)
        )
      end

      ForemNative.serialize_search_comments_json(
        comments_flat,
        users_flat,
        Time.current.year,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end
    private_class_method :serialize_plucked_natively

    def self.serialize_models_natively(relation)
      comments = relation.to_a
      return '{"result":[]}' if comments.empty?

      users_flat = []
      user_idx_by_id = {}
      comments_flat = []

      comments.each do |comment|
        created_at = comment.created_at
        return nil unless created_at.respond_to?(:tv_sec) && created_at.respond_to?(:tv_nsec) &&
          created_at.respond_to?(:utc?) && created_at.utc?

        user = comment.user
        user_idx = if user
                     user_idx_by_id[user.id] ||= begin
                       idx = users_flat.size / 3
                       users_flat.push(user.name, user.profile_image_90, user.username)
                       idx
                     end
                   else
                     -1
                   end

        comments_flat.push(
          comment.id, comment.public_reactions_count, comment.body_markdown,
          true, comment.pg_search_highlight, comment.score,
          created_at.tv_sec, created_at.tv_nsec / 1_000_000,
          comment.commentable_title, user_idx
        )
      end

      ForemNative.serialize_search_comments_json(
        comments_flat,
        users_flat,
        Time.current.year,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end
    private_class_method :serialize_models_natively

    def self.build_users_payload(user_ids)
      return [[], {}] if user_ids.empty?

      users_by_id = ::User.where(id: user_ids).select(*USER_ATTRIBUTES).index_by(&:id)
      users_flat = []
      user_idx_by_id = {}
      user_ids.each do |uid|
        user = users_by_id[uid]
        next unless user

        user_idx_by_id[uid] = users_flat.size / 3
        users_flat.push(user.name, user.profile_image_90, user.username)
      end
      [users_flat, user_idx_by_id]
    end
    private_class_method :build_users_payload
  end
end
