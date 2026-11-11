module Articles
  class UpdateDependentEmbedsWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    lock_args_method: :lock_args

    BILLBOARD_ENGAGEMENT_DEBOUNCE = LiquidEmbedReference::BILLBOARD_ENGAGEMENT_INTERVAL
    DEFAULT_ENGAGEMENT_DEBOUNCE = LiquidEmbedReference::ENGAGEMENT_BACKOFF_BASE.seconds
    COLD_COALESCE_WINDOW = 2.minutes
    PENDING_CONTEXT_TTL = 10.minutes
    ENGAGEMENT_MARKER_TTL = 2.hours
    RECORD_PRIORITY = %w[Billboard Page Article Comment].freeze
    DYNAMIC_FEED_OPTION_REGEX = /\b(?:sort=(?:reactions|comments|score)|min_reactions=\d+|min_comments=\d+)\b/

    def self.lock_args(args)
      [args.first]
    end

    def self.schedule_for_article_change(article_id, organization_ids: [], tag_names: [], membership_changed: false)
      return false if article_id.blank?

      normalized_orgs = Array(organization_ids).compact.map(&:to_i).uniq
      normalized_tags = LiquidEmbedReference.parse_tag_list(Array(tag_names).join(","))

      status = LiquidEmbedReference.dependency_status_for_article(
        article_id,
        organization_ids: normalized_orgs,
        tag_names: normalized_tags,
        published_only: false,
      )
      return false unless status[:any]

      Rails.cache.delete(engagement_cooldown_key(article_id))
      merged = merge_pending_context!(
        article_id,
        org_ids: normalized_orgs,
        tags: normalized_tags,
        membership_changed: membership_changed,
      )

      payload = {
        "org_ids" => merged[:org_ids],
        "tags" => merged[:tags],
        "membership_changed" => merged[:membership_changed]
      }
      perform_async(article_id, payload)
      true
    end

    def self.schedule_for_engagement(article_id)
      return false if article_id.blank?
      return false if Rails.cache.exist?(pending_context_key(article_id))

      status = LiquidEmbedReference.dependency_status_for_article(article_id, published_only: true)
      return false unless status[:any]

      interval = status[:refresh_interval]
      long_backoff = !status[:billboard] && interval >= LiquidEmbedReference::COOLDOWN_GATE_THRESHOLD
      return false if long_backoff && Rails.cache.exist?(engagement_cooldown_key(article_id))

      delay = if status[:billboard]
                BILLBOARD_ENGAGEMENT_DEBOUNCE
              elsif long_backoff
                COLD_COALESCE_WINDOW
              else
                interval
              end

      debounce_key = engagement_debounce_key(article_id, billboard: status[:billboard])

      # Fixed trailing-edge debounce window: the first engagement event schedules a run
      # `delay` seconds out, while subsequent events in that window coalesce in cache
      # without pushing the scheduled timestamp forward (avoiding starvation).
      acquired = Rails.cache.write(debounce_key, true, unless_exist: true, expires_in: delay)
      return false if acquired == false

      Rails.cache.write(engagement_marker_key(article_id), interval.to_i, expires_in: delay + ENGAGEMENT_MARKER_TTL)
      perform_in(delay, article_id)
      true
    end

    def self.pending_context_key(article_id)
      "update_dependent_embeds:ctx:v1:#{article_id}"
    end

    def self.engagement_debounce_key(article_id, billboard:)
      tier = billboard ? "bb" : "std"
      "update_dependent_embeds:debounce:v1:#{tier}:#{article_id}"
    end

    def self.engagement_marker_key(article_id)
      "update_dependent_embeds:eng_marker:v1:#{article_id}"
    end

    def self.engagement_cooldown_key(article_id)
      "update_dependent_embeds:cooldown:v1:#{article_id}"
    end

    def self.record_cooldown_key(record_type, record_id)
      "update_dependent_embeds:rec_cd:v1:#{record_type}:#{record_id}"
    end

    def self.clear_engagement_debounce!(article_id)
      Rails.cache.delete(engagement_debounce_key(article_id, billboard: true))
      Rails.cache.delete(engagement_debounce_key(article_id, billboard: false))
    end

    def self.merge_pending_context!(article_id, org_ids:, tags:, membership_changed:)
      key = pending_context_key(article_id)
      existing = Rails.cache.read(key)
      merged = if existing.is_a?(Hash)
                 {
                   org_ids: (Array(existing[:org_ids] || existing["org_ids"]) + org_ids).uniq,
                   tags: (Array(existing[:tags] || existing["tags"]) + tags).uniq,
                   membership_changed: boolean_cast(existing[:membership_changed] || existing["membership_changed"]) ||
                     membership_changed,
                   structural: true
                 }
               else
                 {
                   org_ids: org_ids,
                   tags: tags,
                   membership_changed: membership_changed == true,
                   structural: true
                 }
               end
      Rails.cache.write(key, merged, expires_in: PENDING_CONTEXT_TTL)
      merged
    end
    private_class_method :merge_pending_context!

    def self.boolean_cast(val)
      val == true
    end
    private_class_method :boolean_cast

    def perform(article_id, options = nil)
      return if article_id.blank?

      self.class.clear_engagement_debounce!(article_id)
      scheduled_interval = consume_engagement_marker(article_id)
      pending = consume_pending_context(article_id, options)
      engagement_only = engagement_only_run?(scheduled_interval, options, pending)

      # Only narrow metadata columns are needed; skip hydrating the wide TOASTed article row.
      found_id, organization_id, raw_tag_list = Article
        .where(id: article_id)
        .pick(:id, :organization_id, :cached_tag_list)

      org_ids = ([organization_id] + pending[:org_ids]).compact.map(&:to_i).uniq
      current_tags = LiquidEmbedReference.parse_tag_list(raw_tag_list)
      all_tag_names = (current_tags + pending[:tags]).uniq
      membership_changed = pending[:membership_changed] || found_id.nil?

      if engagement_only && !membership_changed
        apply_post_engagement_cooldown!(
          article_id,
          scheduled_interval: scheduled_interval,
          org_ids: org_ids,
          tag_names: all_tag_names,
        )
      end

      ref_rows = fetch_matching_reference_rows(article_id, org_ids: org_ids, tag_names: all_tag_names)
      return if ref_rows.empty?

      grouped = group_reference_rows(ref_rows, all_tag_names: all_tag_names)
      return if grouped.empty?

      ordered_types = (RECORD_PRIORITY & grouped.keys) + (grouped.keys - RECORD_PRIORITY)
      ordered_types.each do |record_type|
        process_records_for_type(
          record_type,
          grouped[record_type],
          article_id: article_id,
          membership_changed: membership_changed,
          engagement_only: engagement_only && !membership_changed,
        )
      end
    end

    private

    def consume_engagement_marker(article_id)
      key = self.class.engagement_marker_key(article_id)
      value = Rails.cache.read(key)
      Rails.cache.delete(key) if value
      value
    end

    def engagement_only_run?(scheduled_interval, options, pending)
      return false if pending[:structural]

      explicit_engagement = options.is_a?(Hash) &&
        (options["engagement"] == true || options[:engagement] == true)
      scheduled_interval.present? || explicit_engagement
    end

    def apply_post_engagement_cooldown!(article_id, scheduled_interval:, org_ids:, tag_names:)
      interval_seconds = scheduled_interval.to_i
      if interval_seconds <= 0
        status = LiquidEmbedReference.dependency_status_for_article(
          article_id,
          organization_ids: org_ids,
          tag_names: tag_names,
          published_only: true,
        )
        return if status[:billboard]

        interval_seconds = status[:refresh_interval].to_i
      end
      return if interval_seconds < LiquidEmbedReference::COOLDOWN_GATE_THRESHOLD.to_i

      Rails.cache.write(
        self.class.engagement_cooldown_key(article_id),
        true,
        expires_in: interval_seconds.seconds,
      )
    end

    def consume_pending_context(article_id, options)
      key = self.class.pending_context_key(article_id)
      cached = Rails.cache.read(key)
      Rails.cache.delete(key) if cached

      opt_hash = options.is_a?(Hash) ? options : {}
      cached_hash = cached.is_a?(Hash) ? cached : {}

      org_ids = extract_array_ints(opt_hash, cached_hash, :org_ids)
      tags = extract_merged_tags(opt_hash, cached_hash)
      membership_changed = extract_flag(opt_hash, cached_hash, :membership_changed)
      structural = extract_flag(opt_hash, cached_hash, :structural) ||
        opt_hash.key?("org_ids") || opt_hash.key?(:org_ids)

      {
        org_ids: org_ids,
        tags: tags,
        membership_changed: membership_changed,
        structural: structural
      }
    end

    def extract_array_ints(opt_hash, cached_hash, key)
      str_key = key.to_s
      (Array(opt_hash[str_key] || opt_hash[key]) + Array(cached_hash[str_key] || cached_hash[key]))
        .compact.map(&:to_i).uniq
    end

    def extract_merged_tags(opt_hash, cached_hash)
      (Array(opt_hash["tags"] || opt_hash[:tags]) + Array(cached_hash["tags"] || cached_hash[:tags]))
        .flat_map { |entry| LiquidEmbedReference.parse_tag_list(entry) }.uniq
    end

    def extract_flag(opt_hash, cached_hash, key)
      str_key = key.to_s
      (opt_hash[str_key] == true) || (opt_hash[key] == true) ||
        (cached_hash[str_key] == true) || (cached_hash[key] == true)
    end

    def fetch_matching_reference_rows(article_id, org_ids:, tag_names:)
      scope = LiquidEmbedReference.where(referenced_type: "Article", referenced_id: article_id)

      if org_ids.any?
        scope = scope.or(
          LiquidEmbedReference.where(
            referenced_type: "Organization",
            referenced_id: org_ids,
            tag_name: LiquidEmbedReference::FEED_TAG_NAMES,
          ),
        )
      end

      if tag_names.any?
        tracked_tag_names = LiquidEmbedReference.cached_feed_targets[:tags].keys
        matching_tag_names = tag_names & tracked_tag_names
        if matching_tag_names.any?
          tag_ids = Tag.where(name: matching_tag_names).ids
          if tag_ids.any?
            scope = scope.or(
              LiquidEmbedReference.where(
                referenced_type: "Tag",
                referenced_id: tag_ids,
                tag_name: "feed",
              ),
            )
          end
        end
      end

      scope.pluck(:record_type, :record_id, :tag_name, :options, :referenced_type)
    end

    def group_reference_rows(ref_rows, all_tag_names:)
      grouped = Hash.new { |h, k| h[k] = Hash.new { |inner, id| inner[id] = [] } }

      ref_rows.each do |record_type, record_id, tag_name, tag_options, referenced_type|
        next if record_type.blank? || record_id.blank?
        next if skip_mismatched_org_tag_feed?(tag_name, tag_options, referenced_type, all_tag_names)

        grouped[record_type][record_id] << {
          tag_name: tag_name,
          options: tag_options,
          referenced_type: referenced_type
        }
      end

      grouped.delete_if { |_type, by_id| by_id.empty? }
    end

    def skip_mismatched_org_tag_feed?(tag_name, tag_options, referenced_type, all_tag_names)
      return false unless tag_name == "feed" && referenced_type == "Organization"

      _org_slug, feed_tags = LiquidEmbedExtractor.parse_feed_sources(tag_options)
      return false if feed_tags.empty?

      (feed_tags.map(&:downcase) & all_tag_names).empty?
    end

    def process_records_for_type(record_type, entries_by_id, article_id:, membership_changed:, engagement_only:)
      ids = entries_by_id.keys
      return if ids.empty?

      ctx = { article_id: article_id, membership_changed: membership_changed, engagement_only: engagement_only }
      case record_type
      when "Billboard" then process_billboards(ids, entries_by_id, ctx)
      when "Page" then process_pages(ids, entries_by_id, ctx)
      when "Article" then process_articles(ids, entries_by_id, ctx)
      when "Comment" then process_comments(ids, entries_by_id, ctx)
      else process_generic_records(record_type, ids, ctx)
      end
    end

    def process_billboards(ids, entries_by_id, ctx)
      Billboard.approved_and_published.where(render_mode: :forem_markdown, id: ids).includes(:creator).find_each do |bb|
        next if skip_unchanged_recent_feed?(bb, entries_by_id[bb.id], ctx[:article_id], ctx[:membership_changed])

        safely_refresh(bb) { bb.refresh_embedded_markdown! }
      end
    end

    def process_pages(ids, entries_by_id, ctx)
      Page.where(id: ids).includes(:organization, :page_template).find_each do |page|
        next if skip_unchanged_recent_feed?(page, entries_by_id[page.id], ctx[:article_id], ctx[:membership_changed])

        safely_refresh(page) { refresh_page(page) }
      end
    end

    def process_articles(ids, entries_by_id, ctx)
      scope = Article.where(id: ids)
      scope = scope.where(published: true) if ctx[:engagement_only]
      scope.includes(:user, :organization).find_each do |art|
        next if skip_unchanged_recent_feed?(art, entries_by_id[art.id], ctx[:article_id], ctx[:membership_changed])
        next if skip_record_for_engagement_backoff?("Article", art, ctx[:engagement_only])

        safely_refresh(art) { refresh_article(art) }
      end
    end

    def process_comments(ids, entries_by_id, ctx)
      Comment.where(id: ids).includes(:user, :commentable).find_each do |cmt|
        next if skip_unchanged_recent_feed?(cmt, entries_by_id[cmt.id], ctx[:article_id], ctx[:membership_changed])
        next if skip_record_for_engagement_backoff?("Comment", cmt, ctx[:engagement_only])

        safely_refresh(cmt) { refresh_comment(cmt) }
      end
    end

    def process_generic_records(record_type, ids, ctx)
      klass = record_type.safe_constantize
      return unless klass

      klass.where(id: ids).find_each do |record|
        next if skip_record_for_engagement_backoff?(record_type, record, ctx[:engagement_only])

        safely_refresh(record) { refresh_generic_record(record) }
      end
    end

    def skip_record_for_engagement_backoff?(record_type, record, engagement_only)
      key = self.class.record_cooldown_key(record_type, record.id)
      unless engagement_only
        Rails.cache.delete(key)
        return false
      end

      backoff = LiquidEmbedReference.record_engagement_backoff(record)
      return false if backoff < LiquidEmbedReference::COOLDOWN_GATE_THRESHOLD

      Rails.cache.write(key, true, unless_exist: true, expires_in: backoff) == false
    end

    def skip_unchanged_recent_feed?(record, entries, article_id, membership_changed)
      return false if membership_changed || entries.blank?

      only_recent_feeds = entries.all? do |entry|
        entry[:referenced_type] != "Article" &&
          LiquidEmbedReference::FEED_TAG_NAMES.include?(entry[:tag_name]) &&
          !entry[:options].to_s.match?(DYNAMIC_FEED_OPTION_REGEX)
      end
      return false unless only_recent_feeds

      html_blobs = [record.processed_html]
      html_blobs << record.minimized_processed_html if record.respond_to?(:minimized_processed_html)
      combined_html = html_blobs.compact_blank.join("\n")
      return false if combined_html.blank?
      return false unless combined_html.include?("ltag-feed") || combined_html.include?("ltag-org-posts")

      !html_mentions_article?(combined_html, article_id)
    end

    def html_mentions_article?(html, article_id)
      html.include?(%(data-feed-content-id="#{article_id}")) ||
        html.include?("article-link-#{article_id}")
    end

    def refresh_article(article)
      original_html = article.processed_html
      article.evaluate_and_update_column_from_markdown
      article.async_bust unless LiquidEmbedReference.semantically_equal_html?(article.processed_html, original_html)
    end

    def refresh_page(page)
      original_html = page.processed_html
      if page.uses_page_template?
        page.__send__(:render_from_page_template)
      else
        page.__send__(:evaluate_markdown)
      end
      return if LiquidEmbedReference.semantically_equal_html?(page.processed_html, original_html)

      page.update_column(:processed_html, page.processed_html)
      page.__send__(:bust_cache)
    end

    def refresh_comment(comment)
      original_html = comment.processed_html
      comment.__send__(:evaluate_markdown)
      return if LiquidEmbedReference.semantically_equal_html?(comment.processed_html, original_html)

      comment.update_column(:processed_html, comment.processed_html)
      comment.__send__(:bust_cache)
    end

    def refresh_generic_record(record)
      return unless record.respond_to?(:evaluate_markdown, true) && record.respond_to?(:processed_html=)

      original_html = record.processed_html
      record.__send__(:evaluate_markdown)
      return if LiquidEmbedReference.semantically_equal_html?(record.processed_html, original_html)

      record.update_column(:processed_html, record.processed_html)
      if record.respond_to?(:async_bust)
        record.async_bust
      elsif record.respond_to?(:bust_cache, true)
        record.__send__(:bust_cache)
      end
    end

    def safely_refresh(record)
      yield
    rescue StandardError => e
      Rails.logger.error(
        "[Articles::UpdateDependentEmbedsWorker] Failed refreshing #{record.class.name}##{record.try(:id)}: " \
        "#{e.class} - #{e.message}",
      )
    end
  end
end
