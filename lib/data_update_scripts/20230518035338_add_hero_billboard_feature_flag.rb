module DataUpdateScripts
  class AddHeroBillboardFeatureFlag
    def run
      FeatureFlag.add(:hero_billboard)
    end
  end
end
