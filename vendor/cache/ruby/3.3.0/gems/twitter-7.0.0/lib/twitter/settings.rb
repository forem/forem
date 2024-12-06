require 'twitter/base'

module Twitter
  class Settings < Twitter::Base
    # @return [Hash]
    attr_reader :sleep_time, :time_zone
    # @return [String]
    attr_reader :language, :screen_name
    object_attr_reader :Place, :trend_location
    predicate_attr_reader :allow_contributor_request,
                          :allow_dm_groups_from,
                          :allow_dms_from,
                          :always_use_https,
                          :discoverable_by_email,
                          :discoverable_by_mobile_phone,
                          :display_sensitive_media,
                          :geo_enabled,
                          :protected,
                          :show_all_inline_media,
                          :use_cookie_personalization
  end
end
