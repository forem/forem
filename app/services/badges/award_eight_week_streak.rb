module Badges
  class AwardEightWeekStreak
    def self.call
      ::Badges::AwardStreak.call(8)
    end
  end
end
