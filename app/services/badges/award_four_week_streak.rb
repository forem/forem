module Badges
  class AwardFourWeekStreak
    def self.call
      ::Badges::AwardStreak.call(weeks: 4)
    end
  end
end
