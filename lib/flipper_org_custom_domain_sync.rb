module FlipperOrgCustomDomainSync
  FEATURE_KEY = "org_custom_domain".freeze
  ACTOR_PREFIX_REGEX = /\AOrganization;/

  def enable(feature, gate, thing)
    result = super
    notify_custom_domain_flag_change(feature, gate, thing)
    result
  end

  def disable(feature, gate, thing)
    result = super
    notify_custom_domain_flag_change(feature, gate, thing)
    result
  end

  def remove(feature)
    result = super
    enqueue_full_custom_domain_sync if custom_domain_feature?(feature)
    result
  end

  def clear(feature)
    result = super
    enqueue_full_custom_domain_sync if custom_domain_feature?(feature)
    result
  end

  private

  def custom_domain_feature?(feature)
    feature.respond_to?(:key) && feature.key.to_s == FEATURE_KEY
  end

  def notify_custom_domain_flag_change(feature, gate, thing)
    return unless custom_domain_feature?(feature)

    if gate.respond_to?(:name) && gate.name == :actor && thing.respond_to?(:value)
      org_id = thing.value.to_s.sub(ACTOR_PREFIX_REGEX, "").to_i
      if org_id.positive?
        invalidate_organization_custom_domain_caches(org_id)
        if FastlyConfig::CustomDomainDictionary.configured?
          Organizations::SyncCustomDomainDictionaryWorker.perform_async(org_id)
        end
        return
      end
    end

    enqueue_full_custom_domain_sync
  rescue StandardError => e
    Rails.logger.error("[FlipperOrgCustomDomainSync] Failed to enqueue custom domain sync: #{e.class}: #{e.message}")
  end

  def enqueue_full_custom_domain_sync
    return unless FastlyConfig::CustomDomainDictionary.configured?

    Organizations::SyncCustomDomainDictionaryWorker.perform_async
  rescue StandardError => e
    Rails.logger.error(
      "[FlipperOrgCustomDomainSync] Failed to enqueue full custom domain sync: #{e.class}: #{e.message}",
    )
  end

  def invalidate_organization_custom_domain_caches(org_id)
    MemoryFirstCache.delete("org_custom_domain:#{org_id}")
    custom_domain = Organization.where(id: org_id).pick(:custom_domain)
    MemoryFirstCache.delete("org_custom_domain_id:#{custom_domain.downcase}") if custom_domain.present?
  end
end
