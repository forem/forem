module Ai
  # Shared helper for resolving community-level AI context (`internal_content_description_spec`,
  # `expanded_content_advisement_spec`, `community_description`, and `community_name`) with
  # consistent fallback to the default Subforem (`Subforem.cached_default_id`) and global
  # settings, especially in background workers where `RequestStore` or record `subforem_id`
  # may be nil or point to a retired subforem.
  module CommunityContext
    extend ActiveSupport::Concern

    private

    def effective_subforem_id(record_subforem_id = nil)
      default_subforem_id = RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      return default_subforem_id if Subforem.disabled_by_env? && default_subforem_id.present?

      record_subforem_id || RequestStore.store[:subforem_id] || default_subforem_id
    end

    def resolve_community_description(record_subforem_id = nil)
      default_subforem_id = RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      subforem_id = effective_subforem_id(record_subforem_id)

      description = if subforem_id
                      Settings::RateLimit.internal_content_description_spec(subforem_id: subforem_id).presence ||
                        Settings::Community.community_description(subforem_id: subforem_id).presence
                    end
      if description.blank? && default_subforem_id && default_subforem_id != subforem_id
        description =
          Settings::RateLimit.internal_content_description_spec(subforem_id: default_subforem_id).presence ||
          Settings::Community.community_description(subforem_id: default_subforem_id).presence
      end
      description ||
        Settings::RateLimit.internal_content_description_spec.presence ||
        Settings::Community.community_description
    end

    def resolve_content_advisement_spec(record_subforem_id = nil)
      default_subforem_id = RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      subforem_id = effective_subforem_id(record_subforem_id)

      advisement = if subforem_id
                     Settings::RateLimit.expanded_content_advisement_spec(subforem_id: subforem_id).presence
                   end
      if advisement.blank? && default_subforem_id && default_subforem_id != subforem_id
        advisement = Settings::RateLimit.expanded_content_advisement_spec(subforem_id: default_subforem_id).presence
      end
      advisement || Settings::RateLimit.expanded_content_advisement_spec.presence
    end

    def resolve_community_name(record_subforem_id = nil)
      default_subforem_id = RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      subforem_id = effective_subforem_id(record_subforem_id)

      name = Settings::Community.community_name(subforem_id: subforem_id).presence if subforem_id
      if name.blank? && default_subforem_id && default_subforem_id != subforem_id
        name = Settings::Community.community_name(subforem_id: default_subforem_id).presence
      end
      name || Settings::Community.community_name
    end

    def multiple_subforems_enabled?
      Subforem.multiple_subforems_enabled?
    end
  end
end
