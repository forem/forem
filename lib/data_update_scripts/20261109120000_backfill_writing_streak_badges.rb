module DataUpdateScripts
  class BackfillWritingStreakBadges
    WEEKS = [4, 8, 16].freeze

    def run
      WEEKS.each do |weeks|
        Badges::AwardStreak.call(weeks: weeks, historical: true)
      end
    end
  end
end
