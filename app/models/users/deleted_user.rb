module Users
  # This module represents a deleted user.  In particular as it
  # relates to rendering rich content in tags.  This "Null" object
  # provides the interface for rendering.
  #
  # @see UserTag for implementation details.
  module DeletedUser
    BG_COLOR = "#19063A".freeze
    FG_COLOR = "#DCE9F3".freeze
    ENRICHED_COLORS = { bg: BG_COLOR, text: FG_COLOR }.freeze
    USER_COLORS = [BG_COLOR, FG_COLOR].freeze

    # [@jeremyf] Yeah, this looks funny; it's analogue to `def.self
    # method_name; nil; end`.
    def self.deleted? = true
    def self.id = nil
    def self.darker_color = Color::CompareHex.new(USER_COLORS).brightness
    def self.username = "[deleted user]"
    def self.name = I18n.t("models.users.deleted_user.name")
    def self.summary = nil
    def self.twitter_username = nil
    def self.github_username = nil
    def self.profile_image_url = nil
    def self.path = nil
    def self.tag_line = nil

    # @return [String]
    #
    # @see ApplicationRecord#class_name
    def self.class_name
      User.name
    end

    def self.decorate
      self
    end

    def self.enriched_colors
      ENRICHED_COLORS
    end

    def self.profile_image_url_for(length:)
      Images::Profile.call(profile_image_url, length: length)
    end
  end
end
