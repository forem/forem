module DataUpdateScripts
  module RemoveCollectiveNounFromSettings
    class General
      def run
        Settings::General.where(var: %w[collective_noun collective_noun_disabled]).destroy_all
      end
    end
  end
end
