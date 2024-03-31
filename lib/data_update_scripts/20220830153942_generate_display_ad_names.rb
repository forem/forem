module DataUpdateScripts
  class GenerateDisplayAdNames
    def run
      Billboard.where(name: nil).find_each do |display_ad|
        display_ad.update(name: "Billboard #{display_ad.id}")
      end
    end
  end
end
