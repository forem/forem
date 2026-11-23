module Api
  module CommentsController
    extend ActiveSupport::Concern

    ATTRIBUTES_FOR_SERIALIZATION = %i[
      id processed_html user_id ancestry deleted hidden_by_commentable_user created_at ai_disclosure_level
    ].freeze
    private_constant :ATTRIBUTES_FOR_SERIALIZATION

    COMMENT_PLUCK_COLUMNS = %i[
      id ancestry processed_html user_id deleted hidden_by_commentable_user created_at ai_disclosure_level
    ].freeze
    private_constant :COMMENT_PLUCK_COLUMNS

    USER_SERIALIZATION_COLUMNS = %i[
      id name username twitter_username github_username profile_image
    ].freeze
    private_constant :USER_SERIALIZATION_COLUMNS

    AI_DISCLOSURE_INDICES = {
      "not_disclosed" => 0,
      :not_disclosed => 0,
      0 => 0,
      "no_ai" => 1,
      :no_ai => 1,
      1 => 1,
      "some_ai" => 2,
      :some_ai => 2,
      3 => 2,
      "fully_autonomous" => 3,
      :fully_autonomous => 3,
      5 => 3
    }.freeze
    private_constant :AI_DISCLOSURE_INDICES

    DEFAULT_PER_PAGE = 50
    private_constant :DEFAULT_PER_PAGE

    # Each level renders as a nested jbuilder partial, so a very deep reply chain
    # overflows the stack (SystemStackError). Replies below this depth are left out.
    MAX_DEPTH = 50
    private_constant :MAX_DEPTH

    def index
      commentable = find_commentable

      if native_serializable_request?
        root_offset, root_limit = pagination_bounds
        if root_offset
          rows = commentable.comments.order(:id).pluck(*COMMENT_PLUCK_COLUMNS)
          serialized = serialize_comments_natively(
            rows,
            single_root: false,
            root_offset: root_offset,
            root_limit: root_limit,
          )
          if serialized
            json_body, included_ids = serialized
            set_surrogate_key_header commentable.record_key, Comment.table_key,
                                     comment_record_keys(included_ids)
            render json: json_body
            return
          end
        end
      end

      legacy_index(commentable)
    end

    def show
      comment_id = params[:id].to_i(26)
      if native_serializable_request?
        rows = Comment.subtree_of(comment_id).order(:id).pluck(*COMMENT_PLUCK_COLUMNS)
        serialized = serialize_comments_natively(rows, single_root: true)
        if serialized
          json_body, included_ids = serialized
          set_surrogate_key_header Comment.table_key, comment_record_keys(included_ids)
          render json: json_body
          return
        end
      end

      legacy_show(comment_id)
    end

    def preview
      comment_param = params[:comment]
      comment_hash = comment_param.is_a?(ActionController::Parameters) || comment_param.is_a?(Hash) ? comment_param : {}
      body_markdown = params.key?(:body_markdown) ? params[:body_markdown] : comment_hash[:body_markdown]

      renderer = ContentRenderer.new(body_markdown.to_s, source: Comment.new(user: @user), user: @user)
      processed_html = renderer.process(link_attributes: { rel: "nofollow" }).processed_html

      render json: { processed_html: processed_html }, status: :ok
    rescue ContentRenderer::ContentParsingError => e
      error_unprocessable_entity(ErrorMessages::Clean.call(e.message))
    end

    private

    def find_commentable
      if params[:a_id]
        Article.select(:id).find(params[:a_id])
      else
        PodcastEpisode.select(:id).find(params[:p_id])
      end
    end

    def pagination_bounds
      page = params[:page].to_i
      return [0, nil] unless page.positive?

      raw_per_page = params[:per_page]
      per_page = if raw_per_page.nil?
                   DEFAULT_PER_PAGE
                 elsif raw_per_page.is_a?(Integer) || raw_per_page.to_s.match?(/\A\d+\z/)
                   raw_per_page.to_i
                 else
                   return [nil, nil]
                 end
      return [nil, nil] unless per_page.positive?
      return [nil, nil] if Kaminari.config.max_per_page && per_page > Kaminari.config.max_per_page

      offset = (page - 1) * per_page
      return [nil, nil] unless offset < 2**63 && per_page < 2**63

      [offset, per_page]
    end

    def native_serializable_request?
      ForemNative.available? && (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def serialize_comments_natively(rows, single_root:, root_offset: 0, root_limit: nil)
      return unless ForemNative.available?

      selected_root_ids = selected_paginated_root_ids(rows, single_root, root_offset, root_limit)
      users_flat, user_idx_by_id = native_users_payload(rows, selected_root_ids: selected_root_ids)
      return unless users_flat

      comments_flat = native_comments_payload(rows, user_idx_by_id, selected_root_ids: selected_root_ids)
      return unless comments_flat

      ForemNative.serialize_api_comments_json(
        comments_flat,
        users_flat,
        native_comment_labels,
        max_depth: MAX_DEPTH,
        single_root: single_root,
        root_offset: root_offset,
        root_limit: root_limit,
        escape_html_entities: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
    end

    # When paginating root comments, identifies the root IDs on the requested page so
    # `native_users_payload` only loads `User`/`Profile` rows and builds image URLs for
    # authors of retained comments on that page. Returns `nil` when unpaginated or when
    # any row has an external/orphan ancestor so all authors are resolved safely.
    def selected_paginated_root_ids(rows, single_root, root_offset, root_limit)
      return if single_root || root_limit.nil? || rows.empty?

      ancestry_by_id, root_ids, root_id_set = collect_row_ids(rows)
      return unless ancestry_by_id && all_descendants_rooted?(rows, ancestry_by_id, root_id_set)

      (root_ids[root_offset, root_limit] || []).index_with(true)
    end

    def collect_row_ids(rows)
      ancestry_by_id = {}
      root_ids = []
      root_id_set = {}
      rows.each do |id, ancestry, *_rest|
        id_str = id.to_s
        return nil if ancestry_by_id.key?(id_str)

        ancestry_by_id[id_str] = ancestry
        next unless root_ancestry?(ancestry)

        root_ids << id_str
        root_id_set[id_str] = true
      end
      [ancestry_by_id, root_ids, root_id_set]
    end

    def all_descendants_rooted?(rows, ancestry_by_id, root_id_set)
      rows.all? do |_id, ancestry, *_rest|
        next true if root_ancestry?(ancestry)

        consistent_descendant_ancestry?(ancestry, ancestry_by_id, root_id_set)
      end
    end

    def consistent_descendant_ancestry?(ancestry, ancestry_by_id, root_id_set)
      top_ancestor = ancestry.split("/", 2).first
      return false unless root_id_set.key?(top_ancestor)

      if ancestry.include?("/")
        prefix, _sep, parent_id = ancestry.rpartition("/")
        ancestry_by_id.key?(parent_id) && ancestry_by_id[parent_id] == prefix
      else
        ancestry_by_id.key?(ancestry) && root_ancestry?(ancestry_by_id[ancestry])
      end
    end

    def root_ancestry?(ancestry)
      ancestry.nil? || ancestry == ""
    end

    def row_on_selected_page?(id, ancestry, selected_root_ids)
      return true unless selected_root_ids

      if root_ancestry?(ancestry)
        MAX_DEPTH.positive? && selected_root_ids.key?(id.to_s)
      else
        top_ancestor = ancestry.split("/", 2).first
        selected_root_ids.key?(top_ancestor) && (ancestry.count("/") + 1) < MAX_DEPTH
      end
    end

    def native_users_payload(rows, selected_root_ids: nil)
      active_user_ids = []
      seen = {}
      rows.each do |id, ancestry, _html, user_id, deleted, hidden, _created_at, _ai_level|
        next if deleted || hidden || user_id.nil? || seen.key?(user_id)
        next unless row_on_selected_page?(id, ancestry, selected_root_ids)

        seen[user_id] = true
        active_user_ids << user_id
      end

      return [[], {}] if active_user_ids.empty?

      users_by_id = User.where(id: active_user_ids).select(*USER_SERIALIZATION_COLUMNS).index_by(&:id)
      websites_by_user_id = Profile.where(user_id: active_user_ids).pluck(:user_id, :website_url).to_h

      users_flat = []
      user_idx_by_id = {}
      active_user_ids.each do |uid|
        user = users_by_id[uid]
        return nil unless user

        website = websites_by_user_id[uid]
        processed_website = website.present? ? website.to_s.strip : nil
        user_idx_by_id[uid] = users_flat.size / 8
        users_flat.push(
          user.id,
          user.name,
          user.username,
          user.twitter_username,
          user.github_username,
          processed_website,
          user.profile_image_url_for(length: 640),
          user.profile_image_url_for(length: 90),
        )
      end

      [users_flat, user_idx_by_id]
    end

    def native_comments_payload(rows, user_idx_by_id, selected_root_ids: nil)
      comments_flat = []
      rows.each do |row|
        return nil unless append_native_comment_row(comments_flat, row, user_idx_by_id, selected_root_ids)
      end

      comments_flat
    end

    def append_native_comment_row(comments_flat, row, user_idx_by_id, selected_root_ids)
      id, ancestry, processed_html, user_id, deleted, hidden, created_at, ai_level = row
      on_page = row_on_selected_page?(id, ancestry, selected_root_ids)
      user_idx = deleted || hidden || !on_page ? -1 : user_idx_by_id[user_id]
      ai_idx = AI_DISCLOSURE_INDICES[ai_level] || (on_page ? nil : 0)
      created_sec = extract_created_at_sec(created_at, on_page)
      return false unless user_idx && ai_idx && created_sec != :invalid

      comments_flat.push(id, ancestry, processed_html, user_idx, deleted ? true : false, hidden ? true : false,
                         created_sec, ai_idx)
      true
    end

    def extract_created_at_sec(created_at, on_page)
      return if created_at.nil?
      return created_at.tv_sec if created_at.respond_to?(:tv_sec)

      on_page ? :invalid : nil
    end

    def native_comment_labels
      [
        "<p>#{Comment.title_deleted}</p>",
        "<p>#{Comment.title_hidden}</p>",
        I18n.t("models.comment.ai_disclosure.not_disclosed"),
        I18n.t("models.comment.ai_disclosure.no_ai"),
        I18n.t("models.comment.ai_disclosure.some_ai"),
        I18n.t("models.comment.ai_disclosure.fully_autonomous"),
      ]
    end

    def comment_record_keys(comment_ids)
      prefix = "#{Comment.table_key}/"
      comment_ids.map { |id| "#{prefix}#{id}" }
    end

    def legacy_index(commentable)
      per_page = params[:per_page] || DEFAULT_PER_PAGE

      @comments = prune(commentable.comments
        .includes(user: :profile)
        .select(ATTRIBUTES_FOR_SERIALIZATION)
        .arrange(order: "id"))

      # paginating only if page is passed
      if params[:page].to_i.positive?
        @comments = Kaminari.paginate_array(@comments.to_a).page(params[:page]).per(per_page).to_h
      end

      set_surrogate_key_header commentable.record_key, Comment.table_key, edge_cache_keys(@comments)
    end

    def legacy_show(comment_id)
      tree_with_root_comment = prune(Comment.subtree_of(comment_id)
        .includes(user: :profile)
        .select(ATTRIBUTES_FOR_SERIALIZATION)
        .arrange(order: "id"))

      # being only one tree we know that the root comment is the first (and only) key
      @comment = tree_with_root_comment.keys.first
      @comments = tree_with_root_comment[@comment]

      set_surrogate_key_header Comment.table_key, edge_cache_keys(tree_with_root_comment)
    end

    def prune(comments_trees, depth = 0)
      return {} if depth >= MAX_DEPTH

      comments_trees.transform_values { |children| prune(children, depth + 1) }
    end

    # ancestry wraps a single or multiple trees of comments into a single hash,
    # in the case of an article comments, the hash has multiple keys (the root comments),
    # in the case of a comment and its descendants, the hash has only one key.
    # Either way, we need to use recursion to extract all the comment cache keys
    # collecting both the keys of each level of root comments and their descendants
    # NOTE: the objects are already loaded in memory by "ancestry",
    # so no additional SQL query is performed during this extraction, avoiding N+1s
    def edge_cache_keys(comments_trees)
      comments_trees.keys.flat_map do |comment|
        Array.wrap(comment.record_key) + edge_cache_keys(comments_trees[comment])
      end
    end
  end
end
