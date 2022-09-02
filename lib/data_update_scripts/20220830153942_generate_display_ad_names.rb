module DataUpdateScripts
  class GenerateDisplayAdNames
    def run
      DisplayAd.where(name: nil).find_each do |display_ad|
        display_ad.update(name: "Display Ad #{display_ad.id}")
      end
    end
  end
end
