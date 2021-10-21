module SettingsHelper
  HOMEPAGE_FEED_OPTIONS = [
    ["Feed - posts picked and ordered magically.", :default],
    ["Latest - the most recent posts will be displayed first.", :latest],
    ["Top Week - the most popular posts from the last week.", :top_week],
    ["Top Month - the most popular posts from the last month.", :top_month],
    ["Top Year - the most popular posts from the last year.", :top_year],
    ["Top Infinity - the most popular posts from all time.", :top_infinity],
  ].freeze

  def user_experience_labels
    %w[Novice Beginner Mid-level Advanced Expert]
  end

  def user_experience_levels
    %w[1 3 5 8 10]
  end
end
