module Badges
  class AwardFourWeekStreak
    def self.call
      ::Badges::AwardStreak.call(4)
    end
  end
end
