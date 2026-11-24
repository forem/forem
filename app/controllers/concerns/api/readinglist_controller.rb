module Api
  module ReadinglistController
    extend ActiveSupport::Concern

    INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION = %i[id reactable_id created_at status].freeze
    private_constant :INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION

    PER_PAGE_MAX = 100
    private_constant :PER_PAGE_MAX

    ARTICLE_PLUCK_COLUMNS = %i[
      id user_id organization_id collection_id
      title description main_image published_at crossposted_at social_image
      cached_tag_list slug path canonical_url comments_count
      public_reactions_count created_at edited_at last_comment_at published
      video_thumbnail_url reading_time subforem_id language ai_disclosure_level
    ].freeze
    private_constant :ARTICLE_PLUCK_COLUMNS

    ORG_COLUMNS = %i[
      id name username slug profile_image custom_domain
    ].freeze
    private_constant :ORG_COLUMNS

    USER_JOIN_COLUMNS = [
      :id, :name, :username, :twitter_username, :github_username, :profile_image,
      "profiles.website_url AS website_url"
    ].freeze
    private_constant :USER_JOIN_COLUMNS

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
      per_page = (params[:per_page] || 30).to_i
      num = [per_page, PER_PAGE_MAX].min

      base_scope = Reaction
        .readinglist
        .where(user_id: @user.id)
        .where.not(status: "archived")
        .order(created_at: :desc)
        .page(params[:page])
        .per(num)

      if native_readinglist_serializable? && (json_body = serialize_readinglist_natively(base_scope))
        render json: json_body
        return
      end

      @readinglist = base_scope.select(INDEX_REACTIONS_ATTRIBUTES_FOR_SERIALIZATION)

      articles = Article
        .includes(:organization)
        .select(ArticlesController::INDEX_ATTRIBUTES_FOR_SERIALIZATION)
        .where(id: @readinglist.map(&:reactable_id))
        .decorate

      @users_by_id = User
        .joins(:profile)
        .select(UsersController::SHOW_ATTRIBUTES_FOR_SERIALIZATION)
        .find(articles.map(&:user_id))
        .each { |user| hydrate_joined_profile(user) }
        .index_by(&:id)

      articles_by_id = articles.index_by(&:id)

      @articles_by_reaction_ids = @readinglist.each_with_object({}) do |reaction, result|
        result[reaction.id] = articles_by_id[reaction.reactable_id]
      end
    end

    private

    def native_readinglist_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?) &&
        I18n.locale == :en &&
        Time.zone&.tzinfo&.name == "Etc/UTC" &&
        !Images::Optimizer.imgproxy_enabled? &&
        !Images::Optimizer.cloudinary_enabled?
    end

    def serialize_readinglist_natively(scope)
      reaction_rows = scope.pluck(:id, :reactable_id, :created_at, :status)
      return "[]" if reaction_rows.empty?

      article_ids = reaction_rows.pluck(1).uniq
      articles_by_id = Article.where(id: article_ids).pluck(*ARTICLE_PLUCK_COLUMNS).index_by { |row| row[0] }
      ordered_articles = []
      reactions_flat = []

      reaction_rows.each do |rx_id, article_id, created_at, status|
        article_row = articles_by_id[article_id]
        return nil unless article_row
        return nil unless created_at.nil? || created_at.respond_to?(:tv_sec)

        ordered_articles << article_row
        reactions_flat.push(rx_id, status, created_at&.tv_sec)
      end

      users_flat, user_idx_by_id = native_readinglist_users_payload(ordered_articles)
      return unless users_flat

      orgs_flat, org_idx_by_id, org_custom_domains = native_readinglist_orgs_payload(ordered_articles)
      articles_flat, base_urls = native_readinglist_articles_payload(
        ordered_articles, user_idx_by_id, org_idx_by_id, org_custom_domains
      )
      return unless articles_flat

      ForemNative.serialize_api_readinglist_json(
        reactions_flat,
        articles_flat,
        users_flat,
        orgs_flat,
        base_urls,
        native_readinglist_config,
      )
    end

    def native_readinglist_users_payload(article_rows)
      user_ids = article_rows.filter_map { |row| row[1] }.uniq
      return if user_ids.empty?

      users_by_id = User.joins(:profile).where(id: user_ids).select(*USER_JOIN_COLUMNS).index_by(&:id)
      users_flat = []
      user_idx_by_id = {}

      user_ids.each do |uid|
        user = users_by_id[uid]
        return nil unless user

        website = user[:website_url]
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

    def native_readinglist_orgs_payload(article_rows)
      org_ids = article_rows.filter_map { |row| row[2] }.uniq
      return [[], {}, {}] if org_ids.empty?

      orgs_by_id = Organization.where(id: org_ids).select(*ORG_COLUMNS).index_by(&:id)
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

    def native_readinglist_articles_payload(rows, user_idx_by_id, org_idx_by_id, org_custom_domains)
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
        timestamps = extract_readinglist_article_timestamps(row)
        return nil unless user_idx && ai_idx && timestamps

        domain, url_path = resolve_readinglist_domain_and_path(
          row, org_custom_domains, subforem_disabled, subforem_domains, default_subforem_id
        )
        base_url_idx = base_url_idx_by_domain[domain] ||= begin
          idx = base_urls.size
          base_urls << URL.url(nil, domain)
          idx
        end

        social_image_large = row[7].present? && row[7] > social_image_cutoff
        append_readinglist_article_row(
          articles_flat, row, user_idx, org_idx_by_id[row[2]] || -1,
          base_url_idx, url_path, ai_idx, timestamps, social_image_large
        )
      end

      [articles_flat, base_urls]
    end

    def resolve_readinglist_domain_and_path(row, org_custom_domains, subforem_disabled, subforem_domains,
                                            default_subforem_id)
      custom_domain = row[2] ? org_custom_domains[row[2]] : nil
      return [custom_domain, "/#{row[11]}"] if custom_domain
      return [nil, row[12]] if subforem_disabled

      sf_id = row[22] || default_subforem_id
      [sf_id ? subforem_domains[sf_id] : nil, row[12]]
    end

    def extract_readinglist_article_timestamps(row)
      created_sec = extract_readinglist_epoch_sec(row[16])
      edited_sec = extract_readinglist_epoch_sec(row[17])
      crossposted_sec = extract_readinglist_epoch_sec(row[8])
      published_sec = extract_readinglist_epoch_sec(row[7])
      last_comment_sec = extract_readinglist_epoch_sec(row[18])
      return if created_sec == :invalid || edited_sec == :invalid ||
        crossposted_sec == :invalid || published_sec == :invalid || last_comment_sec == :invalid

      [created_sec, edited_sec, crossposted_sec, published_sec, last_comment_sec]
    end

    def append_readinglist_article_row(articles_flat, row, user_idx, org_idx, base_url_idx, url_path,
                                       ai_idx, timestamps, social_image_large)
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

    def extract_readinglist_epoch_sec(value)
      return if value.nil?
      return value.tv_sec if value.respond_to?(:tv_sec)

      :invalid
    end

    def native_readinglist_config
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

    def hydrate_joined_profile(user)
      profile = Profile.instantiate(
        "user_id" => user.id,
        "summary" => user[:summary],
        "location" => user[:location],
        "website_url" => user[:website_url],
      )
      profile.readonly!
      user.association(:profile).target = profile
    end
  end
end
