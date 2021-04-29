module DataUpdateScripts
  class RemoveCollectiveNounFromConfig
    def run
      # Settings::General.where(var: %w[collective_noun collective_noun_disabled]).destroy_all

      # These columns have been removed via the model, rendering this script useless
    end
  end
end
