module Trackable
  # Namespaces every event we emit to Customer.io with the deploy's APP_NAME
  # (e.g. "dev_prod") so events from different environments or Forem instances
  # writing into the same workspace stay distinct: "dev_prod_user_updated".
  # When APP_NAME is unset the prefix falls back to "forem".
  #
  # Shared by both Customer.io paths -- CDP events (Trackers::CustomerioCdp)
  # and campaign-triggering Track API events (DeliveryMethods::CustomerIoEvent)
  # -- because a Track event name is also a campaign's trigger. Two copies of
  # this rule that drifted apart would stop a campaign firing rather than just
  # mislabel a metric, so there is only one.
  module EventName
    DEFAULT_APP_NAME = "forem".freeze

    def self.prefixed(event_name)
      prefix = ApplicationConfig["APP_NAME"].presence || DEFAULT_APP_NAME
      "#{prefix}_#{event_name}"
    end
  end
end
