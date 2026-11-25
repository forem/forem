module Search
  class ReadingList
    ATTRIBUTES = [
      "articles.cached_tag_list",
      "articles.crossposted_at",
      "articles.path",
      "articles.published_at",
      "articles.reading_time",
      "articles.title",
      "articles.user_id",
      "reactions.id AS reaction_id",
      "reactions.user_id AS reaction_user_id",
    ].freeze
    REACTION_ATTRIBUTES = %i[id reactable_id user_id].freeze
    USER_ATTRIBUTES = %i[id name profile_image username].freeze
    NATIVE_PLUCK_COLUMNS = [
      Arel.sql("reactions.id"),
      Arel.sql("reactions.user_id"),
      Arel.sql("articles.path"),
      Arel.sql("articles.published_at"),
      Arel.sql("articles.crossposted_at"),
      Arel.sql("articles.reading_time"),
      Arel.sql("articles.cached_tag_list"),
      Arel.sql("articles.title"),
      Arel.sql("articles.user_id"),
    ].freeze

    DEFAULT_STATUSES = %w[confirmed valid].freeze

    DEFAULT_PER_PAGE = 60
    MAX_PER_PAGE = 100 # to avoid querying too many items, we set a maximum amount for a page

    # Search for the given user's reading list.
    #
    # @param user [User] whose reading list are we searching?
    # @param term [String] search term for the articles
    # @param statuses [Array<String>] what reading list status(es) to filter our search
    # @param tags [Array<String>] a list of tags to filter our search
    # @param page [Integer] the page in the pagination
    # @param per_page [Integer] how many items do we return in our pagination result set
    # @param subforem_id [Integer] the subforem to filter articles by
    #
    # @return [Hash<Symbol,Object>] with keys :items and :total.
    #         :total is an Integer and :items is an Array of serialized data.
    def self.search_documents(user, term: nil, statuses: [], tags: [], page: 0, per_page: DEFAULT_PER_PAGE,
                              subforem_id: nil, format: :hash)
      return {} unless user

      statuses = statuses.presence || DEFAULT_STATUSES
      tags = tags.presence || []

      # TODO: [@rhymes] we should eventually update the frontend
      # to start from page 1
      page = page.to_i + 1
      per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

      result = find_articles(
        user: user,
        term: term,
        statuses: statuses,
        tags: tags,
        page: page,
        per_page: per_page,
        subforem_id: subforem_id,
      )

      if format == :json && native_json_serializable?(result[:items])
        json = serialize_json_natively(result[:items], result[:total])
        return Homepage::ArticleSerializer::EncodedJson.new(json) if json
      end

      # Materialize once so we don't execute the articles query twice (once for pluck(:user_id)
      # and again when iterating inside ReadingListArticleSerializer).
      articles = result[:items].to_a
      user_ids = articles.map(&:user_id).uniq
      users = find_users(user_ids)

      {
        items: serialize(articles, users),
        total: result[:total]
      }
    end

    def self.find_articles(user:, term:, statuses:, tags:, page:, per_page:, subforem_id: nil, only_published: true)
      # [@jgaskins, @rhymes] as `reactions` is potentially a big table, adding pagination
      # to an INNER JOIN (eg. `joins(:reactions)`) exponentially decreases the performance,
      # incrementing query time as the database has to scan all the rows just to discard
      # them right after if they lie outside the bounds of the `OFFSET`.
      # Even though it should have had a similar performance, we realized that a subquery
      # enabled PostgreSQL query planner to drastically decrease the planned time (ca. 145x)
      reaction_query_sql = user.reactions.readinglist
        .where(status: statuses, reactable_type: "Article")
        .order(created_at: :desc)
        .select(*REACTION_ATTRIBUTES)
        .to_sql

      relation = ::Article.joins(
        "INNER JOIN (#{reaction_query_sql}) reactions ON reactions.reactable_id = articles.id",
      )

      relation = relation.published if only_published

      # Only filter by subforem if we're not in the root subforem context
      # In root context, show articles from any subforem
      if !Subforem.disabled_by_env? && subforem_id.present? && subforem_id != RequestStore.store[:root_subforem_id]
        relation = relation.from_subforem(subforem_id)
      end

      relation = relation.search_articles(term) if term.present?

      relation = relation.cached_tagged_with(tags) if tags.any?

      # here we issue a COUNT(*) after all the conditions are applied,
      # because we need to fetch the total number of articles, pre pagination
      total = relation.count

      relation = relation.select(*ATTRIBUTES)
      relation = relation.page(page).per(per_page)

      {
        items: relation,
        total: total
      }
    end
    private_class_method :find_articles

    def self.find_users(user_ids)
      ::User
        .where(id: user_ids)
        .select(*USER_ATTRIBUTES)
        .index_by(&:id)
    end
    private_class_method :find_users

    def self.serialize(articles, users)
      Search::ReadingListArticleSerializer
        .new(articles, params: { users: users }, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end
    private_class_method :serialize

    def self.native_json_serializable?(relation)
      ForemNative.available? &&
        relation.is_a?(ActiveRecord::Relation) &&
        !relation.loaded? &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC"
    end
    private_class_method :native_json_serializable?

    def self.serialize_json_natively(relation, total)
      rows = relation.unscope(:select).pluck(*NATIVE_PLUCK_COLUMNS)
      return %({"result":[],"total":#{total.to_i}}) if rows.empty?

      user_ids = rows.filter_map { |row| row[8] }.uniq
      users_by_id = find_users(user_ids)

      users_flat = []
      user_idx_by_id = {}
      user_ids.each do |uid|
        user = users_by_id[uid]
        return nil unless user

        user_idx_by_id[uid] = users_flat.size / 3
        users_flat.push(user.name, user.profile_image_90, user.username)
      end

      items_flat = []
      rows.each do |row|
        user_idx = user_idx_by_id[row[8]]
        return nil unless user_idx

        published_sec = extract_epoch_sec(row[3])
        crossposted_sec = extract_epoch_sec(row[4])
        return nil if published_sec == :invalid || crossposted_sec == :invalid

        items_flat.push(row[0], row[1], row[2], published_sec, crossposted_sec, row[5], row[6], row[7], user_idx)
      end

      ForemNative.serialize_search_reading_list_json(
        items_flat,
        users_flat,
        total,
        Time.current.year,
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end
    private_class_method :serialize_json_natively

    def self.extract_epoch_sec(value)
      return if value.nil?
      return value.tv_sec if value.respond_to?(:tv_sec) && value.respond_to?(:utc_offset) && value.utc_offset.zero?

      :invalid
    end
    private_class_method :extract_epoch_sec
  end
end
