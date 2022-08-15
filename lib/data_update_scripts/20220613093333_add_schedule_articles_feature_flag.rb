module DataUpdateScripts
  class AddScheduleArticlesFeatureFlag
    def run
      FeatureFlag.add(:schedule_articles)
    end
  end
end
