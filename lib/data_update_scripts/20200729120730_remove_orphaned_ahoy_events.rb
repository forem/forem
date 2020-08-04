module DataUpdateScripts
  class RemoveOrphanedAhoyEvents
    def run
      Ahoy::Event.find_each do |event|
        next if event.visit.blank?

        event.destroy
      end
    end
  end
end
