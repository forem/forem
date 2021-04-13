module Constants
  module Settings
    TAB_LIST = %w[
      Profile
      Customization
      Notifications
      Account
      Billing
      Organization
      Extensions
    ].freeze

    VALID_URL = %r{\A(http|https)://([/|.\w\s-])*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}.freeze
    URL_MESSAGE = "must be a valid URL".freeze
  end
end
