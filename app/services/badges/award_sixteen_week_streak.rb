module Badges
  class AwardSixteenWeekStreak
    def self.call
      ::Badges::AwardStreak.call(weeks: 16)
    end
  end
end
