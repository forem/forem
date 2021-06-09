module Users
  class Setting < ApplicationRecord
    self.table_name_prefix = "users_"

    belongs_to :user

    # TODO: @msarit Double-check how these suffixes have impacted the rest of the codebase
    enum editor_version: { v2: 0, v1: 1 }, _suffix: :editor
    enum config_font: { default: 0, comic_sans: 1, monospace: 2, open_dyslexic: 3, sans_serif: 4, serif: 5 },
         _suffix: :font
    enum inbox_type: { private: 0, open: 1 }, _suffix: :inbox
    enum config_navbar: { default: 0, static: 1 }, _suffix: :navbar
    enum config_theme: { default: 0, minimal_light_theme: 1, night_theme: 2, pink_theme: 3,
                         ten_x_hacker_theme: 4 }

    validates :user_id, presence: true
    validates :experience_level, numericality: { less_than_or_equal_to: 10 }, allow_blank: true
    validates :feed_referential_link, inclusion: { in: [true, false] }
    validates :feed_url, length: { maximum: 500 }, allow_nil: true
    validates :inbox_guidelines, length: { maximum: 250 }, allow_nil: true
  end

  # TODO: @msarit Re-add feed_url validation after updates are pointed directly to users_settings table
end
