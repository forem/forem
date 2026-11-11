module FastlyConfig
  class CustomDomainDictionary
    include HTTParty
    base_uri "https://api.fastly.com"
    default_timeout 10

    DICTIONARY_NAME = "custom_domain_orgs".freeze
    APP_DOMAIN_KEY = "app_domain".freeze
    BATCH_LIMIT = 1_000
    DICTIONARY_ID_CACHE_TTL = 1.hour

    class Error < StandardError; end

    class << self
      def configured?
        ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
      end

      def sync_all!
        return false unless configured?

        dict_id = resolve_dictionary_id
        return false if dict_id.blank?

        existing = fetch_items(dict_id)
        desired = desired_items
        operations = build_diff_operations(existing, desired)

        operations.each_slice(BATCH_LIMIT) do |batch|
          patch_items(dict_id, batch)
        end

        true
      rescue StandardError => e
        Rails.logger.error("[FastlyConfig::CustomDomainDictionary] Failed sync_all!: #{e.class}: #{e.message}")
        ForemStatsClient.increment("fastly.custom_domain_dictionary.error", tags: ["operation:sync_all"])
        false
      end

      def sync_organization!(organization_id, previous_slug: nil, previous_custom_domain: nil)
        return false unless configured?

        dict_id = resolve_dictionary_id
        return false if dict_id.blank?

        organization = Organization.find_by(id: organization_id)
        stale_keys, upserts = build_organization_sync_plan(
          organization,
          previous_slug: previous_slug,
          previous_custom_domain: previous_custom_domain,
        )

        stale_keys.each { |item_key| delete_item(dict_id, item_key) }
        patch_items(dict_id, upserts) if upserts.any?
        true
      rescue StandardError => e
        msg = "[FastlyConfig::CustomDomainDictionary] Failed sync_organization!(#{organization_id}): " \
              "#{e.class}: #{e.message}"
        Rails.logger.error(msg)
        ForemStatsClient.increment("fastly.custom_domain_dictionary.error", tags: ["operation:sync_organization"])
        false
      end

      def desired_items
        items = {}
        app_domain = normalized_app_domain
        items[APP_DOMAIN_KEY] = app_domain if app_domain.present?

        Organization.where.not(custom_domain: [nil, ""]).find_each do |org|
          next unless active_custom_domain_org?(org)

          slug = normalize_token(org.slug)
          domain = normalize_token(org.custom_domain)
          next if slug.blank? || domain.blank?

          items["slug:#{slug}"] = domain
          items["domain:#{domain}"] = slug
        end

        items
      end

      private

      def build_organization_sync_plan(organization, previous_slug:, previous_custom_domain:)
        upserts = base_app_domain_upserts
        prev_slug = normalize_token(previous_slug)
        prev_domain = normalize_token(previous_custom_domain)

        if organization && active_custom_domain_org?(organization)
          active_organization_sync_plan(organization, prev_slug, prev_domain, upserts)
        else
          inactive_organization_sync_plan(organization, prev_slug, prev_domain, upserts)
        end
      end

      def base_app_domain_upserts
        app_domain = normalized_app_domain
        return [] if app_domain.blank?

        [{ op: "upsert", item_key: APP_DOMAIN_KEY, item_value: app_domain }]
      end

      def active_organization_sync_plan(organization, prev_slug, prev_domain, upserts)
        current_slug = normalize_token(organization.slug)
        current_domain = normalize_token(organization.custom_domain)
        stale_keys = []
        stale_keys << "slug:#{prev_slug}" if prev_slug && prev_slug != current_slug
        stale_keys << "domain:#{prev_domain}" if prev_domain && prev_domain != current_domain

        upserts << { op: "upsert", item_key: "slug:#{current_slug}", item_value: current_domain }
        upserts << { op: "upsert", item_key: "domain:#{current_domain}", item_value: current_slug }
        [stale_keys.uniq, upserts]
      end

      def inactive_organization_sync_plan(organization, prev_slug, prev_domain, upserts)
        slugs = [prev_slug, normalize_token(organization&.slug)].compact
        domains = [prev_domain, normalize_token(organization&.custom_domain)].compact
        stale_keys = slugs.map { |s| "slug:#{s}" } + domains.map { |d| "domain:#{d}" }
        [stale_keys.uniq, upserts]
      end

      def normalize_token(value)
        value.to_s.strip.downcase.presence
      end

      def active_custom_domain_org?(organization)
        organization.custom_domain.present? &&
          FeatureFlag.uncached.enabled?(:org_custom_domain, FeatureFlag::Actor.new(organization))
      end

      def normalized_app_domain
        normalize_token(Settings::General.app_domain)
      end

      def service_id
        ApplicationConfig["FASTLY_SERVICE_ID"]
      end

      def dictionary_id_cache_key
        "fastly_dictionary_id:#{service_id}:#{DICTIONARY_NAME}"
      end

      def resolve_dictionary_id(force_refresh: false)
        MemoryFirstCache.delete(dictionary_id_cache_key) if force_refresh

        cached = MemoryFirstCache.fetch(dictionary_id_cache_key, redis_expires_in: DICTIONARY_ID_CACHE_TTL) do
          fetch_dictionary_id_from_fastly || "not_found"
        end

        if cached == "not_found"
          MemoryFirstCache.delete(dictionary_id_cache_key)
          return
        end

        cached
      end

      def fetch_dictionary_id_from_fastly
        version_resp = get("/service/#{service_id}/version/active", headers: request_headers)
        return if version_resp.code == 404

        ensure_success!(version_resp, "fetch active Fastly version")
        version_number = parse_json(version_resp)["number"]
        return if version_number.blank?

        dict_resp = get("/service/#{service_id}/version/#{version_number}/dictionary/#{DICTIONARY_NAME}",
                        headers: request_headers)
        return if dict_resp.code == 404

        ensure_success!(dict_resp, "fetch #{DICTIONARY_NAME} dictionary")
        parse_json(dict_resp)["id"]
      end

      def fetch_items(dict_id)
        response = get("/service/#{service_id}/dictionary/#{dict_id}/items", headers: request_headers)
        if response.code == 404
          MemoryFirstCache.delete(dictionary_id_cache_key)
          raise Error, "Dictionary #{dict_id} not found"
        end
        ensure_success!(response, "list dictionary items")

        Array(parse_json(response)).each_with_object({}) do |entry, acc|
          key = entry["item_key"]
          acc[key] = entry["item_value"].to_s if key.present?
        end
      end

      def patch_items(dict_id, operations)
        return if operations.empty?

        response = patch(
          "/service/#{service_id}/dictionary/#{dict_id}/items",
          headers: request_headers,
          body: { items: operations }.to_json,
        )
        MemoryFirstCache.delete(dictionary_id_cache_key) if response.code == 404
        ensure_success!(response, "batch update dictionary items")
      end

      def delete_item(dict_id, item_key)
        encoded_key = URI.encode_www_form_component(item_key)
        response = delete(
          "/service/#{service_id}/dictionary/#{dict_id}/item/#{encoded_key}",
          headers: request_headers,
        )
        return if response.code == 404

        ensure_success!(response, "delete dictionary item #{item_key}")
      end

      def build_diff_operations(existing, desired)
        operations = []

        existing.each_key do |key|
          operations << { op: "delete", item_key: key } unless desired.key?(key)
        end

        desired.each do |key, value|
          operations << { op: "upsert", item_key: key, item_value: value } if existing[key] != value
        end

        operations
      end

      def parse_json(response)
        parsed = response.parsed_response
        parsed.is_a?(String) ? JSON.parse(parsed) : parsed
      end

      def ensure_success!(response, context)
        return if response.success?

        raise Error, "Fastly API failed to #{context} (HTTP #{response.code}): #{response.body}"
      end

      def request_headers
        {
          "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"],
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        }
      end
    end
  end
end
