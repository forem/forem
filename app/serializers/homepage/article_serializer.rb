module Homepage
  class ArticleSerializer < ApplicationSerializer
    USER_ATTRIBUTES = %i[id name profile_image username].freeze
    ORGANIZATION_ATTRIBUTES = %i[id name profile_image slug].freeze
    NATIVE_ARTICLE_COLUMNS = %i[
      id
      user_id
      organization_id
      favorited_by_user_id
      path
      public_reactions_count
      reading_time
      title
      comments_count
      displayed_comments_count
      video_duration_in_seconds
      video_thumbnail_url
      cached_tag_list
      published_at
      crossposted_at
      type_of
    ].freeze

    # Thin wrapper signaling that a payload is already encoded as `{"result":[...]}` JSON.
    EncodedJson = Struct.new(:json) do
      def to_str
        json
      end
    end

    # @param relation [ActiveRecord::Relation<Article>]
    #
    # @return [Array<Hash>]
    def self.serialized_collection_from(relation:)
      articles = relation.load
      article_records = articles.to_a

      ActiveRecord::Associations::Preloader.new(
        records: article_records, associations: :user, scope: User.select(USER_ATTRIBUTES),
      ).call
      ActiveRecord::Associations::Preloader.new(
        records: article_records, associations: :organization, scope: Organization.select(ORGANIZATION_ATTRIBUTES),
      ).call

      # Unfortunately the FlareTag class sends one SQL query per each article,
      # as we want to optimize by loading them in one query, we're using a different class
      tag_flares = Homepage::FetchTagFlares.call(articles)

      # One cache round-trip for every article's :public_reaction_categories
      Article.preload_reaction_counts_for_reactable(article_records)

      new(articles, params: { tag_flares: tag_flares }, is_collection: true)
        .serializable_hash[:data]
        .pluck(:attributes)
    end

    # Streams `{"result":[...]}` JSON directly through `ForemNative` without hydrating
    # `Article` or `Tag` ActiveRecord models, building `JSONAPI::Serializer` wrapper hashes,
    # or running `ActiveSupport::JSON.encode`. Falls back transparently to
    # `serialized_collection_from` for out-of-domain inputs (e.g., `status` articles,
    # non-English locales, non-UTC timezones, or Cloudinary/Imgproxy optimizers).
    #
    # @param relation [ActiveRecord::Relation<Article>]
    #
    # @return [EncodedJson]
    def self.serialized_json_from(relation:)
      if native_json_serializable?(relation)
        rows = relation.unscope(:select, :includes).pluck(*NATIVE_ARTICLE_COLUMNS)
        return EncodedJson.new('{"result":[]}') if rows.empty?

        json = serialize_rows_natively(rows)
        return EncodedJson.new(json) if json
      end

      EncodedJson.new({ result: serialized_collection_from(relation: relation) }.to_json)
    end

    class << self
      private

      def native_json_serializable?(relation)
        ForemNative.available? &&
          relation.is_a?(ActiveRecord::Relation) &&
          !relation.loaded? &&
          !relation.eager_loading? &&
          I18n.locale == :en &&
          Time.zone&.tzinfo&.name == "Etc/UTC" &&
          !Images::Optimizer.imgproxy_enabled? &&
          !Images::Optimizer.cloudinary_enabled?
      end

      def serialize_rows_natively(rows)
        return if rows.any? { |row| row[15] == "status" }

        users_flat, user_idx_by_id = native_users_payload(rows)
        return unless users_flat

        orgs_flat, org_idx_by_id = native_orgs_payload(rows)
        articles_flat = native_articles_payload(rows, user_idx_by_id, org_idx_by_id)
        return unless articles_flat

        reaction_counts_flat, reaction_counts_lens = native_reaction_counts_payload(rows)
        return unless reaction_counts_flat

        ForemNative.serialize_homepage_articles_json(
          articles_flat,
          users_flat,
          orgs_flat,
          native_flare_tags_payload(rows),
          native_reaction_categories_payload,
          reaction_counts_flat,
          reaction_counts_lens,
          native_config_payload,
        )
      end

      def native_users_payload(rows)
        user_ids = rows.filter_map { |row| row[1] }.uniq
        return if user_ids.empty?

        users_by_id = User.where(id: user_ids).select(*USER_ATTRIBUTES).index_by(&:id)
        users_flat = []
        user_idx_by_id = {}
        user_ids.each do |uid|
          user = users_by_id[uid]
          return nil unless user

          user_idx_by_id[uid] = users_flat.size / 3
          users_flat.push(user.name, user.profile_image_90, user.username)
        end

        [users_flat, user_idx_by_id]
      end

      def native_orgs_payload(rows)
        org_ids = rows.filter_map { |row| row[2] }.uniq
        return [[], {}] if org_ids.empty?

        orgs_by_id = Organization.where(id: org_ids).select(*ORGANIZATION_ATTRIBUTES).index_by(&:id)
        orgs_flat = []
        org_idx_by_id = {}
        org_ids.each do |oid|
          org = orgs_by_id[oid]
          next unless org

          org_idx_by_id[oid] = orgs_flat.size / 3
          orgs_flat.push(org.name, org.profile_image_90, org.slug)
        end

        [orgs_flat, org_idx_by_id]
      end

      def native_flare_tags_payload(rows)
        flare_names = ::Constants::Tags::FLARE_TAG_NAMES
        return [] if flare_names.empty?

        matched_names = []
        rows.each do |row|
          raw_tags = row[12]
          next unless raw_tags.is_a?(String) && !raw_tags.empty?

          matched = ForemNative.match_first_flare_tag(raw_tags, flare_names)
          matched_names << matched if matched.is_a?(String)
        end
        return [] if matched_names.empty?

        matched_names.uniq!
        tags_by_name = Tag.where(name: matched_names)
          .pluck(:name, :bg_color_hex, :text_color_hex)
          .each_with_object({}) { |(name, bg, text), h| h[name] = [bg, text] }

        flare_tags_flat = []
        flare_names.each do |match_name|
          if (attrs = tags_by_name[match_name])
            flare_tags_flat.push(match_name, match_name, attrs[0], attrs[1])
          else
            flare_tags_flat.push(match_name, nil, nil, nil)
          end
        end
        flare_tags_flat
      end

      def native_reaction_categories_payload
        categories_flat = []
        ReactionCategory.for_view.each do |cat|
          categories_flat.push(cat.slug.to_s, cat.name, cat.icon, cat.position)
        end
        categories_flat
      end

      def native_reaction_counts_payload(rows)
        article_ids = rows.pluck(0)
        keys_by_id = article_ids.index_with { |id| "reaction_counts_for_reactable-Article-#{id}" }
        counts_by_key = fetch_reaction_counts_by_key(article_ids, keys_by_id)
        flatten_reaction_counts(article_ids, keys_by_id, counts_by_key)
      end

      def fetch_reaction_counts_by_key(article_ids, keys_by_id)
        counts_by_key = Rails.cache.read_multi(*keys_by_id.values)
        missing_ids = article_ids.reject { |id| counts_by_key.key?(keys_by_id[id]) }
        return counts_by_key if missing_ids.empty?

        computed_by_id = Hash.new { |h, k| h[k] = [] }
        Reaction.where(reactable_type: "Article", reactable_id: missing_ids)
          .group(:reactable_id, :category).count
          .each { |(id, category), count| computed_by_id[id] << { category: category, count: count } }

        to_write = missing_ids.each_with_object({}) { |id, hash| hash[keys_by_id[id]] = computed_by_id[id] }
        Rails.cache.write_multi(to_write, expires_in: 10.hours)
        counts_by_key.merge(to_write)
      end

      def flatten_reaction_counts(article_ids, keys_by_id, counts_by_key)
        counts_flat = []
        counts_lens = []
        article_ids.each do |id|
          entries = counts_by_key[keys_by_id[id]]
          return nil unless entries.is_a?(Array)

          counts_lens << entries.size
          entries.each do |entry|
            return nil unless entry.is_a?(Hash)

            cat = entry[:category]
            cnt = entry[:count]
            return nil unless (cat.is_a?(String) || cat.is_a?(Symbol)) && cnt.is_a?(Integer)

            counts_flat.push(cat.is_a?(Symbol) ? cat.name : cat, cnt)
          end
        end

        [counts_flat, counts_lens]
      end

      def native_articles_payload(rows, user_idx_by_id, org_idx_by_id)
        articles_flat = []
        rows.each do |row|
          user_idx = user_idx_by_id[row[1]]
          return nil unless user_idx

          published_sec = extract_epoch_sec(row[13])
          crossposted_sec = extract_epoch_sec(row[14])
          return nil if published_sec == :invalid || crossposted_sec == :invalid

          articles_flat.push(
            row[0], user_idx, org_idx_by_id[row[2]] || -1,
            row[3], row[4], row[5], row[6], row[7], row[1],
            row[8], row[9], row[10], row[11], row[12],
            published_sec, crossposted_sec
          )
        end
        articles_flat
      end

      def extract_epoch_sec(value)
        return if value.nil?
        return value.tv_sec if value.respond_to?(:tv_sec)

        :invalid
      end

      def native_config_payload
        cf_enabled = Images::Optimizer.cloudflare_enabled?
        [
          Time.current.year,
          cf_enabled ? 1 : 0,
          cf_enabled ? ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"] : nil,
          Images::Optimizer::CLOUDFLARE_DIRECTORY,
          ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
        ]
      end
    end

    attributes(
      :class_name,
      :cloudinary_video_url,
      :favorited_by_user_id,
      :id,
      :path,
      :public_reactions_count,
      :readable_publish_date,
      :reading_time,
      :title,
      :user_id,
      :public_reaction_categories,
    )

    # return displayed_comments_count (excluding low score comments) if it was calculated earlier
    attribute :comments_count, (lambda do |article|
      article.displayed_comments_count? ? article.displayed_comments_count : article.comments_count
    end)
    attribute :video_duration_string, &:video_duration_in_minutes
    attribute :published_at_int, ->(article) { article.published_at.to_i }
    attribute :tag_list, ->(article) { article.cached_tag_list.to_s.split(", ") }
    attribute :flare_tag, ->(article, params) { params.dig(:tag_flares, article.id) }

    # Only include special title methods for status articles
    attribute :title_finalized_for_feed, if: proc { |article| article.type_of == "status" }
    attribute :title_for_metadata, if: proc { |article| article.type_of == "status" }

    attribute :user do |article|
      user = article.user

      {
        name: user.name,
        profile_image_90: user.profile_image_90,
        username: user.username
      }
    end

    attribute :organization, if: proc { |a| a.organization.present? } do |article|
      organization = article.organization

      {
        name: organization.name,
        profile_image_90: organization.profile_image_90,
        slug: organization.slug
      }
    end
  end
end
