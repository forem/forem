Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :cookie
  strategy :active_record
  strategy :default

  # Other strategies:
  #
  # strategy :query_string
  # strategy :redis
  # strategy :session
  #
  # strategy :my_strategy do |feature|
  #   # ... your custom code here; return true/false/nil.
  # end

  # Declare your features, e.g:
  #
  feature :display_sponsors,
    default: false,
    description: "Home page sponsor display"
  feature :live_starting_soon,
    default: false,
    description: "/live event is starting soon."
  feature :live_is_live,
    default: false,
    description: "/live page showing live event"
  feature :she_coded,
    default: false,
    description: "Toggle #shecoded sidebar"
  feature :sendbird,
    default: true,
    description: "Toggle between Sendbird and our custom chat"
  feature :upcoming_events,
    default: true,
    description: "Toggle upcoming events in sidebar"
end
