module Badges
  class AwardEightWeekStreak
    def self.call
      ::Badges::AwardStreak.call(weeks: 8)
    end
  end
end
