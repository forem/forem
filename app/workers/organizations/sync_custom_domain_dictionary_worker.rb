module Organizations
  class SyncCustomDomainDictionaryWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 5, lock: :until_executing, on_conflict: :replace

    def perform(organization_id = nil, previous_slug = nil, previous_custom_domain = nil)
      return unless FastlyConfig::CustomDomainDictionary.configured?

      if organization_id.nil?
        FastlyConfig::CustomDomainDictionary.sync_all!
      else
        FastlyConfig::CustomDomainDictionary.sync_organization!(
          organization_id,
          previous_slug: previous_slug,
          previous_custom_domain: previous_custom_domain,
        )
      end
    end
  end
end
