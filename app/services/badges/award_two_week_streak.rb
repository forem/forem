module Badges
  class AwardTwoWeekStreak
    def self.call
      ::Badges::AwardStreak.call(weeks: 2)
    end
  end
end
