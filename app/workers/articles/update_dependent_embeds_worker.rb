module Articles
  class UpdateDependentEmbedsWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority,
                    lock: :until_executing,
                    on_conflict: :replace,
                    lock_args_method: :lock_args

    BILLBOARD_ENGAGEMENT_DEBOUNCE = 15.seconds
    DEFAULT_ENGAGEMENT_DEBOUNCE = 60.seconds
    PENDING_CONTEXT_TTL = 10.minutes
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
      )
      return false unless status[:any]

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

      status = LiquidEmbedReference.dependency_status_for_article(article_id)
      return false unless status[:any]

      delay = status[:billboard] ? BILLBOARD_ENGAGEMENT_DEBOUNCE : DEFAULT_ENGAGEMENT_DEBOUNCE
      debounce_key = engagement_debounce_key(article_id, billboard: status[:billboard])

      # Fixed trailing-edge debounce window: the first engagement event schedules a run
      # `delay` seconds out, while subsequent events in that window coalesce in cache
      # without pushing the scheduled timestamp forward (avoiding starvation).
      acquired = Rails.cache.write(debounce_key, true, unless_exist: true, expires_in: delay)
      return false if acquired == false

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
                     membership_changed
                 }
               else
                 {
                   org_ids: org_ids,
                   tags: tags,
                   membership_changed: membership_changed == true
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
      pending = consume_pending_context(article_id, options)

      # Only narrow metadata columns are needed; skip hydrating the wide TOASTed article row.
      found_id, organization_id, raw_tag_list = Article
        .where(id: article_id)
        .pick(:id, :organization_id, :cached_tag_list)

      org_ids = ([organization_id] + pending[:org_ids]).compact.map(&:to_i).uniq
      current_tags = LiquidEmbedReference.parse_tag_list(raw_tag_list)
      all_tag_names = (current_tags + pending[:tags]).uniq
      membership_changed = pending[:membership_changed] || found_id.nil?

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
        )
      end
    end

    private

    def consume_pending_context(article_id, options)
      key = self.class.pending_context_key(article_id)
      cached = Rails.cache.read(key)
      Rails.cache.delete(key) if cached

      opt_hash = options.is_a?(Hash) ? options : {}
      cached_hash = cached.is_a?(Hash) ? cached : {}

      org_ids = (
        Array(opt_hash["org_ids"] || opt_hash[:org_ids]) +
        Array(cached_hash["org_ids"] || cached_hash[:org_ids])
      ).compact.map(&:to_i).uniq

      tags = (
        Array(opt_hash["tags"] || opt_hash[:tags]) +
        Array(cached_hash["tags"] || cached_hash[:tags])
      ).flat_map { |entry| LiquidEmbedReference.parse_tag_list(entry) }.uniq

      membership_changed = (opt_hash["membership_changed"] == true) ||
        (opt_hash[:membership_changed] == true) ||
        (cached_hash["membership_changed"] == true) ||
        (cached_hash[:membership_changed] == true)

      { org_ids: org_ids, tags: tags, membership_changed: membership_changed }
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

    def process_records_for_type(record_type, entries_by_id, article_id:, membership_changed:)
      ids = entries_by_id.keys
      return if ids.empty?

      case record_type
      when "Billboard"
        active_billboards = Billboard.approved_and_published.where(render_mode: :forem_markdown, id: ids)
        active_billboards.includes(:creator).find_each do |billboard|
          next if skip_unchanged_recent_feed?(billboard, entries_by_id[billboard.id], article_id, membership_changed)

          safely_refresh(billboard) { billboard.refresh_embedded_markdown! }
        end
      when "Page"
        Page.where(id: ids).includes(:organization, :page_template).find_each do |page|
          next if skip_unchanged_recent_feed?(page, entries_by_id[page.id], article_id, membership_changed)

          safely_refresh(page) { refresh_page(page) }
        end
      when "Article"
        Article.where(id: ids).includes(:user, :organization).find_each do |article|
          next if skip_unchanged_recent_feed?(article, entries_by_id[article.id], article_id, membership_changed)

          safely_refresh(article) { refresh_article(article) }
        end
      when "Comment"
        Comment.where(id: ids).includes(:user, :commentable).find_each do |comment|
          next if skip_unchanged_recent_feed?(comment, entries_by_id[comment.id], article_id, membership_changed)

          safely_refresh(comment) { refresh_comment(comment) }
        end
      else
        klass = record_type.safe_constantize
        return unless klass

        klass.where(id: ids).find_each do |record|
          safely_refresh(record) { refresh_generic_record(record) }
        end
      end
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
