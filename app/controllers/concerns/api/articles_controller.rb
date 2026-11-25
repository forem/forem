module Api
  module ArticlesController
    extend ActiveSupport::Concern

    included do
      before_action :validate_page_limit, only: %i[index search]
      before_action -> { set_cache_control_headers(1.hour.to_i) }, only: %i[search]
    end

    MAX_UNAUTHENTICATED_PAGE = 1000
    MAX_UNAUTHENTICATED_OFFSET = 30_000

    INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id collection_id
      title description main_image published_at crossposted_at social_image
      cached_tag_list slug path canonical_url comments_count
      public_reactions_count created_at edited_at last_comment_at published
      updated_at video_thumbnail_url reading_time subforem_id language
      ai_disclosure_level
    ].freeze

    ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION = [
      *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown
    ].freeze
    private_constant :ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION

    SHOW_ATTRIBUTES_FOR_SERIALIZATION = [
      *INDEX_ATTRIBUTES_FOR_SERIALIZATION, :body_markdown, :processed_html
    ].freeze
    private_constant :SHOW_ATTRIBUTES_FOR_SERIALIZATION

    ME_ATTRIBUTES_FOR_SERIALIZATION = %i[
      id user_id organization_id
      title description main_image published published_at cached_tag_list
      slug path canonical_url comments_count public_reactions_count
      page_views_count crossposted_at body_markdown updated_at reading_time
      ai_disclosure_level
    ].freeze
    private_constant :ME_ATTRIBUTES_FOR_SERIALIZATION

    INDEX_PLUCK_COLUMNS = %i[
      id user_id organization_id collection_id
      title description main_image published_at crossposted_at social_image
      cached_tag_list slug path canonical_url comments_count
      public_reactions_count created_at edited_at last_comment_at published
      video_thumbnail_url reading_time subforem_id language ai_disclosure_level
    ].freeze
    private_constant :INDEX_PLUCK_COLUMNS

    SHOW_PLUCK_COLUMNS = [
      *INDEX_PLUCK_COLUMNS, :processed_html, :body_markdown
    ].freeze
    private_constant :SHOW_PLUCK_COLUMNS

    ME_PLUCK_COLUMNS = %i[
      id organization_id title description published published_at
      crossposted_at slug path comments_count public_reactions_count
      page_views_count body_markdown main_image cached_tag_list
      canonical_url reading_time
    ].freeze
    private_constant :ME_PLUCK_COLUMNS

    POSITIVE_INT32_MAX = 2_147_483_647
    private_constant :POSITIVE_INT32_MAX

    USER_INDEX_COLUMNS = %i[
      id name username twitter_username github_username profile_image
    ].freeze
    private_constant :USER_INDEX_COLUMNS

    ORG_INDEX_COLUMNS = %i[
      id name username slug profile_image custom_domain
    ].freeze
    private_constant :ORG_INDEX_COLUMNS

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

    def index
      if invalid_tags_present?
        render json: { error: "Not Found", status: 404 }, status: :not_found
        return
      end

      relation = ArticleApiIndexService.new(params).get
      if native_index_serializable?(relation)
        rows = relation.except(:includes).pluck(*INDEX_PLUCK_COLUMNS)
        json_body = serialize_articles_index_natively(rows)
        if json_body
          set_index_surrogate_keys(rows.map(&:first))
          render json: json_body
          return
        end
      end

      legacy_index(relation)
    end

    def show
      if native_show_serializable?
        row = Article.published.from_subforem
          .where(id: params[:id])
          .pick(*SHOW_PLUCK_COLUMNS)
        raise ActiveRecord::RecordNotFound unless row

        json_body = serialize_article_show_natively(row)
        if json_body
          set_surrogate_key_header "#{Article.table_key}/#{row[0]}"
          render json: json_body
          return
        end
      end

      legacy_show
    end

    def show_by_slug
      if native_serialization_supported?
        row = Article.published.from_subforem
          .where(path: "/#{params[:username]}/#{params[:slug]}")
          .pick(*SHOW_PLUCK_COLUMNS)
        raise ActiveRecord::RecordNotFound unless row

        json_body = serialize_article_show_natively(row)
        if json_body
          set_surrogate_key_header "#{Article.table_key}/#{row[0]}"
          render json: json_body
          return
        end
      end

      legacy_show_by_slug
    end

    def create
      authorize(Article)

      @article = Articles::Creator.call(@user, article_params).decorate

      if @article.persisted?
        render "show", status: :created, location: @article.url
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    def update
      # Set @article before #article_params so #allowed_to_change_org_id? checks the
      # post's author, not the editor, when an org admin edits someone else's post.
      @article = find_updatable_article
      editor_is_author = @article.user_id == @user.id
      organization_id = @article.organization_id

      result = Articles::Updater.call(@user, @article, article_params)

      @article = result.article

      if result.success
        log_non_author_update(organization_id) unless editor_is_author
        assign_ai_disclosure_warning
        render "show", status: :ok
      else
        message = @article.errors_as_sentence
        render json: { error: message, status: 422 }, status: :unprocessable_entity
      end
    end

    # Lists the authenticated user's articles by publication status, newest first, with paginated results.
    def me
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, per_page_max].min

      relation = me_articles_relation(num)
      if native_me_serializable?(relation)
        rows = relation.pluck(*ME_PLUCK_COLUMNS)
        json_body = serialize_articles_me_natively(rows)
        if json_body
          render json: json_body
          return
        end
      end

      legacy_me(relation)
    end

    def unpublish
      @article = Article.find(params[:id])

      authorize @article, :revoke_publication?

      if Articles::Unpublish.call(@user, @article)
        payload = { action: "api_article_unpublish", article_id: @article.id }
        Audit::Logger.log(:admin_api, @user, payload)

        render status: :no_content
      else
        render json: { message: @article.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def search
      # I temporarily added a new search endpoint in the interest of getting the chatGPT plugin live without changing
      # the existing index endpoint. There are some experiments which we want to conduct which I think makes sense on
      # a new endpoint rather than an existing one. We may want to refactor the index one in the future.
      articles = Articles::ApiSearchQuery.call(params)

      if native_index_serializable?(articles)
        rows = articles.except(:includes).pluck(*INDEX_PLUCK_COLUMNS)
        single_body_markdown = nil
        if rows.size == 1
          refetched = Article.where(id: rows[0][0]).pick(*INDEX_PLUCK_COLUMNS, :body_markdown)
          if refetched
            single_body_markdown = refetched.pop
            rows = [refetched]
          else
            rows = []
          end
        end
        json_body = serialize_articles_search_natively(rows, single_body_markdown: single_body_markdown)
        if json_body
          set_surrogate_key_header(Article.table_key, rows.map { |row| "#{Article.table_key}/#{row[0]}" })
          render json: json_body
          return
        end
      end

      legacy_search(articles)
    end

    def preview
      authorize(Article)

      article_hash = extract_preview_article_hash
      markdown = preview_markdown(article_hash)
      result = ContentRenderer.new(markdown, source: Article.new, user: @user).process_article
      front_matter = result.front_matter.to_h

      render json: {
        processed_html: result.processed_html,
        body_html: result.processed_html,
        title: front_matter["title"] || article_hash[:title] || params[:title],
        description: front_matter["description"] || article_hash[:description] || params[:description],
        tags: preview_tags(front_matter, article_hash),
        cover_image: preview_cover_image(front_matter, article_hash),
        reading_time_minutes: result.reading_time,
        ai_disclosure_level: preview_ai_disclosure_level(front_matter, article_hash)
      }, status: :ok
    rescue StandardError => e
      error_unprocessable_entity(ErrorMessages::Clean.call(e.message))
    end

    private

    def legacy_index(relation)
      @articles = relation.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate
      set_index_surrogate_keys(@articles.map(&:id))
    end

    def legacy_show
      @article = Article.published.from_subforem
        .includes(user: :profile)
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find(params[:id])
        .decorate

      set_surrogate_key_header @article.record_key
    end

    def legacy_show_by_slug
      @article = Article.published.from_subforem
        .includes(user: :profile)
        .select(SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find_by!(path: "/#{params[:username]}/#{params[:slug]}")
        .decorate

      set_surrogate_key_header @article.record_key
      render "show"
    end

    def me_articles_relation(per_page_num)
      scope = case params[:status]
              when "published"
                @user.articles.published.from_subforem
              when "unpublished"
                @user.articles.unpublished.from_subforem
              when "all"
                @user.articles.from_subforem
              else
                @user.articles.published.from_subforem
              end

      scope.order(published_at: :desc, created_at: :desc).page(params[:page]).per(per_page_num)
    end

    def legacy_me(relation)
      @articles = relation
        .includes({ user: :profile }, :organization)
        .select(ME_ATTRIBUTES_FOR_SERIALIZATION)
        .decorate
    end

    def legacy_search(articles)
      # This adds some inconsistency where we omit the body markdown when the response has more than 1 article because
      # ChatGPT cannot process the long body request.
      # Load the page once and only re-query (with body_markdown) when it has at most one article, rather than
      # running a separate COUNT over the full search before every load.
      @articles = articles.select(INDEX_ATTRIBUTES_FOR_SERIALIZATION).decorate
      if @articles.size == 1
        # Re-fetch the single hit by primary key rather than re-running the full-text search (rare terms that
        # return 0-1 results are the slowest searches, so repeating them doubled their cost).
        @articles = Article.includes([{ user: :profile }, :organization])
          .where(id: @articles.first.id)
          .select(ADDITIONAL_SEARCH_ATTRIBUTES_FOR_SERIALIZATION)
          .decorate
      end

      set_surrogate_key_header Article.table_key, @articles.map(&:record_key)
    end

    def set_index_surrogate_keys(article_ids)
      prefix = "#{Article.table_key}/"
      surrogate_keys = [Article.table_key]
      article_ids.each { |id| surrogate_keys << "#{prefix}#{id}" }
      if params[:tag].is_a?(String) && params[:top].present?
        tag_name = params[:tag].downcase.strip
        surrogate_keys << "api-articles-tag-#{tag_name}-top" if tag_name.match?(/\A[a-z0-9_-]+\z/)
      end
      set_surrogate_key_header(*surrogate_keys)
    end

    def native_serialization_supported?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?) &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC" &&
        !Images::Optimizer.imgproxy_enabled? &&
        !Images::Optimizer.cloudinary_enabled?
    end

    def native_index_serializable?(relation)
      relation.is_a?(ActiveRecord::Relation) && native_serialization_supported?
    end

    def native_show_serializable?
      return false unless native_serialization_supported?

      raw_id = params[:id]
      if raw_id.is_a?(Integer)
        raw_id.positive? && raw_id <= POSITIVE_INT32_MAX
      elsif raw_id.is_a?(String) && raw_id.match?(/\A\d+\z/)
        parsed = raw_id.to_i
        parsed.positive? && parsed <= POSITIVE_INT32_MAX
      else
        false
      end
    end

    def native_me_serializable?(relation)
      native_index_serializable?(relation) &&
        ActiveSupport::JSON::Encoding.use_standard_json_time_format &&
        ActiveSupport::JSON::Encoding.time_precision == 3
    end

    def serialize_articles_index_natively(rows)
      return "[]" if rows.empty?

      users_flat, user_idx_by_id = native_index_users_payload(rows)
      return unless users_flat

      orgs_flat, org_idx_by_id, org_custom_domains = native_index_orgs_payload(rows)
      articles_flat, base_urls = native_index_articles_payload(rows, user_idx_by_id, org_idx_by_id, org_custom_domains)
      return unless articles_flat

      ForemNative.serialize_api_articles_json(
        articles_flat,
        users_flat,
        orgs_flat,
        native_index_flare_tags_payload(rows),
        base_urls,
        native_index_config,
      )
    end

    def serialize_article_show_natively(row)
      rows = [row]
      users_flat, user_idx_by_id = native_index_users_payload(rows)
      return unless users_flat

      orgs_flat, org_idx_by_id, org_custom_domains = native_index_orgs_payload(rows)
      articles_flat, base_urls = native_index_articles_payload(rows, user_idx_by_id, org_idx_by_id, org_custom_domains)
      return unless articles_flat

      ForemNative.serialize_api_article_show_json(
        articles_flat,
        row[25],
        row[26],
        users_flat,
        orgs_flat,
        native_index_flare_tags_payload(rows),
        base_urls,
        native_index_config,
      )
    end

    def serialize_articles_search_natively(rows, single_body_markdown: nil)
      return "[]" if rows.empty?

      users_flat, user_idx_by_id = native_index_users_payload(rows)
      return unless users_flat

      orgs_flat, org_idx_by_id, org_custom_domains = native_index_orgs_payload(rows)
      articles_flat, base_urls = native_index_articles_payload(rows, user_idx_by_id, org_idx_by_id, org_custom_domains)
      return unless articles_flat

      include_body_markdown = rows.size == 1

      ForemNative.serialize_api_articles_search_json(
        articles_flat,
        include_body_markdown,
        single_body_markdown,
        users_flat,
        orgs_flat,
        native_index_flare_tags_payload(rows),
        base_urls,
        native_index_config,
      )
    end

    def serialize_articles_me_natively(rows)
      return "[]" if rows.empty?

      user_flat = native_me_user_payload
      orgs_flat, org_idx_by_id, org_custom_domains = native_index_orgs_payload(rows, org_col_idx: 1)
      articles_flat, base_urls = native_me_articles_payload(rows, org_idx_by_id, org_custom_domains)
      return unless articles_flat

      ForemNative.serialize_api_articles_me_json(
        articles_flat,
        user_flat,
        orgs_flat,
        native_index_flare_tags_payload(rows, tag_col_idx: 14),
        base_urls,
        native_index_config,
      )
    end

    def native_me_user_payload
      website = if @user.association(:profile).loaded?
                  @user.profile&.website_url
                else
                  Profile.where(user_id: @user.id).pick(:website_url)
                end
      processed_website = website.present? ? website.to_s.strip : nil
      [
        @user.id,
        @user.name,
        @user.username,
        @user.twitter_username,
        @user.github_username,
        processed_website,
        @user.profile_image_url_for(length: 640),
        @user.profile_image_url_for(length: 90),
      ]
    end

    def native_me_articles_payload(rows, org_idx_by_id, org_custom_domains)
      base_urls = []
      base_url_idx_by_domain = {}
      articles_flat = []

      rows.each do |row|
        org_id = row[1]
        custom_domain = org_id ? org_custom_domains[org_id] : nil
        url_path = custom_domain ? "/#{row[7]}" : row[8]
        base_url_idx = base_url_idx_by_domain[custom_domain] ||= begin
          idx = base_urls.size
          base_urls << URL.url(nil, custom_domain)
          idx
        end

        pub_sec, pub_millis = extract_epoch_sec_and_millis(row[5])
        crossposted_sec = extract_epoch_sec(row[6])
        return nil if pub_sec == :invalid || crossposted_sec == :invalid

        articles_flat.push(
          row[0], org_idx_by_id[org_id] || -1, base_url_idx, url_path,
          row[2], row[3], row[4], pub_sec, pub_millis, crossposted_sec,
          row[7], row[8], row[9], row[10], row[11], row[12], row[13], row[14], row[15], row[16]
        )
      end

      [articles_flat, base_urls]
    end

    def extract_epoch_sec_and_millis(value)
      return [nil, nil] if value.nil?
      return [value.tv_sec, value.tv_usec / 1000] if value.respond_to?(:tv_sec) && value.respond_to?(:tv_usec)

      [:invalid, nil]
    end

    def native_index_users_payload(rows)
      user_ids = rows.filter_map { |row| row[1] }.uniq
      return if user_ids.empty?

      users_by_id = User.where(id: user_ids).select(*USER_INDEX_COLUMNS).index_by(&:id)
      websites_by_user_id = Profile.where(user_id: user_ids).pluck(:user_id, :website_url).to_h

      users_flat = []
      user_idx_by_id = {}
      user_ids.each do |uid|
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

    def native_index_orgs_payload(rows, org_col_idx: 2)
      org_ids = rows.filter_map { |row| row[org_col_idx] }.uniq
      return [[], {}, {}] if org_ids.empty?

      orgs_by_id = Organization.where(id: org_ids).select(*ORG_INDEX_COLUMNS).index_by(&:id)
      allow_custom_domain = !(RequestStore.store[:user_signed_in] && RequestStore.store[:custom_domain_org].blank?)

      orgs_flat = []
      org_idx_by_id = {}
      org_custom_domains = {}
      org_ids.each do |oid|
        org = orgs_by_id[oid]
        next unless org

        org_idx_by_id[oid] = orgs_flat.size / 5
        orgs_flat.push(
          org.name,
          org.username,
          org.slug,
          org.profile_image_url_for(length: 640),
          org.profile_image_url_for(length: 90),
        )
        if allow_custom_domain && org.custom_domain.present? &&
            FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor.new(org))
          org_custom_domains[oid] = org.custom_domain
        end
      end

      [orgs_flat, org_idx_by_id, org_custom_domains]
    end

    def native_index_flare_tags_payload(rows, tag_col_idx: 10)
      flare_map = FlareTag::FLARE_TAG_IDS_HASH
      return [] if flare_map.empty?

      flare_names = flare_map.keys
      has_flare_match = rows.any? do |row|
        raw_tags = row[tag_col_idx]
        raw_tags.is_a?(String) && !raw_tags.empty? && ForemNative.match_first_flare_tag(raw_tags, flare_names) != false
      end
      return [] unless has_flare_match

      tags_by_id = FlareTag.tags_by_id
      flare_tags_flat = []
      flare_map.each do |match_name, tag_id|
        tag = tags_by_id[tag_id]
        flare_tags_flat.push(match_name, tag&.name, tag&.bg_color_hex, tag&.text_color_hex)
      end
      flare_tags_flat
    end

    def native_index_articles_payload(rows, user_idx_by_id, org_idx_by_id, org_custom_domains)
      subforem_disabled = Subforem.disabled_by_env?
      subforem_domains = subforem_disabled ? {} : Subforem.cached_id_to_domain_hash
      default_subforem_id = RequestStore.store[:default_subforem_id]
      social_image_cutoff = Time.zone.local(2026, 3, 1)

      base_urls = []
      base_url_idx_by_domain = {}
      articles_flat = []

      rows.each do |row|
        user_idx = user_idx_by_id[row[1]]
        ai_idx = AI_DISCLOSURE_INDICES[row[24]]
        return nil unless user_idx && ai_idx

        domain, url_path = resolve_article_domain_and_path(
          row, org_custom_domains, subforem_disabled, subforem_domains, default_subforem_id
        )
        base_url_idx = base_url_idx_by_domain[domain] ||= begin
          idx = base_urls.size
          base_urls << URL.url(nil, domain)
          idx
        end

        timestamps = extract_article_epoch_secs(row)
        return nil unless timestamps

        social_image_large = row[7].present? && row[7] > social_image_cutoff
        append_native_article_row(articles_flat, row, user_idx, org_idx_by_id[row[2]] || -1,
                                  base_url_idx, url_path, ai_idx, timestamps, social_image_large)
      end

      [articles_flat, base_urls]
    end

    def resolve_article_domain_and_path(row, org_custom_domains, subforem_disabled, subforem_domains,
                                        default_subforem_id)
      custom_domain = row[2] ? org_custom_domains[row[2]] : nil
      return [custom_domain, "/#{row[11]}"] if custom_domain
      return [nil, row[12]] if subforem_disabled

      sf_id = row[22] || default_subforem_id
      domain = sf_id ? subforem_domains[sf_id] : nil
      [domain, row[12]]
    end

    def extract_article_epoch_secs(row)
      created_sec = extract_epoch_sec(row[16])
      edited_sec = extract_epoch_sec(row[17])
      crossposted_sec = extract_epoch_sec(row[8])
      published_sec = extract_epoch_sec(row[7])
      last_comment_sec = extract_epoch_sec(row[18])
      return if created_sec == :invalid || edited_sec == :invalid ||
        crossposted_sec == :invalid || published_sec == :invalid || last_comment_sec == :invalid

      [created_sec, edited_sec, crossposted_sec, published_sec, last_comment_sec]
    end

    def extract_epoch_sec(value)
      return if value.nil?
      return value.tv_sec if value.respond_to?(:tv_sec)

      :invalid
    end

    def append_native_article_row(articles_flat, row, user_idx, org_idx, base_url_idx, url_path, ai_idx, timestamps,
                                  social_image_large)
      created_sec, edited_sec, crossposted_sec, published_sec, last_comment_sec = timestamps
      articles_flat.push(
        row[0], user_idx, org_idx, base_url_idx, url_path,
        row[3], row[4], row[5], row[6], row[9], row[20],
        row[10], row[11], row[12], row[13], row[14], row[15],
        row[21], row[22], row[23], row[19] ? true : false, ai_idx,
        created_sec, edited_sec, crossposted_sec, published_sec, last_comment_sec,
        social_image_large ? true : false
      )
    end

    def native_index_config
      subforem_id = RequestStore.store[:subforem_id]
      cf_enabled = Images::Optimizer.cloudflare_enabled?
      [
        Time.current.year,
        Settings::General.main_social_image.to_s,
        Settings::UserExperience.cover_image_height(subforem_id: subforem_id).to_i,
        Settings::UserExperience.cover_image_fit(subforem_id: subforem_id).to_s,
        Rails.env.development?,
        cf_enabled ? 1 : 0,
        cf_enabled ? ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"] : nil,
        Images::Optimizer::CLOUDFLARE_DIRECTORY,
        I18n.t("models.article.ai_disclosure.not_disclosed"),
        I18n.t("models.article.ai_disclosure.no_ai"),
        I18n.t("models.article.ai_disclosure.some_ai"),
        I18n.t("models.article.ai_disclosure.fully_autonomous"),
        ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      ]
    end

    def extract_preview_article_hash
      return params[:article] if params[:article].is_a?(ActionController::Parameters) || params[:article].is_a?(Hash)

      {}
    end

    def preview_markdown(article_hash)
      article_hash[:body_markdown] || params[:body_markdown] || params[:article_body]
    end

    def preview_tags(front_matter, article_hash)
      raw_tags = front_matter["tags"] || article_hash[:tags] || params[:tags]
      return unless raw_tags

      raw_tags_input = raw_tags.is_a?(Array) ? raw_tags.join(", ") : raw_tags
      Article.new.tag_list.add(raw_tags_input, parser: ActsAsTaggableOn::TagParser)
    end

    def preview_cover_image(front_matter, article_hash)
      raw_cover_image = if front_matter.key?("cover_image")
                          front_matter["cover_image"]
                        else
                          article_hash[:main_image] || article_hash[:cover_image] ||
                            params[:main_image] || params[:cover_image]
                        end
      ApplicationController.helpers.cloud_cover_url(raw_cover_image) if raw_cover_image
    end

    def preview_ai_disclosure_level(front_matter, article_hash)
      front_matter["ai_disclosure_level"] ||
        front_matter["ai_disclosure"] ||
        article_hash[:ai_disclosure_level] ||
        params[:ai_disclosure_level]
    end

    def invalid_tags_present?
      tag_params = [params[:tag], params[:tags], params[:tags_exclude]].flatten.compact

      return false if tag_params.empty?

      all_tags = tag_params.flat_map { |t| t.to_s.split(",") }.map(&:strip).compact_blank

      all_tags.any? { |t| !t.match?(/\A[[:alnum:]\-]+\z/i) }
    end

    # Uses the same ArticlePolicy#update? as the web editor. A caller who may not
    # edit the post gets a 404, not a 401, as before: this keeps the existing
    # response and does not reveal that an unpublished draft exists.
    def find_updatable_article
      return @article if defined?(@article) && @article

      article = Article.includes(:user).find(params[:id])
      authorize article, :update?
      @article = article
    rescue Pundit::NotAuthorizedError => e
      raise if e.is_a?(ApplicationPolicy::UserSuspendedError)

      raise ActiveRecord::RecordNotFound
    end

    # @param organization_id [Integer, nil] the post's organization before the update,
    #        i.e. the organization whose admin rights allowed the edit
    def log_non_author_update(organization_id)
      payload = {
        action: "api_article_update",
        article_id: @article.id,
        organization_id: organization_id,
        changed_attributes: @article.saved_changes.keys - %w[updated_at]
      }
      Audit::Logger.log(:admin_api, @user, payload)
    end

    def per_page_max
      (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
    end

    # Updates stay permissive: every article predating this feature is
    # `not_disclosed`, so requiring a value here would break existing clients
    # editing old posts. Warn instead.
    def assign_ai_disclosure_warning
      return unless Settings::General.enable_ai_disclosure
      return unless @article.not_disclosed?

      @warnings = [
        "This article has ai_disclosure_level=not_disclosed. Set it to one of: " \
        "#{Article.ai_disclosure_levels.keys.join(', ')}. See #{URL.url('llms.txt')}"
      ]
    end

    def article_params
      convert_labels_param
      allowed_params = [
        :title, :body_markdown, :published, :series,
        :main_image, :canonical_url, :description, { tags: [] },
        :published_at, :subforem_id, :language
      ]
      allowed_params << :ai_disclosure_level if Settings::General.enable_ai_disclosure
      allowed_params << :organization_id if params.dig("article", "organization_id") && allowed_to_change_org_id?
      # allow video_source_url only for supported hosts; a blank value removes the cover video
      if params["article"]&.key?("video_source_url") &&
          Article.permitted_video_source_url?(params["article"]["video_source_url"])
        allowed_params << :video_source_url
      end
      if @user.super_admin?
        allowed_params << :clickbait_score
        allowed_params << :compellingness_score
        allowed_params << { labels: [] }
      end
      params.require(:article).permit(allowed_params)
    end

    def allowed_to_change_org_id?
      requested_org_id = params.dig("article", "organization_id")
      return OrganizationMembership.member.exists?(user: @user, organization_id: requested_org_id) if @article.nil?

      potential_user = @article.user
      return true if potential_user == @user && @user.any_admin?

      return false unless OrganizationMembership.member.exists?(user: potential_user,
                                                                organization_id: requested_org_id)

      # Require admin membership in the target organization when editing another author's article
      potential_user == @user || @user.org_admin?(requested_org_id) || @user.any_admin?
    end

    def validate_article_param_is_hash
      return if params.to_unsafe_h[:article].is_a?(Hash)

      message = I18n.t("api.v0.articles_controller.must_be_json", type: params[:article].class.name)
      render json: { error: message, status: 422 }, status: :unprocessable_entity
    end

    # An unrecognized value would otherwise raise ArgumentError from the enum
    # setter and surface as a 500.
    def validate_ai_disclosure_level
      return unless Settings::General.enable_ai_disclosure

      value = params[:article][:ai_disclosure_level]
      if value.nil? || value.to_s.strip.empty?
        params[:article].delete(:ai_disclosure_level)
        return
      end
      return if Article.normalize_ai_disclosure_level(value)

      error_unprocessable_entity(
        "ai_disclosure_level must be one of: #{Article.ai_disclosure_levels.keys.join(', ')}",
      )
    end

    def convert_labels_param
      labels = params.dig("article", "labels")
      if labels.present?
        labels = labels.is_a?(String) ? labels.gsub(" ", "").split(",") : labels
        params[:article][:labels] = labels
      end
    end

    def validate_page_limit
      page = [params[:page].to_i, 1].max
      page_limit_exceeded = page > MAX_UNAUTHENTICATED_PAGE
      offset_limit_exceeded = !page_limit_exceeded &&
        ((page - 1) * effective_per_page_for_pagination) > MAX_UNAUTHENTICATED_OFFSET

      return unless page_limit_exceeded || offset_limit_exceeded
      return if authenticate_with_api_key

      response.headers["Cache-Control"] = "no-store"
      response.headers["Surrogate-Control"] = "no-store"
      message_key = if page_limit_exceeded
                      "api.v0.articles_controller.page_limit_exceeded"
                    else
                      "api.v0.articles_controller.offset_limit_exceeded"
                    end
      render json: { error: I18n.t(message_key), status: 401 }, status: :unauthorized
    end

    def effective_per_page_for_pagination
      if action_name == "index" && params[:username].present? && params[:state] == "all" && params[:per_page].blank?
        return per_page_max
      end

      requested = params[:per_page].to_i
      return ArticleApiIndexService::DEFAULT_PER_PAGE unless requested.positive?

      [requested, per_page_max].min
    end
  end
end
