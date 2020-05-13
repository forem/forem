module DataUpdateScripts
  class UpdateTagHotnessScores
    def run
      # Saving a tag will trigger calculate_hotness_score
      Tag.find_each(&:save)
    end
  end
end
