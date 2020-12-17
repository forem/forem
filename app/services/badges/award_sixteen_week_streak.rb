module Badges
  class AwardSixteenWeekStreak
    def self.call
      ::Badges::AwardStreak.call(16)
    end
  end
end
